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
    buffButton:SetSize(24, 24)
    buffButton:SetPoint("CENTER", UIParent, "CENTER", 0, -100) -- Standardplacering för nu
    buffButton:SetAttribute("type1", "spell") -- Vänsterklick kastar spell

    -- The indicator (centered square)
    buffButton.indicator = buffButton:CreateTexture(nil, "OVERLAY")
    buffButton.indicator:SetSize(12, 12)
    buffButton.indicator:SetColorTexture(0.07, 0.07, 0.07, 1) -- Mörk färg som standard
    buffButton.indicator:ClearAllPoints()
    buffButton.indicator:SetPoint("CENTER", buffButton, "CENTER", 0, 0)
    buffButton.indicator:Show()
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

function FroBuff:UpdateBuffStatus()
    -- Blizzard prevents changing secure button attributes in combat
    if InCombatLockdown() then return end
    
    -- Fetch the list of buffs our class is responsible for (from Data.lua)
    local myBuffs = self:GetMyClassBuffs()
    
    -- Check if we are missing any of them
    local missingBuff = self:GetFirstMissingBuff(myBuffs, "player")
    
    if missingBuff then
        -- We are missing a buff! Turn the indicator RED and set the button to cast it
        buffButton.indicator:SetColorTexture(1, 0, 0, 1) -- Red
        buffButton:SetAttribute("spell", missingBuff)
    else
        -- All buffs are active! Turn the indicator DARK and clear the spell
        buffButton.indicator:SetColorTexture(0.07, 0.07, 0.07, 1) -- Dark grey
        buffButton:SetAttribute("spell", nil)
    end
end
