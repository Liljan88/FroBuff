local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff")

local function GetMageArmorOptions()
    return { ["Ice Armor"] = "Ice/Frost Armor", ["Mage Armor"] = "Mage Armor" }
end

local function GetPriestShadowOptions()
    return { ["Shadow Protection"] = "Shadow Protection (10 min)", ["Prayer of Shadow Protection"] = "Prayer of Shadow Protection (20 min)" }
end

local options = {
    name = "FroBuff",
    handler = FroBuff,
    type = "group",
    childGroups = "tab",
    args = {
        general = {
            type = "group",
            name = "Allmänt",
            order = 1,
            args = {
                toggleMinimap = {
                    type = "toggle", name = "Visa Minimap Ikon", order = 1,
                    get = function() return not FroBuff.db.profile.minimap.hide end,
                    set = function(_, value)
                        FroBuff.db.profile.minimap.hide = not value
                        if FroBuff.db.profile.minimap.hide then LibStub("LibDBIcon-1.0"):Hide("FroBuff") else LibStub("LibDBIcon-1.0"):Show("FroBuff") end
                    end,
                },
                lockFrame = {
                    type = "toggle", name = "Lås FroBuff", order = 2,
                    get = function() return FroBuff.db.profile.locked end,
                    set = function(_, value) FroBuff.db.profile.locked = value end,
                },
                rebuffThreshold = {
                    type = "range", name = "Buff Tröskelvärde (Sekunder)", order = 3,
                    min = 0, max = 600, step = 10,
                    get = function() return FroBuff.db.profile.rebuffThreshold end,
                    set = function(_, value) FroBuff.db.profile.rebuffThreshold = value; FroBuff:UpdateBuffStatus() end,
                },
            },
        },
        solo = {
            type = "group",
            name = "Solo & Filter",
            order = 2,
            args = {
                mageArmor = {
                    type = "select", name = "Föredragen Armor (Mage)", order = 1,
                    values = GetMageArmorOptions(),
                    get = function() return FroBuff.db.profile.solo.mageArmor end,
                    set = function(_, value) FroBuff.db.profile.solo.mageArmor = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() local _, c = UnitClass("player"); return c ~= "MAGE" end,
                },
                priestShadow = {
                    type = "select", name = "Föredragen Shadow Protection", order = 2,
                    values = GetPriestShadowOptions(),
                    get = function() return FroBuff.db.profile.solo.priestShadow end,
                    set = function(_, value) FroBuff.db.profile.solo.priestShadow = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() local _, c = UnitClass("player"); return c ~= "PRIEST" end,
                },
                filterHeader = { type = "header", name = "Aktiva Buff-filter", order = 10 },
                enableInnerFire = {
                    type = "toggle", name = "Inner Fire (Präst)", order = 11,
                    get = function() return FroBuff.db.profile.filters.InnerFire end,
                    set = function(_, value) FroBuff.db.profile.filters.InnerFire = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() local _, c = UnitClass("player"); return c ~= "PRIEST" end,
                },
                enableShadowform = {
                    type = "toggle", name = "Shadowform (Präst)", order = 12,
                    get = function() return FroBuff.db.profile.filters.Shadowform end,
                    set = function(_, value) FroBuff.db.profile.filters.Shadowform = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() local _, c = UnitClass("player"); return c ~= "PRIEST" end,
                },
                enableFearWard = {
                    type = "toggle", name = "Fear Ward (Dvärg)", order = 13,
                    get = function() return FroBuff.db.profile.filters.FearWard end,
                    set = function(_, value) FroBuff.db.profile.filters.FearWard = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() 
                        local _, c = UnitClass("player")
                        local _, r = UnitRace("player")
                        return c ~= "PRIEST" or r ~= "Dwarf" 
                    end,
                },
                enableThorns = {
                    type = "toggle", name = "Thorns (Druid)", order = 14,
                    get = function() return FroBuff.db.profile.filters.Thorns end,
                    set = function(_, value) FroBuff.db.profile.filters.Thorns = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() local _, c = UnitClass("player"); return c ~= "DRUID" end,
                },
                enableOmen = {
                    type = "toggle", name = "Omen of Clarity (Druid)", order = 15,
                    get = function() return FroBuff.db.profile.filters.OmenOfClarity end,
                    set = function(_, value) FroBuff.db.profile.filters.OmenOfClarity = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() local _, c = UnitClass("player"); return c ~= "DRUID" end,
                },
            },
        },
        party = {
            type = "group",
            name = "Party & Raid",
            order = 3,
            args = {
                groupThreshold = {
                    type = "range", name = "Grupp-buff Tröskel (Antal pers)", order = 1,
                    min = 2, max = 5, step = 1,
                    get = function() return FroBuff.db.profile.party.groupThreshold end,
                    set = function(_, value) FroBuff.db.profile.party.groupThreshold = value; FroBuff:UpdateBuffStatus() end,
                }
            }
        }
    },
}

function FroBuff:SetupOptions()
    FroBuff.db = LibStub("AceDB-3.0"):New("FroBuffDB", {
        profile = {
            minimap = { hide = false },
            locked = true,
            framePosition = nil,
            rebuffThreshold = 300,
            solo = { mageArmor = "Ice Armor", priestShadow = "Shadow Protection" },
            party = { groupThreshold = 3 },
            filters = { InnerFire = true, Shadowform = true, FearWard = true, Thorns = true, OmenOfClarity = true }
        },
    })

    local FroBuffLDB = LibStub("LibDataBroker-1.1"):NewDataObject("FroBuff", {
        type = "launcher", text = "FroBuff", icon = "Interface\\Icons\\INV_Alchemy_EnchantedVial",
        OnClick = function(_, button)
            if button == "LeftButton" then
                local acd = LibStub("AceConfigDialog-3.0")
                if acd.OpenFrames["FroBuff"] then acd:Close("FroBuff") else acd:Open("FroBuff") end
            elseif button == "RightButton" then
                FroBuff.db.profile.locked = not FroBuff.db.profile.locked
                print("|cFF33FF99FroBuff:|r Fönstret är nu " .. (FroBuff.db.profile.locked and "LÅST" or "UPPLÅST") .. ".")
            end
        end,
        OnTooltipShow = function(tooltip) tooltip:AddLine("FroBuff", 1, 0.82, 0); tooltip:AddLine("Vänster/Högerklick för meny/lås.") end,
    })
    
    LibStub("LibDBIcon-1.0"):Register("FroBuff", FroBuffLDB, FroBuff.db.profile.minimap)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("FroBuff", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FroBuff", "FroBuff")
    
    self:RegisterChatCommand("frobuff", "OpenOptions")
    self:RegisterChatCommand("fb", "OpenOptions")
end

function FroBuff:OpenOptions() LibStub("AceConfigDialog-3.0"):Open("FroBuff") end
