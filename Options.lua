local _, ns = ...
local AceAddon = LibStub("AceAddon-3.0")
local FroCore = AceAddon:GetAddon("FroCore", true)

local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local froCoreIsActive = FroCore and (isLoaded and isLoaded("FroCore"))

local FroBuff = froCoreIsActive and FroCore:GetModule("FroBuff", true) or AceAddon:GetAddon("FroBuff", true)
local Data = FroBuff.Data

function FroBuff:GetCategorySpells(category)
    local _, playerClass = UnitClass("player")
    local classData = Data.BUFF_DB[playerClass]
    local spells = {}
    if classData and classData[category] then
        for _, spellName in ipairs(classData[category]) do spells[spellName] = Data.DISPLAY_NAMES[spellName] or spellName end
    end
    spells["None"] = "None"
    return spells
end

local function GetDropdownList(listType)
    local list = { ["None"] = "None" }
    local _, playerClass = UnitClass("player")
    
    if listType == "Conjured" then
        if playerClass == "MAGE" then list["Mana Ruby"] = "Mana Ruby"; list["Mana Citrine"] = "Mana Citrine"; list["Mana Jade"] = "Mana Jade"; list["Mana Agate"] = "Mana Agate"
        elseif playerClass == "WARLOCK" then list["Major Healthstone"] = "Major Healthstone"; list["Greater Healthstone"] = "Greater Healthstone"; list["Healthstone"] = "Healthstone"; list["Lesser Healthstone"] = "Lesser Healthstone"; list["Minor Healthstone"] = "Minor Healthstone" end
    elseif listType == "Food" then
        list["+12 Stam/Spirit"] = "+12 Stam/Spirit (Tender Wolf Steak)"; list["+8 Stam/Spirit"] = "+8 Stam/Spirit"; list["+6 Stam/Spirit"] = "+6 Stam/Spirit"
        list["+20 Strength"] = "+20 Strength"; list["+10 Agility"] = "+10 Agility (Grilled Squid)"; list["+10 Intellect"] = "+10 Intellect (Runn Tum Tuber)"; list["+10 MP5"] = "+10 MP5"
    elseif listType == "Weapon" then
        if Data.WEAPON_ENCHANTS[playerClass] then for _, enchant in ipairs(Data.WEAPON_ENCHANTS[playerClass]) do list[enchant] = enchant end end
    end
    return list
end

local function AddExtraBuffOptions(args, profileKey, startOrder)
    local _, playerClass = UnitClass("player")
    local classData = Data.BUFF_DB[playerClass]
    if classData and classData.Extra then
        local order = startOrder
        args["extra_section_header"] = { type = "header", name = "Extra Buffs (Short Duration)", order = order }
        order = order + 1

        for _, spellName in ipairs(classData.Extra) do
            local safeKey = spellName:gsub("[^%w]", "_")
            local displayName = Data.DISPLAY_NAMES[spellName] or spellName
            args["group_" .. safeKey] = {
                type = "group", name = "", inline = true, order = order,
                args = {
                    ["extra_" .. safeKey] = { type = "toggle", name = displayName, desc = "Maintain " .. spellName, width = 1.4, get = function() return FroBuff.db.profile[profileKey].extraBuffs[spellName] end, set = function(info, val) FroBuff.db.profile[profileKey].extraBuffs[spellName] = val end, order = 1 },
                    ["self_" .. safeKey] = { type = "toggle", name = "Self-Only", desc = "Do not scan or cast this on other players.", width = 0.6, get = function() return FroBuff.db.profile[profileKey].selfOnlyExtra[spellName] end, set = function(info, val) FroBuff.db.profile[profileKey].selfOnlyExtra[spellName] = val end, order = 2 },
                },
            }
            order = order + 1
        end
        return order
    end
    return startOrder
end

