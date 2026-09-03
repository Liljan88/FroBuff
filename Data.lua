local addonName, core = ...
local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff", true)
if not FroBuff then
    FroBuff = LibStub("AceAddon-3.0"):NewAddon("FroBuff", "AceEvent-3.0", "AceConsole-3.0")
end

FroBuff.Data = {}

-- Prioritetsmotorn: Känner av vad som saknas.
-- Framöver bygger vi ut denna per klass!
function FroBuff:GetMissingPriorityBuff(unit)
    local hasBuff = false
    for i = 1, 40 do
        local name = UnitBuff(unit, i)
        if not name then break end
        -- Exempel för test (byt ut mot riktig klasslogik sen)
        if name == "Power Word: Fortitude" or name == "Arcane Intellect" then
            hasBuff = true
            break
        end
    end
    
    if not hasBuff and not UnitIsDeadOrGhost(unit) then
        return "Saknar Viktig Buff" 
    end
    
    return nil
end
