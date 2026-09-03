local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff")

local options = {
    name = "FroBuff",
    handler = FroBuff,
    type = "group",
    args = {
        general = {
            type = "group",
            name = "Allmänt",
            inline = true,
            args = {
                toggleMinimap = {
                    type = "toggle",
                    name = "Visa Minimap Ikon",
                    desc = "Slår av och på FroBuffs ikon vid minimappen.",
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
            },
        },
        advanced = {
            type = "group",
            name = "Avancerat (Dold)",
            desc = "Här kommer avancerade inställningar finnas för de som vill finjustera.",
            args = {
                -- Fylls på senare
            }
        }
    },
}

function FroBuff:SetupOptions()
    -- Registrera DB först så FroBuff.db finns tillgänglig
    FroBuff.db = LibStub("AceDB-3.0"):New("FroBuffDB", {
        profile = {
            minimap = {
                hide = false,
            },
        },
    })

    -- LDB för Minimap Ikon med angiven ikon
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
    
    -- Registrera Minimap
    LibStub("LibDBIcon-1.0"):Register("FroBuff", FroBuffLDB, FroBuff.db.profile.minimap)

    -- Registrera Config
    LibStub("AceConfig-3.0"):RegisterOptionsTable("FroBuff", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FroBuff", "FroBuff")
    
    -- Slash command
    self:RegisterChatCommand("frobuff", "OpenOptions")
    self:RegisterChatCommand("fb", "OpenOptions")
end

function FroBuff:OpenOptions()
    LibStub("AceConfigDialog-3.0"):Open("FroBuff")
end