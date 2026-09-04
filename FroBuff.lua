local _, ns = ...
local AceAddon = LibStub("AceAddon-3.0")
local FroCore = AceAddon:GetAddon("FroCore", true)

local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local froCoreIsActive = FroCore and (isLoaded and isLoaded("FroCore"))

-- SÄKER HÄMTNING: Skapar ingen modul.
local FroBuff = froCoreIsActive and FroCore:GetModule("FroBuff", true) or AceAddon:GetAddon("FroBuff", true)
local Data = FroBuff.Data

-- Performance optimizations
local UnitBuff, GetTime, GetSpellInfo = UnitBuff, GetTime, GetSpellInfo
local UnitIsVisible, UnitIsDeadOrGhost, UnitIsConnected = UnitIsVisible, UnitIsDeadOrGhost, UnitIsConnected
local IsInRaid, IsInGroup, UnitClass = IsInRaid, IsInGroup, UnitClass
local IsSpellInRange, IsUsableSpell = IsSpellInRange, IsUsableSpell
local GetItemCount, GetItemInfo, GetItemIcon, GetWeaponEnchantInfo = GetItemCount, GetItemInfo, C_Item and C_Item.GetItemIconByID or GetItemIcon, GetWeaponEnchantInfo
local select, math_ceil = select, math.ceil

-- ============================================================================
-- UI AND SECURE BUTTONS
-- ============================================================================

local function CreateWarningUI()
    local frame = CreateFrame("Button", "FroBuffWarningFrame", UIParent, "BackdropTemplate")
    frame:SetSize(200, 32) 
    frame:EnableMouse(false)
    frame:SetClampedToScreen(true)
    
    local pos = FroBuff.db.profile.pos
    if pos then frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else frame:SetPoint("CENTER", 0, -150) end
    frame:Hide()

    local btnUp = CreateFrame("Button", "FroBuffScrollUpButton", UIParent, "SecureActionButtonTemplate")
    btnUp:SetAttribute("type", "macro")
    btnUp:RegisterForClicks("AnyUp", "AnyDown")

    local btnDown = CreateFrame("Button", "FroBuffScrollDownButton", UIParent, "SecureActionButtonTemplate")
    btnDown:SetAttribute("type", "macro")
    btnDown:RegisterForClicks("AnyUp", "AnyDown")

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("RIGHT", icon, "LEFT", -10, 0)
    text:SetText("Name >")
    text:SetTextColor(1, 1, 1)
    
    frame.icon = icon
    frame.text = text
    frame.btnUp = btnUp
    frame.btnDown = btnDown

    if froCoreIsActive and FroCore.MakeMovable then
        FroCore:MakeMovable(frame, function(f)
            local point, _, relativePoint, xOfs, yOfs = f:GetPoint()
            FroBuff.db.profile.pos = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
        end)
    else
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            FroBuff.db.profile.pos = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
        end)
    end

    local ag = frame:CreateAnimationGroup()
    local alpha = ag:CreateAnimation("Alpha")
    alpha:SetFromAlpha(1)
    alpha:SetToAlpha(0.2)
    alpha:SetDuration(1.2)
    alpha:SetSmoothing("IN_OUT")
    ag:SetLooping("BOUNCE")
    ag:Play()

    FroBuff.warningUI = frame
end

-- ============================================================================
-- INIT & EVENTS
-- ============================================================================

function FroBuff:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("FroBuffDB", Data.defaults)
    self.unlocked = false
    
    if froCoreIsActive and FroCore then
        FroCore:RegisterModuleOptions("FroBuff", self:GetOptions(), "Automated intelligent buff system.")
    else
        LibStub("AceConfig-3.0"):RegisterOptionsTable("FroBuff", function() return self:GetOptions() end)
        self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FroBuff", "FroBuff")
    end
    
    local LDB = LibStub("LibDataBroker-1.1", true)
    local DBIcon = LibStub("LibDBIcon-1.0", true)
    if LDB and DBIcon then
        local FroBuffDataBroker = LDB:NewDataObject("FroBuff", {
            type = "data source", text = "FroBuff", icon = 136036,
            OnClick = function(_, button) if button == "LeftButton" or button == "RightButton" then FroBuff:OpenConfig() end end,
            OnTooltipShow = function(tooltip) tooltip:AddLine("FroBuff 1.1", 0.4, 0.8, 0.4); tooltip:AddLine("Click to open settings.", 1, 1, 1) end,
        })
        DBIcon:Register("FroBuff", FroBuffDataBroker, self.db.profile.minimap)
    end

    CreateWarningUI()
