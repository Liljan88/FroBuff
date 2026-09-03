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
    -- Create the secure button frame
    buffButton = CreateFrame("Button", "FroBuffButton", UIParent, "SecureActionButtonTemplate")
    buffButton:SetSize(36, 36)
    buffButton:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    
    -- Använd macro istället för direkt spell-attribut för maximal kompatibilitet i Classic
    buffButton:SetAttribute("type1", "macro")
    buffButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")

    -- Spell icon background
    buffButton.icon = buffButton:CreateTexture(nil, "BACKGROUND")
    buffButton.icon:SetAllPoints()
    buffButton.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    -- Blizzard default button border
    buffButton.border = buffButton:CreateTexture(nil, "BORDER")
    buffButton.border:SetSize(62, 62)
    buffButton.border:SetPoint("CENTER", 0, 0)
    buffButton.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    -- The status indicator
    buffButton.indicator = buffButton:CreateTexture(nil, "OVERLAY")
    buffButton.indicator:SetSize(10, 10)
    buffButton.indicator:SetColorTexture(0.07, 0.07, 0.07, 1)
    buffButton.indicator:SetPoint("TOPRIGHT", buffButton, "TOPRIGHT", 2, 2)
    buffButton.indicator:Show()

    -- Tooltip handling
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

function FroBuff:UNIT_AURA(event, unit)
    if unit == "player" then
        self:UpdateBuffStatus()
    end
end

function FroBuff:PLAYER_REGEN_ENABLED()
    self:UpdateBuffStatus()
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

        buffButton.indicator:SetColorTexture(1, 0, 0, 1)
        
        -- Sätt makrot som körs vid klick och spara namnet för tooltip
        buffButton:SetAttribute("macrotext1", "/cast " .. missingBuff)
        buffButton:SetAttribute("currentSpell", missingBuff)
    else
        buffButton.icon:SetDesaturated(true)
        buffButton.indicator:SetColorTexture(0.07, 0.07, 0.07, 1)
        
        buffButton:SetAttribute("macrotext1", nil)
        buffButton:SetAttribute("currentSpell", nil)
    end
end
