local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff")

-- Dynamiska val för menyer (kan flyttas till Data.lua senare om det blir mycket)
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
    childGroups = "tab", -- Skapar flikar i toppen av menyn!
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
            },
        },
        -- FLIK 2: SOLO
        solo = {
            type = "group",
            name = "Solo",
            order = 2,
            args = {
                description = {
                    type = "description",
                    name = "Här ställer du in vilka buffs addonet ska prioritera när du spelar solo.\n",
                    order = 1,
                },
                mageArmor = {
                    type = "select",
                    name = "Föredragen Armor (Mage)",
                    desc = "Välj vilken rustning du vill att knappen ska rekommendera.",
                    order = 2,
                    values = GetMageArmorOptions(),
                    get = function(info) return FroBuff.db.profile.solo.mageArmor end,
                    set = function(info, value)
                        FroBuff.db.profile.solo.mageArmor = value
                        -- Uppdaterar knappen direkt om rutan är synlig
                        if FroBuff.UpdateBuffStatus then
                            FroBuff:UpdateBuffStatus()
                        end
                    end,
                    hidden = function()
                        -- Dölj denna inställning om spelaren inte är en Mage!
                        local _, class = UnitClass("player")
                        return class ~= "MAGE"
                    end,
                },
            },
        },
        -- FLIK 3: PARTY & RAID (Framtidssäkrad)
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
    -- Registrera databasen och sätt in standardvärden för den nya strukturen
    FroBuff.db = LibStub("AceDB-3.0"):New("FroBuffDB", {
        profile = {
            minimap = { hide = false },
            locked = true,
            framePosition = nil,
            solo = {
                mageArmor = "Ice Armor", -- Standardvalet första gången man loggar in
            }
        },
    })

    -- Minimap Ikon (LDB)
    local FroBuffLDB = LibStub("LibDataBroker-1.1"):NewDataObject("FroBuff", {
        type = "launcher",
        text = "FroBuff",
        icon = "Interface\\Icons\\INV_Alchemy_EnchantedVial",
        OnClick = function(_, button)
            if button == "LeftButton" then
                LibStub("AceConfigDialog-3.0"):Open("FroBuff")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("FroBuff", 1, 0.82, 0)
            tooltip:AddLine("Vänsterklicka för inställningar.")
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