end

function FroBuff:OnEnable()
    self:RegisterChatCommand("frobuff", "OpenConfig")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.ticker = C_Timer.NewTicker(2, function() self:CheckBuffs() end)
end

function FroBuff:OnDisable()
    if self.ticker then self.ticker:Cancel(); self.ticker = nil end
    if self.warningUI and not InCombatLockdown() then self.warningUI:Hide(); ClearOverrideBindings(self.warningUI) end
    self:UnregisterAllEvents()
end

function FroBuff:PLAYER_REGEN_DISABLED() if self.warningUI then ClearOverrideBindings(self.warningUI) end end
function FroBuff:PLAYER_REGEN_ENABLED() self:CheckBuffs() end
function FroBuff:OpenConfig() if froCoreIsActive and FroCore then FroCore:OpenMenu() else LibStub("AceConfigDialog-3.0"):Open("FroBuff") end end

function FroBuff:UpdateLockState(unlocked)
    if not self.warningUI then return end
    if unlocked then
        self.warningUI:EnableMouse(true)
        self.warningUI:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
        self.warningUI:SetBackdropColor(0.1, 0.5, 0.1, 0.8)
        self.warningUI.text:SetText("FroBuff (Drag)")
        self.warningUI.icon:SetTexture(136122)
        self.warningUI:Show()
    else
        self.warningUI:EnableMouse(false)
        self.warningUI:SetBackdrop(nil)
        self:CheckBuffs()
    end
end

-- ============================================================================
-- CORE LOGIC & SMART SCANNER
-- ============================================================================

local function IsBuffActiveAndValid(unit, spellName, threshold)
    local validAuras = Data.ACCEPTABLE_AURAS[spellName] or {spellName}
    for i = 1, 40 do
        local name, icon, _, _, _, expirationTime = UnitBuff(unit, i)
        if not name then break end
        for _, validName in ipairs(validAuras) do
            if name == validName then
                if expirationTime and expirationTime > 0 then
                    local timeLeft = expirationTime - GetTime()
                    if timeLeft <= threshold then return false, icon, timeLeft else return true, icon, timeLeft end
                else return true, icon, 0 end
            end
        end
    end
    return false, nil, 0
end

local function CanCastOnUnit(spellName, unit)
    local isUsable = IsUsableSpell(spellName)
    if not isUsable then return false end
    if unit ~= "player" then if IsSpellInRange(spellName, unit) == 0 then return false end end
    return true
end

local function HasWellFedBuff()
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if name == "Well Fed" then return true end
    end
    return false
end

function FroBuff:GetActiveProfileKey()
    if IsInRaid() then return "raid" elseif IsInGroup() then return "party" else return "solo" end
end