local function CreateClassSetupRow(args, key, name, dropdownList, order)
    args["setup_" .. key] = {
        type = "group", name = "", inline = true, order = order,
        args = {
            select = { type = "select", name = name, values = dropdownList, width = 1.0, get = function() return FroBuff.db.profile.classSetup[key].selection end, set = function(info, val) FroBuff.db.profile.classSetup[key].selection = val end, order = 1 },
            solo = { type = "toggle", name = "Solo", width = 0.5, get = function() return FroBuff.db.profile.classSetup[key].solo end, set = function(info, val) FroBuff.db.profile.classSetup[key].solo = val end, order = 2 },
            party = { type = "toggle", name = "Party", width = 0.5, get = function() return FroBuff.db.profile.classSetup[key].party end, set = function(info, val) FroBuff.db.profile.classSetup[key].party = val end, order = 3 },
            raid = { type = "toggle", name = "Raid", width = 0.5, get = function() return FroBuff.db.profile.classSetup[key].raid end, set = function(info, val) FroBuff.db.profile.classSetup[key].raid = val end, order = 4 },
        }
    }
end

function FroBuff:GetOptions()
    local partyArgs = { mainSelect = { type = "select", name = "Main Buff (Stance/Armor)", values = function() return FroBuff:GetCategorySpells("Main") end, get = function() return FroBuff.db.profile.party.mainBuff end, set = function(info, value) FroBuff.db.profile.party.mainBuff = value end, order = 1 } }
    local nextOrder = AddExtraBuffOptions(partyArgs, "party", 2)
    partyArgs["groupCheckboxes"] = { type = "multiselect", name = "Group Buffs (Long / AoE)", values = function() return FroBuff:GetCategorySpells("Group") end, get = function(info, key) return FroBuff.db.profile.party.groupBuffs[key] end, set = function(info, key, value) FroBuff.db.profile.party.groupBuffs[key] = value end, order = nextOrder }
    -- FIX: Lade till PET här
    partyArgs["classFilters"] = { type = "multiselect", name = "Allowed Classes", values = { WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter", ROGUE="Rogue", PRIEST="Priest", SHAMAN="Shaman", MAGE="Mage", WARLOCK="Warlock", DRUID="Druid", PET="Pets" }, get = function(info, key) return FroBuff.db.profile.party.monitoredClasses[key] end, set = function(info, key, value) FroBuff.db.profile.party.monitoredClasses[key] = value end, order = nextOrder + 1 }

    local raidArgs = { mainSelect = { type = "select", name = "Main Buff (Stance/Armor)", values = function() return FroBuff:GetCategorySpells("Main") end, get = function() return FroBuff.db.profile.raid.mainBuff end, set = function(info, value) FroBuff.db.profile.raid.mainBuff = value end, order = 1 } }
    nextOrder = AddExtraBuffOptions(raidArgs, "raid", 2)
    raidArgs["groupCheckboxes"] = { type = "multiselect", name = "Group Buffs (Long / AoE)", values = function() return FroBuff:GetCategorySpells("Group") end, get = function(info, key) return FroBuff.db.profile.raid.groupBuffs[key] end, set = function(info, key, value) FroBuff.db.profile.raid.groupBuffs[key] = value end, order = nextOrder }
    raidArgs["raidGroups"] = { type = "multiselect", name = "Monitored Raid Groups", values = { [1]="Group 1", [2]="Group 2", [3]="Group 3", [4]="Group 4", [5]="Group 5", [6]="Group 6", [7]="Group 7", [8]="Group 8" }, get = function(info, key) return FroBuff.db.profile.raid.monitoredGroups[key] end, set = function(info, key, value) FroBuff.db.profile.raid.monitoredGroups[key] = value end, order = nextOrder + 1 }
    -- FIX: Lade till PET här
    raidArgs["classFilters"] = { type = "multiselect", name = "Allowed Classes", values = { WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter", ROGUE="Rogue", PRIEST="Priest", SHAMAN="Shaman", MAGE="Mage", WARLOCK="Warlock", DRUID="Druid", PET="Pets" }, get = function(info, key) return FroBuff.db.profile.raid.monitoredClasses[key] end, set = function(info, key, value) FroBuff.db.profile.raid.monitoredClasses[key] = value end, order = nextOrder + 2 }

    local setupArgs = { header1 = { type = "header", name = "Consumables & Setup", order = 1 } }
    local _, playerClass = UnitClass("player")
    local orderIndex = 2
    if playerClass == "MAGE" or playerClass == "WARLOCK" then CreateClassSetupRow(setupArgs, "conjured", "Conjured Item", GetDropdownList("Conjured"), orderIndex); orderIndex = orderIndex + 1 end
    CreateClassSetupRow(setupArgs, "food", "Food Buff", GetDropdownList("Food"), orderIndex); orderIndex = orderIndex + 1
    CreateClassSetupRow(setupArgs, "mh", "Main Hand Enchant", GetDropdownList("Weapon"), orderIndex); orderIndex = orderIndex + 1
    CreateClassSetupRow(setupArgs, "oh", "Off Hand Enchant", GetDropdownList("Weapon"), orderIndex)

    return {
        type = "group", name = "FroBuff", childGroups = "tab",
        args = {
            generalTab = {
                type = "group", name = "General", order = 1,
                args = {
                    timeThreshold = { type = "range", name = "Rebuff Threshold (Seconds)", min = 5, max = 300, step = 5, get = function() return FroBuff.db.profile.rebuffThreshold end, set = function(info, value) FroBuff.db.profile.rebuffThreshold = value end, order = 1 },
                    scrollBindToggle = { type = "toggle", name = "Enable Mousewheel Buffing", get = function() return FroBuff.db.profile.enableScrollBind end, set = function(info, value) FroBuff.db.profile.enableScrollBind = value; if not value and FroBuff.warningUI and not InCombatLockdown() then ClearOverrideBindings(FroBuff.warningUI) end end, order = 2 },
                    customBind = { type = "keybinding", name = "Custom Buff Keybind", desc = "Set an additional key (like Mouse Button 4) to trigger the buff.\n\nWARNING: Avoid binding plain letters (like 'F') without modifiers. It will block you from typing that letter in chat when a buff is missing! Use Mouse buttons or modifiers (Shift-F). Press ESC to clear.", get = function() return FroBuff.db.profile.customBind end, set = function(info, value) FroBuff.db.profile.customBind = value; if FroBuff.warningUI and not InCombatLockdown() then FroBuff:CheckBuffs() end end, order = 3 },
                    minimapToggle = { type = "toggle", name = "Show Minimap Icon", get = function() return not FroBuff.db.profile.minimap.hide end, set = function(info, value) FroBuff.db.profile.minimap.hide = not value; local icon = LibStub("LibDBIcon-1.0", true); if icon then if value then icon:Show("FroBuff") else icon:Hide("FroBuff") end end end, order = 4 },
                    unlockToggle = (not froCoreIsActive) and { type = "toggle", name = "Unlock Warning Frame", get = function() return FroBuff.unlocked end, set = function(info, value) FroBuff.unlocked = value; FroBuff:UpdateLockState(value) end, order = 5 } or nil,
                },
            },
            soloTab = { type = "group", name = "Solo Buffs", order = 2, args = { mainSelect = { type = "select", name = "Main Buff (Stance/Armor)", values = function() return FroBuff:GetCategorySpells("Main") end, get = function() return FroBuff.db.profile.solo.mainBuff end, set = function(info, value) FroBuff.db.profile.solo.mainBuff = value end, order = 1 }, extraCheckboxes = { type = "multiselect", name = "Single Buffs (Short)", values = function() return FroBuff:GetCategorySpells("Extra") end, get = function(info, key) return FroBuff.db.profile.solo.extraBuffs[key] end, set = function(info, key, value) FroBuff.db.profile.solo.extraBuffs[key] = value end, order = 2 }, groupCheckboxes = { type = "multiselect", name = "Group Buffs (Long / AoE)", values = function() return FroBuff:GetCategorySpells("Group") end, get = function(info, key) return FroBuff.db.profile.solo.groupBuffs[key] end, set = function(info, key, value) FroBuff.db.profile.solo.groupBuffs[key] = value end, order = 3 } } },
            partyTab = { type = "group", name = "Party Buffs", order = 3, args = partyArgs },
            raidTab = { type = "group", name = "Raid Buffs", order = 4, args = raidArgs },
            classSetupTab = { type = "group", name = "Class Setup", order = 5, args = setupArgs },
        },
    }
end