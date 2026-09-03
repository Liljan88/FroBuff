local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff")

FroBuff.Data = {}

-- Vi lyfter ut bas-buffarna för andra klasser så koden hålls ren
local function GetBaseBuffs(playerClass)
    if playerClass == "PRIEST" then
        return {
            { cast = "Power Word: Fortitude", auras = {"Power Word: Fortitude", "Prayer of Fortitude"} },
            { cast = "Inner Fire", auras = {"Inner Fire"} },
            { cast = "Shadow Protection", auras = {"Shadow Protection", "Prayer of Shadow Protection"} }
        }
    elseif playerClass == "DRUID" then
        return {
            { cast = "Mark of the Wild", auras = {"Mark of the Wild", "Gift of the Wild"} },
            { cast = "Thorns", auras = {"Thorns"} },
            { cast = "Omen of Clarity", auras = {"Omen of Clarity"} }
        }
    elseif playerClass == "PALADIN" then
        return {
            { cast = "Blessing of Might", auras = {"Blessing of Might", "Greater Blessing of Might"} }
        }
    elseif playerClass == "WARLOCK" then
        return {
            { cast = "Demon Armor", auras = {"Demon Armor", "Fel Armor"} }
        }
    elseif playerClass == "SHAMAN" then
        return {
            { cast = "Lightning Shield", auras = {"Lightning Shield", "Water Shield", "Earth Shield"} }
        }
    end
    return {} -- Returnera tom lista om ingen matchning
end

-- Denna funktion hämtar nu dynamiskt vad som ska buffas baserat på dina AceDB-inställningar!
function FroBuff:GetMyClassBuffs()
    local _, playerClass = UnitClass("player")
    local buffs = GetBaseBuffs(playerClass)
    
    if playerClass == "MAGE" then
        -- Arcane Intellect ska alltid övervakas
        table.insert(buffs, { cast = "Arcane Intellect", auras = {"Arcane Intellect", "Arcane Brilliance"} })
        
        -- Läs av vilken Armor spelaren valt i Options-menyn (Standard: Ice Armor)
        local preferredArmor = self.db.profile.solo.mageArmor or "Ice Armor"
        
        if preferredArmor == "Mage Armor" then
            table.insert(buffs, { cast = "Mage Armor", auras = {"Mage Armor"} })
        else
            -- Både Ice och Frost Armor hanteras här
            table.insert(buffs, { cast = "Ice Armor", auras = {"Ice Armor", "Frost Armor"} })
        end
    end
    
    return buffs
end

function FroBuff:IsBuffCategoryMissing(auras, unit)
    unit = unit or "player"
    for i = 1, 40 do
        local name = UnitAura(unit, i, "HELPFUL")
        if not name then break end 
        
        for _, auraName in ipairs(auras) do
            if name == auraName then
                return false
            end
        end
    end
    
    return true
end

function FroBuff:GetFirstMissingBuff(buffCategories, unit)
    unit = unit or "player"
    if not buffCategories then return nil end
    
    for _, category in ipairs(buffCategories) do
        if self:IsBuffCategoryMissing(category.auras, unit) then
            return category.cast
        end
    end
    
    return nil
end
