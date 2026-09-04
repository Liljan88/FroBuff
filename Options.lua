local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff")

local function GetMageArmorOptions()
    return {
        ["Ice Armor"] = "Ice Armor / Frost Armor",
        ["Mage Armor"] = "Mage Armor",
    }
end

local options = {
    name = "FroBuff",
    handler = FroBuff,
    type = "group",
    childGroups = "tab",
    args = {
        -- FLIK 1: ALLMÄNT
        general = {
            type = "group",
            name = "Allmänt",
            order = 1,
            args = {
                toggleMinimap = {
                    type = "toggle",
                    name = "Visa Minimap Ikon",
                    order = 1,
                    get = function(info) return not FroBuff.db.profile.minimap.hide end,
                    set = function(info, value)
                        FroBuff.db.profile.minimap.hide = not value
                        if FroBuff.db.profile.minimap.hide then
                            LibStub("LibDBIcon-1.0"):Hide("FroBuff")
                        else
                            LibStub("LibDBIcon-1.0"):Show("FroBuff")
                        end
                    end,
                },
                lockFrame = {
                    type = "toggle",
                    name = "Lås FroBuff",
                    order = 2,
                    desc = "Kryssa ur för att kunna flytta buff-knappen.",
                    get = function(info) return FroBuff.db.profile.locked end,
                    set = function(info, value) 
                        FroBuff.db.profile.locked = value 
                    end,
                },
                rebuffThreshold = {
                    type = "range",
                    name = "Buff Tröskelvärde",
                    desc = "Varna när det är mindre än X sekunder kvar på buffen.",
                    order = 3,
                    min = 0,
                    max = 600,
                    step = 10,
                    get = function(info) return FroBuff.db.profile.rebuffThreshold end,
                    set = function(info, value)
                        FroBuff.db.profile.rebuffThreshold = value
                        if FroBuff.UpdateBuffStatus then
                            FroBuff:UpdateBuffStatus()
                        end
                    end,
                },
            },
        },
        -- FLIK 2: SOLO & BUFF-FILTER
        solo = {
            type = "group",
            name = "Solo & Filter",
            order = 2,
            args = {
                description = {
                    type = "description",
                    name = "Här ställer du in solopreferenser och vilka extra buffs/rasbuffs som ska övervakas.\n",
                    order = 1,
                },
                mageArmor = {
                    type = "select",
                    name = "Föredragen Armor (Mage)",
                    order = 2,
                    values = GetMageArmorOptions(),
                    get = function(info) return FroBuff.db.profile.solo.mageArmor end,
                    set = function(info, value)
                        FroBuff.db.profile.solo.mageArmor = value
                        if FroBuff.UpdateBuffStatus then
                            FroBuff:UpdateBuffStatus()
                        end
                    end,
                    hidden = function()
                        local _, class = UnitClass("player")
                        return class ~= "MAGE"
                    end,
                },
                filterHeader = {
                    type = "header",
                    name = "Aktiva Buff-filter",
                    order = 10,
                },
                enableInnerFire = {
                    type = "toggle",
                    name = "Inner Fire (Präst)",
                    order = 11,
                    get = function(info) return FroBuff.db.profile.filters.InnerFire end,
                    set = function(info, value) FroBuff.db.profile.filters.InnerFire = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() local _, c = UnitClass("player"); return c ~= "PRIEST" end,
                },
                enableShadowProtection = {
                    type = "toggle",
                    name = "Shadow Protection / Greater (Präst)",
                    order = 12,
                    get = function(info) return FroBuff.db.profile.filters.ShadowProtection end,
                    set = function(info, value) FroBuff.db.profile.filters.ShadowProtection = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() local _, c = UnitClass("player"); return c ~= "PRIEST" end,
                },
                enableThorns = {
                    type = "toggle",
                    name = "Thorns (Druid)",
                    order = 13,
                    get = function(info) return FroBuff.db.profile.filters.Thorns end,
                    set = function(info, value) FroBuff.db.profile.filters.Thorns = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() local _, c = UnitClass("player"); return c ~= "DRUID" end,
                },
                enableOmen = {
                    type = "toggle",
                    name = "Omen of Clarity (Druid)",
                    order = 14,
                    get = function(info) return FroBuff.db.profile.filters.OmenOfClarity end,
                    set = function(info, value) FroBuff.db.profile.filters.OmenOfClarity = value; FroBuff:UpdateBuffStatus() end,
                    hidden = function() local _, c = UnitClass("player"); return c ~= "DRUID" end,
                },
            },
        },
        -- FLIK 3: PARTY & RAID
        party = {
            type = "group",
            name = "Party & Raid",
            order = 3,
            args = {
                description = {
                    type = "description",
                    name = "Inställningar för Matrix-ramen och gruppövervakning kommer att byggas här.",
                    order = 1,
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
            solo = {
                mageArmor = "Ice Armor",
            },
            filters = {
                InnerFire = true,
                ShadowProtection = true,
                Thorns = true,
                OmenOfClarity = true,
            }
        },
    })

    local FroBuffLDB = LibStub("LibDataBroker-1.1"):NewDataObject("FroBuff", {
        type = "launcher",
        text = "FroBuff",
        icon = "Interface\\Icons\\INV_Alchemy_EnchantedVial",
        OnClick = function(_, button)
            if button == "LeftButton" then
                local acd = LibStub("AceConfigDialog-3.0")
                if acd.OpenFrames["FroBuff"] then
                    acd:Close("FroBuff")
                else
                    acd:Open("FroBuff")
                end
            elseif button == "RightButton" then
                FroBuff.db.profile.locked = not FroBuff.db.profile.locked
                print("|cFF33FF99FroBuff:|r Fönstret är nu " .. (FroBuff.db.profile.locked and "|cFFFF3333LÅST|r" or "|cFF33FF99UPPLÅST|r") .. ".")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("FroBuff", 1, 0.82, 0)
            tooltip:AddLine("Vänsterklicka för att öppna inställningar.")
            tooltip:AddLine("Högerklicka för att låsa/låsa upp fönstret.")
        end,
    })
    
    LibStub("LibDBIcon-1.0"):Register("FroBuff", FroBuffLDB, FroBuff.db.profile.minimap)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("FroBuff", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FroBuff", "FroBuff")
    
    self:RegisterChatCommand("frobuff", "OpenOptions")
    self:RegisterChatCommand("fb", "OpenOptions")
end

function FroBuff:OpenOptions()
    LibStub("AceConfigDialog-3.0"):Open("FroBuff")
end
