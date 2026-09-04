local AceAddon = LibStub("AceAddon-3.0")
local FroCore = AceAddon:GetAddon("FroCore", true)

local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local froCoreIsActive = FroCore and (isLoaded and isLoaded("FroCore"))

local FroBuff
if froCoreIsActive then
    FroBuff = FroCore:GetModule("FroBuff", true) or FroCore:NewModule("FroBuff", "AceConsole-3.0", "AceEvent-3.0")
else
    FroBuff = AceAddon:GetAddon("FroBuff", true) or AceAddon:NewAddon("FroBuff", "AceConsole-3.0", "AceEvent-3.0")
end

FroBuff.Data = {}

-- ============================================================================
-- CLASS BUFFS
-- ============================================================================

FroBuff.Data.BUFF_DB = {
    MAGE = { Main = {"Ice Armor", "Mage Armor", "Frost Armor"}, Extra = {"Arcane Intellect", "Dampen Magic", "Amplify Magic", "Mana Shield", "Frost Ward", "Fire Ward"}, Group = {"Arcane Brilliance"} },
    PRIEST = { Main = {"Inner Fire"}, Extra = {"Power Word: Fortitude", "Divine Spirit", "Shadow Protection", "Fear Ward", "Shadowform", "Touch of Weakness", "Shadowguard", "Elune's Grace"}, Group = {"Prayer of Fortitude", "Prayer of Spirit", "Prayer of Shadow Protection"} },
    WARLOCK = { Main = {"Demon Armor", "Demon Skin", "Fel Armor"}, Extra = {"Detect Greater Invisibility", "Detect Invisibility", "Detect Lesser Invisibility", "Unending Breath", "Soul Link", "Shadow Ward"}, Group = {} },
    PALADIN = { Main = {"Righteous Fury", "Devotion Aura", "Retribution Aura", "Concentration Aura", "Shadow Resistance Aura", "Frost Resistance Aura", "Fire Resistance Aura"}, Extra = {"Blessing of Might", "Blessing of Wisdom", "Blessing of Kings", "Blessing of Salvation", "Blessing of Sanctuary", "Blessing of Light"}, Group = {"Greater Blessing of Might", "Greater Blessing of Wisdom", "Greater Blessing of Kings", "Greater Blessing of Salvation", "Greater Blessing of Sanctuary", "Greater Blessing of Light"} },
    DRUID = { Main = {"Omen of Clarity"}, Extra = {"Mark of the Wild", "Thorns", "Nature's Grasp"}, Group = {"Gift of the Wild"} },
    SHAMAN = { Main = {"Lightning Shield", "Water Shield", "Earth Shield"}, Extra = {}, Group = {} },
    WARRIOR = { Main = {}, Extra = {"Battle Shout", "Commanding Shout"}, Group = {} },
    HUNTER = { Main = {"Aspect of the Hawk", "Aspect of the Monkey", "Aspect of the Cheetah", "Aspect of the Pack", "Aspect of the Wild", "Aspect of the Beast"}, Extra = {"Trueshot Aura"}, Group = {} },
    ROGUE = { Main = {}, Extra = {}, Group = {} }
}

