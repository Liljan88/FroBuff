local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff")

FroBuff.Data = {}

local function GetBaseBuffs(playerClass)
    if playerClass == "PRIEST" then
        return {
            { cast = "Power Word: Fortitude", auras = {"Power Word: Fortitude", "Prayer of Fortitude"}, target = "group" },
            { cast = "Inner Fire", auras = {"Inner Fire"}, target = "player" },
            { cast = "Shadow Protection", auras = {"Shadow Protection", "Prayer of Shadow Protection"}, target = "group" }
        }
    elseif playerClass == "DRUID" then
        return {
            { cast = "Mark of the Wild", auras = {"Mark of the Wild", "Gift of the Wild"}, target = "group" },
            { cast = "Thorns", auras = {"Thorns"}, target = "group" },
            { cast = "Omen of Clarity", auras = {"Omen of Clarity"}, target = "player" }
        }
    elseif playerClass == "HUNTER" then
        return {
            { cast = "Trueshot Aura", auras = {"Trueshot Aura"}, target = "player" }
        }
    elseif playerClass == "WARLOCK" then
        return {
            { cast = "Demon Armor", auras = {"Demon Armor", "Fel Armor"}, target = "player" }
        }
    elseif playerClass == "SHAMAN" then
        return {
            { cast = "Lightning Shield", auras = {"Lightning Shield", "Water Shield", "Earth Shield"}, target = "player" }
        }
    end
    return {}
end

function FroBuff:GetMyClassBuffs()
    local _, playerClass = UnitClass("player")
    local buffs = GetBaseBuffs(playerClass)
    
    if playerClass == "MAGE" then
        table.insert(buffs, { cast = "Arcane Intellect", auras = {"Arcane Intellect", "Arcane Brilliance"}, target = "group" })
        
        local preferredArmor = self.db.profile.solo.mageArmor or "Ice Armor"
        if preferredArmor == "Mage Armor" then
            table.insert(buffs, { cast = "Mage Armor", auras = {"Mage Armor"}, target = "player" })
        else
            table.insert(buffs, { cast = "Ice Armor", auras = {"Ice Armor", "Frost Armor"}, target = "player" })
        end
    end
    
    return buffs
end

function FroBuff:IsBuffCategoryMissing(auras, unit)
    unit = unit or "player"
    local threshold = self.db.profile.rebuffThreshold or 300 -- Hämta från AceDB (standard 300s)
    
    for i = 1, 40 do
        -- UnitAura returnerar bla: name, icon, count, dispelType, duration, expirationTime
        local name, _, _, _, _, expirationTime = UnitAura(unit, i, "HELPFUL")
        if not name then break end 
        
        for _, auraName in ipairs(auras) do
            if name == auraName then
                -- Buffen hittades! Ska den snart gå ut?
                if expirationTime and expirationTime > 0 then
                    local timeLeft = expirationTime - GetTime()
                    if timeLeft <= threshold then
                        return true -- Tiden är under tröskelvärdet, behandla som "saknad"
                    end
                end
                
                return false -- Buffen finns och har tillräckligt med tid kvar (eller är permanent)
            end
        end
    end
    return true -- Ingen av de godkända buffarna hittades
end

function FroBuff:GetFirstMissingBuff(buffCategories, unit)
    unit = unit or "player"
    if not buffCategories then return nil end
    
    for _, category in ipairs(buffCategories) do
        if category.target == "player" and unit ~= "player" then
            -- Hoppa över solo-buffs om vi skannar en party-medlem
        else
            if self:IsBuffCategoryMissing(category.auras, unit) then
                return category.cast
            end
        end
    end
    
    return nil
end
