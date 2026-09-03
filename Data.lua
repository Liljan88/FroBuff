local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff")

FroBuff.Data = {}

-- Tabell som definierar vilka buffs (namn) varje klass ansvarar för/kan kasta
FroBuff.Data.ClassBuffs = {
    ["MAGE"] = {
        "Arcane Intellect",
        "Arcane Brilliance",
        "Frost Armor",
        "Ice Armor",
        "Mage Armor"
    },
    ["PRIEST"] = {
        "Power Word: Fortitude",
        "Prayer of Fortitude",
        "Inner Fire",
        "Shadow Protection",
        "Prayer of Shadow Protection"
    },
    ["DRUID"] = {
        "Mark of the Wild",
        "Gift of the Wild",
        "Thorns",
        "Omen of Clarity"
    },
    ["PALADIN"] = {
        "Blessing of Might",
        "Blessing of Wisdom",
        "Blessing of Kings",
        "Blessing of Sanctuary",
        "Righteous Fury"
    },
    ["WARLOCK"] = {
        "Demon Armor",
        "Fel Armor",
        "Detect Invisibility"
    },
    ["SHAMAN"] = {
        "Lightning Shield",
        "Water Shield"
    }
}

-- Funktion för att hämta vilka buffs den aktuella spelaren (din klass) kan hantera
function FroBuff:GetMyClassBuffs()
    local _, playerClass = UnitClass("player")
    return self.Data.ClassBuffs[playerClass] or {}
end

-- Funktion för att kontrollera om en specifik buff saknas på en enhet (default "player")
function FroBuff:IsBuffMissing(buffName, unit)
    unit = unit or "player"
    
    -- Vi loopar igenom alla aktuella buffs på enheten (max 40)
    for i = 1, 40 do
        local name = UnitAura(unit, i, "HELPFUL")
        
        -- Om name är nil har vi nått slutet på listan med aktiva buffs
        if not name then break end 
        
        -- Om vi hittar buffen, returnera false (den saknas INTE)
        if name == buffName then
            return false
        end
    end
    
    -- Loopade igenom allt utan att hitta buffen, den saknas!
    return true
end

-- Funktion för att hitta den första buffen som saknas från en lista av buffs
function FroBuff:GetFirstMissingBuff(buffList, unit)
    unit = unit or "player"
    if not buffList then return nil end
    
    for _, buffName in ipairs(buffList) do
        if self:IsBuffMissing(buffName, unit) then
            return buffName -- Returnerar namnet på den första buffen som saknas
        end
    end
    
    return nil -- Alla buffs i listan är aktiva!
end