FroBuff.Data.ACCEPTABLE_AURAS = {
    ["Prayer of Fortitude"] = {"Power Word: Fortitude", "Prayer of Fortitude"}, ["Power Word: Fortitude"] = {"Power Word: Fortitude", "Prayer of Fortitude"},
    ["Prayer of Spirit"] = {"Divine Spirit", "Prayer of Spirit"}, ["Divine Spirit"] = {"Divine Spirit", "Prayer of Spirit"},
    ["Prayer of Shadow Protection"] = {"Shadow Protection", "Prayer of Shadow Protection"}, ["Shadow Protection"] = {"Shadow Protection", "Prayer of Shadow Protection"},
    ["Arcane Brilliance"] = {"Arcane Intellect", "Arcane Brilliance"}, ["Arcane Intellect"] = {"Arcane Intellect", "Arcane Brilliance"},
    ["Gift of the Wild"] = {"Mark of the Wild", "Gift of the Wild"}, ["Mark of the Wild"] = {"Mark of the Wild", "Gift of the Wild"},
    ["Greater Blessing of Might"] = {"Blessing of Might", "Greater Blessing of Might"}, ["Blessing of Might"] = {"Blessing of Might", "Greater Blessing of Might"},
    ["Greater Blessing of Wisdom"] = {"Blessing of Wisdom", "Greater Blessing of Wisdom"}, ["Blessing of Wisdom"] = {"Blessing of Wisdom", "Greater Blessing of Wisdom"},
    ["Greater Blessing of Kings"] = {"Blessing of Kings", "Greater Blessing of Kings"}, ["Blessing of Kings"] = {"Blessing of Kings", "Greater Blessing of Kings"},
    ["Greater Blessing of Salvation"] = {"Blessing of Salvation", "Greater Blessing of Salvation"}, ["Blessing of Salvation"] = {"Blessing of Salvation", "Greater Blessing of Salvation"},
    ["Greater Blessing of Sanctuary"] = {"Blessing of Sanctuary", "Greater Blessing of Sanctuary"}, ["Blessing of Sanctuary"] = {"Blessing of Sanctuary", "Greater Blessing of Sanctuary"},
    ["Greater Blessing of Light"] = {"Blessing of Light", "Greater Blessing of Light"}, ["Blessing of Light"] = {"Blessing of Light", "Greater Blessing of Light"},
    ["Detect Lesser Invisibility"] = {"Detect Lesser Invisibility", "Detect Invisibility", "Detect Greater Invisibility"}, 
    ["Detect Invisibility"] = {"Detect Invisibility", "Detect Greater Invisibility"},
    ["Detect Greater Invisibility"] = {"Detect Greater Invisibility"},
    ["Demon Skin"] = {"Demon Skin", "Demon Armor", "Fel Armor"},
    ["Demon Armor"] = {"Demon Armor", "Fel Armor"},
    ["Frost Armor"] = {"Frost Armor", "Ice Armor"},
}

FroBuff.Data.DISPLAY_NAMES = {
    ["Fear Ward"] = "Fear Ward (Dwarf/Draenei)", ["Touch of Weakness"] = "Touch of Weakness (Undead)",
    ["Shadowguard"] = "Shadowguard (Troll)", ["Elune's Grace"] = "Elune's Grace (Night Elf)"
}

FroBuff.Data.MANA_BUFFS = { ["Arcane Intellect"] = true, ["Arcane Brilliance"] = true, ["Divine Spirit"] = true, ["Prayer of Spirit"] = true }
FroBuff.Data.NO_MANA_CLASSES = { ["WARRIOR"] = true, ["ROGUE"] = true }

-- ============================================================================
-- CONSUMABLES
-- ============================================================================

FroBuff.Data.CONJURE_SPELLS = {
    ["Mana Ruby"] = "Conjure Mana Ruby", ["Mana Citrine"] = "Conjure Mana Citrine", ["Mana Jade"] = "Conjure Mana Jade", ["Mana Agate"] = "Conjure Mana Agate",
    ["Major Healthstone"] = "Create Healthstone (Major)", ["Greater Healthstone"] = "Create Healthstone (Greater)", ["Healthstone"] = "Create Healthstone", ["Lesser Healthstone"] = "Create Healthstone (Lesser)", ["Minor Healthstone"] = "Create Healthstone (Minor)"
}

