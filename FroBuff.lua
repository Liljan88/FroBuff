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

-- Ersätt hela CreateBuffButton-funktionen:
function FroBuff:CreateBuffButton()
    -- Create the secure button frame
    buffButton = CreateFrame("Button", "FroBuffButton", UIParent, "SecureActionButtonTemplate")
    buffButton:SetSize(36, 36) -- Standard action button size
    buffButton:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    buffButton:SetAttribute("type1", "spell") 

    -- Spell icon background
    buffButton.icon = buffButton:CreateTexture(nil, "BACKGROUND")
    buffButton.icon:SetAllPoints()
    buffButton.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") -- Fallback icon

    -- Blizzard default button border
    buffButton.border = buffButton:CreateTexture(nil, "BORDER")
    buffButton.border:SetSize(62, 62)
    buffButton.border:SetPoint("CENTER", 0, 0)
    buffButton.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    -- The status indicator (moved to top-right corner)
    buffButton.indicator = buffButton:CreateTexture(nil, "OVERLAY")
    buffButton.indicator:SetSize(10, 10)
    buffButton.indicator:SetColorTexture(0.07, 0.07, 0.07, 1)
    buffButton.indicator:SetPoint("TOPRIGHT", buffButton, "TOPRIGHT", 2, 2)
    buffButton.indicator:Show()

    -- Tooltip handling
    buffButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local spell = self:GetAttribute("spell")
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
    -- Only update if the aura change happened to the player
    if unit == "player" then
        self:UpdateBuffStatus()
    end
end

function FroBuff:PLAYER_REGEN_ENABLED()
    -- Update immediately when leaving combat (in case we missed a buff dropping during combat)
    self:UpdateBuffStatus()
end

-- Ersätt hela UpdateBuffStatus-funktionen:
function FroBuff:UpdateBuffStatus()
    if InCombatLockdown() then return end
    
    local myBuffs = self:GetMyClassBuffs()
    local missingBuff = self:GetFirstMissingBuff(myBuffs, "player")
    
    if missingBuff then
        -- Get spell info from the WoW API
        local spellName, _, spellIcon = GetSpellInfo(missingBuff)
        
        if spellIcon then
            buffButton.icon:SetTexture(spellIcon)
            buffButton.icon:SetDesaturated(false) -- Full color when missing
        end

        buffButton.indicator:SetColorTexture(1, 0, 0, 1) -- Red indicator
        buffButton:SetAttribute("spell", missingBuff)
    else
        -- Desaturate (grey out) the icon when all buffs are active
        buffButton.icon:SetDesaturated(true)
        buffButton.indicator:SetColorTexture(0.07, 0.07, 0.07, 1) -- Dark indicator
        buffButton:SetAttribute("spell", nil)
    end
end
