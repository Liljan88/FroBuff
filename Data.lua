local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff")
FroBuff.Data = {}

function FroBuff:GetMyClassBuffs()
    local _, playerClass = UnitClass("player")
    local buffs = {}
    local filters = self.db.profile.filters

    if playerClass == "PRIEST" then
        table.insert(buffs, { cast = "Power Word: Fortitude", groupCast = "Prayer of Fortitude", auras = {"Power Word: Fortitude", "Prayer of Fortitude"}, target = "group" })
        
        if filters.InnerFire then
            table.insert(buffs, { cast = "Inner Fire", auras = {"Inner Fire"}, target = "player" })
        end
        if filters.Shadowform then
            table.insert(buffs, { cast = "Shadowform", auras = {"Shadowform"}, target = "player" })
        end
        if filters.FearWard then
            table.insert(buffs, { cast = "Fear Ward", auras = {"Fear Ward"}, target = "player" })
        end
        
        local prefShadow = self.db.profile.solo.priestShadow or "Shadow Protection"
        if prefShadow == "Prayer of Shadow Protection" then
            table.insert(buffs, { cast = "Prayer of Shadow Protection", auras = {"Prayer of Shadow Protection"}, target = "player" })
        else
            table.insert(buffs, { cast = "Shadow Protection", groupCast = "Prayer of Shadow Protection", auras = {"Shadow Protection", "Prayer of Shadow Protection"}, target = "group" })
        end

    elseif playerClass == "DRUID" then
        table.insert(buffs, { cast = "Mark of the Wild", groupCast = "Gift of the Wild", auras = {"Mark of the Wild", "Gift of the Wild"}, target = "group" })
        if filters.Thorns then table.insert(buffs, { cast = "Thorns", auras = {"Thorns"}, target = "group" }) end
        if filters.OmenOfClarity then table.insert(buffs, { cast = "Omen of Clarity", auras = {"Omen of Clarity"}, target = "player" }) end

    elseif playerClass == "MAGE" then
        table.insert(buffs, { cast = "Arcane Intellect", groupCast = "Arcane Brilliance", auras = {"Arcane Intellect", "Arcane Brilliance"}, target = "group" })
        local prefArmor = self.db.profile.solo.mageArmor or "Ice Armor"
        if prefArmor == "Mage Armor" then
            table.insert(buffs, { cast = "Mage Armor", auras = {"Mage Armor"}, target = "player" })
        else
            table.insert(buffs, { cast = "Ice Armor", auras = {"Ice Armor", "Frost Armor"}, target = "player" })
        end
    end
    
    return buffs
end

function FroBuff:IsBuffCategoryMissing(auras, unit)
    unit = unit or "player"
    local threshold = self.db.profile.rebuffThreshold or 300 
    
    for i = 1, 40 do
        local name, _, _, _, _, expirationTime = UnitAura(unit, i, "HELPFUL")
        if not name then break end 
        for _, auraName in ipairs(auras) do
            if name == auraName then
                if expirationTime and expirationTime > 0 then
                    if (expirationTime - GetTime()) <= threshold then return true end
                end
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
        if not (category.target == "player" and unit ~= "player") then
            if self:IsBuffCategoryMissing(category.auras, unit) then
                return category.cast
            end
        end
    end
    return nil
end

function FroBuff:GetNeededGroupBuff(buffCategories)
    if not buffCategories then return nil end
    local threshold = self.db.profile.party.groupThreshold or 3
    
    local activeUnits = {"player"}
    for i = 1, 4 do
        local u = "party"..i
        if UnitExists(u) and UnitIsConnected(u) and not UnitIsDeadOrGhost(u) and UnitIsVisible(u) then
            table.insert(activeUnits, u)
        end
    end

    for _, category in ipairs(buffCategories) do
        if category.groupCast then
            local missingCount = 0
            for _, unit in ipairs(activeUnits) do
                if self:IsBuffCategoryMissing(category.auras, unit) then
                    missingCount = missingCount + 1
                end
            end
            if missingCount >= threshold then
                return category.groupCast, missingCount
            end
        end
    end
    return nil, 0
end