FroBuff.Data.WEAPON_ENCHANTS = {
    MAGE = {"Brilliant Mana Oil", "Brilliant Wizard Oil", "Wizard Oil", "Lesser Mana Oil", "Lesser Wizard Oil", "Minor Mana Oil", "Minor Wizard Oil"},
    PRIEST = {"Brilliant Mana Oil", "Brilliant Wizard Oil", "Wizard Oil", "Lesser Mana Oil", "Lesser Wizard Oil", "Minor Mana Oil", "Minor Wizard Oil"},
    WARLOCK = {"Brilliant Mana Oil", "Brilliant Wizard Oil", "Wizard Oil", "Lesser Mana Oil", "Lesser Wizard Oil", "Minor Mana Oil", "Minor Wizard Oil"},
    PALADIN = {"Brilliant Mana Oil", "Brilliant Wizard Oil", "Wizard Oil", "Lesser Mana Oil", "Lesser Wizard Oil", "Minor Mana Oil", "Minor Wizard Oil", "Elemental Sharpening Stone", "Dense Sharpening Stone", "Solid Sharpening Stone", "Heavy Sharpening Stone", "Coarse Sharpening Stone", "Rough Sharpening Stone"},
    DRUID = {"Brilliant Mana Oil", "Brilliant Wizard Oil", "Wizard Oil", "Lesser Mana Oil", "Lesser Wizard Oil", "Minor Mana Oil", "Minor Wizard Oil", "Elemental Sharpening Stone", "Dense Weightstone", "Solid Weightstone", "Heavy Weightstone", "Coarse Weightstone", "Rough Weightstone"},
    ROGUE = {
        "Instant Poison VI", "Instant Poison V", "Instant Poison IV", "Instant Poison III", "Instant Poison II", "Instant Poison",
        "Deadly Poison V", "Deadly Poison IV", "Deadly Poison III", "Deadly Poison II", "Deadly Poison",
        "Wound Poison IV", "Wound Poison III", "Wound Poison II", "Wound Poison",
        "Crippling Poison II", "Crippling Poison", "Mind-numbing Poison III", "Mind-numbing Poison II", "Mind-numbing Poison",
        "Elemental Sharpening Stone", "Dense Sharpening Stone", "Solid Sharpening Stone", "Heavy Sharpening Stone", "Coarse Sharpening Stone", "Rough Sharpening Stone"
    },
    WARRIOR = {"Elemental Sharpening Stone", "Dense Sharpening Stone", "Solid Sharpening Stone", "Heavy Sharpening Stone", "Coarse Sharpening Stone", "Rough Sharpening Stone", "Dense Weightstone", "Solid Weightstone", "Heavy Weightstone", "Coarse Weightstone", "Rough Weightstone"},
    HUNTER = {"Brilliant Mana Oil", "Brilliant Wizard Oil", "Wizard Oil", "Lesser Mana Oil", "Lesser Wizard Oil", "Minor Mana Oil", "Minor Wizard Oil", "Elemental Sharpening Stone", "Dense Sharpening Stone", "Solid Sharpening Stone", "Heavy Sharpening Stone", "Coarse Sharpening Stone", "Rough Sharpening Stone", "Dense Weightstone", "Solid Weightstone", "Heavy Weightstone", "Coarse Weightstone", "Rough Weightstone"},
    SHAMAN = {"Windfury Weapon", "Rockbiter Weapon", "Flametongue Weapon", "Frostbrand Weapon", "Brilliant Mana Oil", "Brilliant Wizard Oil", "Wizard Oil", "Lesser Mana Oil", "Lesser Wizard Oil", "Minor Mana Oil", "Minor Wizard Oil"},
}

FroBuff.Data.FOOD_TIERS = {
    ["+12 Stam/Spirit"] = {"Monster Omelet", "Tender Wolf Steak", "Spider Sausage", "Heavy Kodo Stew", "Spicy Smoked Snapper"},
    ["+8 Stam/Spirit"] = {"Carrion Surprise", "Mystery Meat Stew", "Dragonbreath Chili", "Heavy Crocolisk Stew"},
    ["+6 Stam/Spirit"] = {"Soothing Turtle Bisque", "Barbecued Buzzard Wing", "Gooey Spider Cake", "Lean Wolf Steak", "Roast Raptor", "Hot Lion Chops"},
    ["+20 Strength"] = {"Smoked Desert Dumplings", "Blessed Sunfruit"},
    ["+10 Agility"] = {"Grilled Squid"},
    ["+10 Intellect"] = {"Runn Tum Tuber Surprise"},
    ["+10 MP5"] = {"Nightfin Soup"}
}

FroBuff.Data.defaults = {
    profile = {
        minimap = { hide = false },
        rebuffThreshold = 20,
        enableScrollBind = true,
        customBind = "",
        pos = nil,
        solo = { mainBuff = "None", extraBuffs = {}, groupBuffs = {} },
        -- FIX: Lade till PET i båda listorna (Party=true, Raid=false som default)
        party = { mainBuff = "None", extraBuffs = {}, groupBuffs = {}, selfOnlyExtra = {}, monitoredClasses = { WARRIOR=true, PALADIN=true, HUNTER=true, ROGUE=true, PRIEST=true, SHAMAN=true, MAGE=true, WARLOCK=true, DRUID=true, PET=true } },
        raid = { mainBuff = "None", extraBuffs = {}, groupBuffs = {}, selfOnlyExtra = {}, monitoredGroups = { [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true }, monitoredClasses = { WARRIOR=true, PALADIN=true, HUNTER=true, ROGUE=true, PRIEST=true, SHAMAN=true, MAGE=true, WARLOCK=true, DRUID=true, PET=false } },
        classSetup = { conjured = { selection = "None", solo = false, party = false, raid = false }, food = { selection = "None", solo = false, party = false, raid = false }, mh = { selection = "None", solo = false, party = false, raid = false }, oh = { selection = "None", solo = false, party = false, raid = false } }
    }
}