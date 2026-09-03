local FroBuff = LibStub("AceAddon-3.0"):NewAddon("FroBuff", "AceConsole-3.0", "AceEvent-3.0")

local buffButton

function FroBuff:OnInitialize()
    if self.SetupOptions then
        self:SetupOptions()
    end
    self:CreateBuffButton()
end

function FroBuff:OnEnable()
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateBuffStatus")
end

function FroBuff:UNIT_AURA(event, unit)
    if unit == "player" then
        self:UpdateBuffStatus()
    end
end

function FroBuff:PLAYER_REGEN_ENABLED()
    self:UpdateBuffStatus()
end

function FroBuff:CreateBuffButton()
    buffButton = CreateFrame("Button", "FroBuffButton", UIParent, "SecureActionButtonTemplate")
    buffButton:SetSize(36, 36)
    
    -- Ladda sparad position eller sätt i mitten
    local pos = self.db.profile.framePosition
    if pos then
        buffButton:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        buffButton:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    end
    
    buffButton:SetAttribute("type1", "macro")
    buffButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")

    -- Dra-och-släpp-logik
    buffButton:SetMovable(true)
    buffButton:RegisterForDrag("LeftButton")
    buffButton:SetScript("OnDragStart", function(self)
        if not FroBuff.db.profile.locked then
            self:StartMoving()
        end
    end)
    buffButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Spara nya positionen i AceDB
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        FroBuff.db.profile.framePosition = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end)

    buffButton.icon = buffButton:CreateTexture(nil, "BACKGROUND")
    buffButton.icon:SetAllPoints()
    buffButton.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    buffButton.border = buffButton:CreateTexture(nil, "BORDER")
    buffButton.border:SetSize(62, 62)
    buffButton.border:SetPoint("CENTER", 0, 0)
    buffButton.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    buffButton.text = buffButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buffButton.text:SetPoint("RIGHT", buffButton, "LEFT", -10, 0)
    buffButton.text:SetText("")

    buffButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local spell = self:GetAttribute("currentSpell")
        if spell then
            GameTooltip:SetText("Missing Buff:\n|cFFFFFFFF" .. spell .. "|r")
        else
            GameTooltip:SetText("All buffs are active!")
        end
        GameTooltip:Show()
    end)
    
    buffButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

function FroBuff:UpdateBuffStatus()
    if InCombatLockdown() then return end
    
    local myBuffs = self:GetMyClassBuffs()
    local missingBuff = self:GetFirstMissingBuff(myBuffs, "player")
    
    if missingBuff then
        local spellName, _, spellIcon = GetSpellInfo(missingBuff)
        
        if spellIcon then
            buffButton.icon:SetTexture(spellIcon)
            buffButton.icon:SetDesaturated(false)
        end

        buffButton.text:SetText(missingBuff .. " ->")
        buffButton:SetAttribute("macrotext1", "/cast " .. missingBuff)
        buffButton:SetAttribute("currentSpell", missingBuff)
    else
        buffButton.icon:SetDesaturated(true)
        buffButton.text:SetText("") 
        buffButton:SetAttribute("macrotext1", nil)
        buffButton:SetAttribute("currentSpell", nil)
    end
end
