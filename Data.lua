local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff")

FroBuff.Data = {}

-- Nu använder vi kategorier. 'cast' är magin som kastas. 'auras' är buffarna som räknas som "godkända".
FroBuff.Data.ClassBuffs = {
    ["MAGE"] = {
        { cast = "Arcane Intellect", auras = {"Arcane Intellect", "Arcane Brilliance"} },
        { cast = "Ice Armor", auras = {"Ice Armor", "Frost Armor", "Mage Armor"} }
    },
    ["PRIEST"] = {
        { cast = "Power Word: Fortitude", auras = {"Power Word: Fortitude", "Prayer of Fortitude"} },
        { cast = "Inner Fire", auras = {"Inner Fire"} },
        { cast = "Shadow Protection", auras = {"Shadow Protection", "Prayer of Shadow Protection"} }
    },
    ["DRUID"] = {
        { cast = "Mark of the Wild", auras = {"Mark of the Wild", "Gift of the Wild"} },
        { cast = "Thorns", auras = {"Thorns"} },
        { cast = "Omen of Clarity", auras = {"Omen of Clarity"} }
    },
    ["PALADIN"] = {
        { cast = "Blessing of Might", auras = {"Blessing of Might", "Greater Blessing of Might"} }
    },
    ["WARLOCK"] = {
        { cast = "Demon Armor", auras = {"Demon Armor", "Fel Armor"} }
    },
    ["SHAMAN"] = {
        { cast = "Lightning Shield", auras = {"Lightning Shield", "Water Shield", "Earth Shield"} }
    }
}

function FroBuff:GetMyClassBuffs()
    local _, playerClass = UnitClass("player")
    return self.Data.ClassBuffs[playerClass] or {}
end

function FroBuff:IsBuffCategoryMissing(auras, unit)
    unit = unit or "player"
    for i = 1, 40 do
        local name = UnitAura(unit, i, "HELPFUL")
        if not name then break end 
        
        -- Om vi hittar NÅGON av de godkända buffarna i gruppen, är vi nöjda
        for _, auraName in ipairs(auras) do
            if name == auraName then
                return false
            end
        end
    end
    
    return true -- Ingen buff från kategorin hittades, den saknas!
end

function FroBuff:GetFirstMissingBuff(buffCategories, unit)
    unit = unit or "player"
    if not buffCategories then return nil end
    
    for _, category in ipairs(buffCategories) do
        if self:IsBuffCategoryMissing(category.auras, unit) then
            return category.cast -- Returnera magin som ska kastas!
        end
    end
    
    return nil
end
