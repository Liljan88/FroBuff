local FroBuff = LibStub("AceAddon-3.0"):NewAddon("FroBuff", "AceConsole-3.0", "AceEvent-3.0")

local buffButton -- Vår klickbara frame

function FroBuff:OnInitialize()
    -- Initialize database and options from Options.lua
    if self.SetupOptions then
        self:SetupOptions()
    end
    
    self:CreateBuffButton()
end

function FroBuff:OnEnable()
    -- Register events to track buff changes
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateBuffStatus")
end

function FroBuff:CreateBuffButton()
    buffButton = CreateFrame("Button", "FroBuffButton", UIParent, "SecureActionButtonTemplate")
    buffButton:SetSize(36, 36)
    buffButton:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    
    buffButton:SetAttribute("type1", "macro")
    buffButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")

    buffButton.icon = buffButton:CreateTexture(nil, "BACKGROUND")
    buffButton.icon:SetAllPoints()
    buffButton.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    buffButton.border = buffButton:CreateTexture(nil, "BORDER")
    buffButton.border:SetSize(62, 62)
    buffButton.border:SetPoint("CENTER", 0, 0)
    buffButton.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    -- NYTT: Snygg text till vänster om ikonen (T.ex. "Arcane Intellect ->")
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

        -- Uppdatera texten istället för röd ruta
        buffButton.text:SetText(missingBuff .. " ->")
        
        buffButton:SetAttribute("macrotext1", "/cast " .. missingBuff)
        buffButton:SetAttribute("currentSpell", missingBuff)
    else
        buffButton.icon:SetDesaturated(true)
        buffButton.text:SetText("") -- Göm texten när allt är klart
        
        buffButton:SetAttribute("macrotext1", nil)
        buffButton:SetAttribute("currentSpell", nil)
    end
end