function FroBuff:CheckBuffs()
    if froCoreIsActive and FroCore and FroCore.UnlockMode then return end
    if self.unlocked then return end 
    if InCombatLockdown() then return end 

    local profileKey = self:GetActiveProfileKey()
    local profile = self.db.profile[profileKey]
    local classSetup = self.db.profile.classSetup
    local threshold = self.db.profile.rebuffThreshold
    
    local targetSpell, targetIcon, targetTimeLeft = nil, nil, 0
    local targetUnitID, targetUnitName, targetSubgroup = "player", "player", nil
    local isFallback, macroType, targetEquipSlot = false, "SPELL", nil

    -- 0. CONSUMABLES
    if classSetup.conjured.selection ~= "None" and classSetup.conjured[profileKey] then
        local itemName = classSetup.conjured.selection
        if GetItemCount(itemName) == 0 then
            local conjureSpell = Data.CONJURE_SPELLS[itemName]
            if conjureSpell and IsUsableSpell(conjureSpell) then
                targetSpell = conjureSpell; macroType = "SPELL"; targetIcon = select(3, GetSpellInfo(conjureSpell)) or 136122
            end
        end
    end

    if not targetSpell and classSetup.mh.selection ~= "None" and classSetup.mh[profileKey] then
        local enchantName = classSetup.mh.selection
        local hasMH, mhExp = GetWeaponEnchantInfo()
        if not hasMH or (mhExp and (mhExp / 1000) <= threshold) then
            if IsUsableSpell(enchantName) then 
                targetSpell = enchantName; macroType = "SPELL"; targetIcon = select(3, GetSpellInfo(enchantName)) or 136122
            elseif GetItemCount(enchantName) > 0 then
                targetSpell = enchantName; macroType = "WEAPON_ENCHANT_ITEM"; targetEquipSlot = 16
                targetIcon = GetItemIcon(enchantName) or select(10, GetItemInfo(enchantName)) or 136122
            end
        end
    end

    if not targetSpell and classSetup.oh.selection ~= "None" and classSetup.oh[profileKey] then
        local enchantName = classSetup.oh.selection
        local _, _, _, _, hasOH, ohExp = GetWeaponEnchantInfo()
        if not hasOH or (ohExp and (ohExp / 1000) <= threshold) then
            if IsUsableSpell(enchantName) then 
                targetSpell = enchantName; macroType = "SPELL"; targetIcon = select(3, GetSpellInfo(enchantName)) or 136122
            elseif GetItemCount(enchantName) > 0 then
                targetSpell = enchantName; macroType = "WEAPON_ENCHANT_ITEM"; targetEquipSlot = 17
                targetIcon = GetItemIcon(enchantName) or select(10, GetItemInfo(enchantName)) or 136122
            end
        end
    end

    if not targetSpell and classSetup.food.selection ~= "None" and classSetup.food[profileKey] then
        if not HasWellFedBuff() then
            local foodList = Data.FOOD_TIERS[classSetup.food.selection]
            if foodList then
                for _, foodItem in ipairs(foodList) do
                    if GetItemCount(foodItem) > 0 then
                        targetSpell = foodItem; macroType = "ITEM"
                        targetIcon = GetItemIcon(foodItem) or select(10, GetItemInfo(foodItem)) or 136122
                        break
                    end
                end
            end
        end
    end

    -- 1. ALWAYS check the player first (Spells)
    if not targetSpell and profile.mainBuff and profile.mainBuff ~= "None" and CanCastOnUnit(profile.mainBuff, "player") then
        local active, icon, timeLeft = IsBuffActiveAndValid("player", profile.mainBuff, threshold)
        if not active then targetSpell, targetIcon, targetTimeLeft = profile.mainBuff, icon or select(3, GetSpellInfo(profile.mainBuff)) or 136122, timeLeft or 0; macroType = "SPELL" end
    end

    if not targetSpell and profile.extraBuffs then
        for spellName, enabled in pairs(profile.extraBuffs) do
            if enabled and CanCastOnUnit(spellName, "player") then
                local active, icon, timeLeft = IsBuffActiveAndValid("player", spellName, threshold)
                if not active then targetSpell, targetIcon, targetTimeLeft = spellName, icon or select(3, GetSpellInfo(spellName)) or 136122, timeLeft or 0; macroType = "SPELL"; break end
            end
        end
    end
    
    if not targetSpell and profile.groupBuffs then
        for spellName, enabled in pairs(profile.groupBuffs) do
            if enabled then
                local activeGroup, iconGroup, timeLeftGroup = IsBuffActiveAndValid("player", spellName, threshold)
                if not activeGroup then
                    if CanCastOnUnit(spellName, "player") then
                        targetSpell = spellName; macroType = "SPELL"
                        local baseBuffName = Data.ACCEPTABLE_AURAS[spellName] and Data.ACCEPTABLE_AURAS[spellName][1] or spellName
                        targetIcon = iconGroup or select(3, GetSpellInfo(baseBuffName)) or 136122
                        targetTimeLeft = timeLeftGroup or 0
                        break
                    else
                        local singleSpell = Data.ACCEPTABLE_AURAS[spellName] and Data.ACCEPTABLE_AURAS[spellName][1]
                        if singleSpell and singleSpell ~= spellName and CanCastOnUnit(singleSpell, "player") then
                            targetSpell = singleSpell; macroType = "SPELL"; targetIcon = select(3, GetSpellInfo(singleSpell)) or 136122
                            targetTimeLeft = timeLeftGroup or 0; isFallback = true
                            break
                        end
                    end
                end
            end
        end
    end

    -- 2. SMART PARTY/RAID SCANNER
    if not targetSpell and (profileKey == "party" or profileKey == "raid") then
        local maxMembers, unitPrefix = 0, ""
        if profileKey == "raid" then maxMembers, unitPrefix = GetNumGroupMembers(), "raid" else maxMembers, unitPrefix = GetNumSubgroupMembers(), "party" end

        if maxMembers > 0 then
            for i = 1, maxMembers do
                local baseUnit = unitPrefix .. i
                local targets = { baseUnit }
                
                -- Lägg till husdjuret i looplistan ENDAST om "Pets" är ikryssat i klassfiltret
                if profile.monitoredClasses["PET"] then
                    if profileKey == "raid" then table.insert(targets, "raidpet" .. i)
                    else table.insert(targets, "partypet" .. i) end
                end

                for _, unit in ipairs(targets) do
                    if UnitExists(unit) then
                        local name, subgroup, online, isDead
                        if profileKey == "raid" then 
                            local rName, _, rSubgroup, _, _, _, _, rOnline, rIsDead = GetRaidRosterInfo(i)
                            subgroup = rSubgroup
                            if unit ~= baseUnit then -- Om det är ett pet
                                name = UnitName(unit)
                                online = UnitIsConnected(unit)
                                isDead = UnitIsDeadOrGhost(unit)
                            else
                                name, online, isDead = rName, rOnline, rIsDead
                            end
                        else 
                            name = UnitName(unit)
                            subgroup = 1
                            online = UnitIsConnected(unit)
                            isDead = UnitIsDeadOrGhost(unit) 
                        end
                        
                        local shouldProcess = online and not isDead and UnitIsVisible(unit)
                        if profileKey == "raid" and not profile.monitoredGroups[subgroup] then shouldProcess = false end
                        
                        if shouldProcess then
                            local _, classFileName = UnitClass(unit)
                            local isPet = (unit ~= baseUnit)
                            
                            -- Tillåt om klassen är övervakad, ELLER om det är ett pet (vilket vi redan filtrerat ovan)
                            if isPet or profile.monitoredClasses[classFileName] ~= false then
                                if profile.groupBuffs then
                                    for spellName, enabled in pairs(profile.groupBuffs) do
                                        if enabled then
                                            local isManaWaste = Data.MANA_BUFFS[spellName] and Data.NO_MANA_CLASSES[classFileName]
                                            if isPet then isManaWaste = false end 
                                            
                                            if not isManaWaste then
                                                local active, icon, timeLeft = IsBuffActiveAndValid(unit, spellName, threshold)
                                                if not active then
                                                    local spellToCast = nil
                                                    if CanCastOnUnit(spellName, unit) then spellToCast = spellName
                                                    else
                                                        local singleSpell = Data.ACCEPTABLE_AURAS[spellName] and Data.ACCEPTABLE_AURAS[spellName][1]
                                                        if singleSpell and singleSpell ~= spellName and CanCastOnUnit(singleSpell, unit) then spellToCast = singleSpell; isFallback = true end
                                                    end
                                                    if spellToCast then targetSpell = spellToCast; macroType = "SPELL"; targetUnitID = unit; targetUnitName = name; targetSubgroup = (profileKey == "raid") and subgroup or nil; targetIcon = icon or select(3, GetSpellInfo(spellToCast)) or 136122; targetTimeLeft = timeLeft or 0; break end
                                                end
                                            end
                                        end
                                    end
                                end
                                if not targetSpell and profile.extraBuffs then
                                    for spellName, enabled in pairs(profile.extraBuffs) do
                                        if enabled then
                                            local isSelfOnly = profile.selfOnlyExtra and profile.selfOnlyExtra[spellName]
                                            if not isSelfOnly then
                                                local isManaWaste = Data.MANA_BUFFS[spellName] and Data.NO_MANA_CLASSES[classFileName]
                                                if isPet then isManaWaste = false end
                                                
                                                if not isManaWaste and CanCastOnUnit(spellName, unit) then
                                                    local active, icon, timeLeft = IsBuffActiveAndValid(unit, spellName, threshold)
                                                    if not active then targetSpell = spellName; macroType = "SPELL"; targetUnitID = unit; targetUnitName = name; targetSubgroup = (profileKey == "raid") and subgroup or nil; targetIcon = icon or select(3, GetSpellInfo(spellName)) or 136122; targetTimeLeft = timeLeft or 0; break end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if targetSpell then break end
                end
                if targetSpell then break end
            end
        end
    end

    -- ============================================================================
    -- ACTION: UPDATE UI AND DYNAMIC MACRO
    -- ============================================================================
    if targetSpell then
        local displayText = targetUnitName == "player" and UnitName("player") or targetUnitName
        if targetSubgroup then displayText = displayText .. " (G" .. targetSubgroup .. ")" end
        if isFallback then displayText = displayText .. " (Fallback)" end
        
        if targetTimeLeft > 0 then displayText = displayText .. " (" .. math_ceil(targetTimeLeft) .. "s) >"
        else displayText = displayText .. " >" end
        
        self.warningUI.text:SetText(displayText)
        self.warningUI.icon:SetTexture(targetIcon)
        
        local macroText = "/console Sound_EnableErrorSpeech 0\n"
        if macroType == "ITEM" or macroType == "WEAPON_ENCHANT_ITEM" then
            macroText = macroText .. "/use " .. targetSpell .. "\n"
            if targetEquipSlot then
                macroText = macroText .. "/use " .. targetEquipSlot .. "\n"
                macroText = macroText .. "/click StaticPopup1Button1\n"
            end
        else
            macroText = macroText .. "/cast [@" .. targetUnitID .. "] " .. targetSpell .. "\n"
        end
        macroText = macroText .. "/console Sound_EnableErrorSpeech 1\n/run UIErrorsFrame:Clear()\n"
        
        self.warningUI.btnUp:SetAttribute("macrotext", macroText .. "/run CameraZoomIn(1.5)")
        self.warningUI.btnDown:SetAttribute("macrotext", macroText .. "/run CameraZoomOut(1.5)")
        
        if self.db.profile.enableScrollBind then
            SetOverrideBindingClick(self.warningUI, true, "MOUSEWHEELUP", "FroBuffScrollUpButton")
            SetOverrideBindingClick(self.warningUI, true, "MOUSEWHEELDOWN", "FroBuffScrollDownButton")
        end
        
        if self.db.profile.customBind and self.db.profile.customBind ~= "" then
            SetOverrideBindingClick(self.warningUI, true, self.db.profile.customBind, "FroBuffScrollUpButton")
        end
        
        self.warningUI:Show()
    else
        self.warningUI.icon:SetTexture(nil)
        self.warningUI:Hide()
        self.warningUI.btnUp:SetAttribute("macrotext", nil)
        self.warningUI.btnDown:SetAttribute("macrotext", nil)
        ClearOverrideBindings(self.warningUI)
    end
end