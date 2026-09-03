local FroBuff = LibStub("AceAddon-3.0"):GetAddon("FroBuff")

local BUTTON_SIZE = 24
local INDICATOR_SIZE = 12
local SPACING = 2
local MISSING_COLOR = { r = 17/255, g = 17/255, b = 17/255, a = 1.0 }

FroBuff.groupButtons = {}

function FroBuff:OnInitialize()
    self:SetupOptions()
    self:CreateMatrix()
end

function FroBuff:OnEnable()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateRoster")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateRoster")
    self:RegisterEvent("UNIT_AURA", "UpdateAuras")
end

function FroBuff:CreateMatrix()
    local frame = CreateFrame("Frame", "FroBuffCore", UIParent)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    frame:SetSize(BUTTON_SIZE * 5 + SPACING * 4, BUTTON_SIZE * 8 + SPACING * 7)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    self.frame = frame

    for g = 1, 8 do
        self.groupButtons[g] = {}
        for p = 1, 5 do
            local btn = CreateFrame("Button", "FroBuff_G" .. g .. "P" .. p, frame, "SecureActionButtonTemplate, BackdropTemplate")
            btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
            btn:RegisterForClicks("AnyUp")
            
            btn.bg = btn:CreateTexture(nil, "BACKGROUND")
            btn.bg:SetAllPoints()
            btn.bg:SetColorTexture(0.3, 0.3, 0.3, 1)

            btn.indicator = btn:CreateTexture(nil, "OVERLAY")
            btn.indicator:SetSize(12, 12)
            btn.indicator:SetColorTexture(0.07, 0.07, 0.07, 1)
            btn.indicator:ClearAllPoints()
            btn.indicator:SetPoint("CENTER", btn, "CENTER", 0, 0)
            btn.indicator:Show()

            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetUnit(self.unit)
                if self.missingBuff then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(self.missingBuff, 1, 0, 0)
                end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            local yOffset = -((g - 1) * (BUTTON_SIZE + SPACING))
            local xOffset = (p - 1) * (BUTTON_SIZE + SPACING)
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
            btn:Hide()
            
            self.groupButtons[g][p] = btn
        end
    end
end

function FroBuff:UpdateRoster()
    local isRaid = IsInRaid()
    local isGroup = IsInGroup()
    local numMembers = GetNumGroupMembers()

    for g = 1, 8 do
        for p = 1, 5 do
            self.groupButtons[g][p]:Hide()
        end
    end

    if not isGroup then
        local btn = self.groupButtons[1][1]
        btn.unit = "player"
        btn:SetAttribute("unit", "player")
        local _, classFileName = UnitClass("player")
        if classFileName and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFileName] then
            local c = RAID_CLASS_COLORS[classFileName]
            btn.bg:SetColorTexture(c.r, c.g, c.b, 1)
        end
        btn:Show()
    else
        for i = 1, numMembers do
            local unit = isRaid and ("raid" .. i) or (i == numMembers and "player" or "party" .. i)
            local name, _, subgroup, _, _, classFileName = GetRaidRosterInfo(i)
            
            if not isRaid then subgroup = 1 end

            if name and subgroup and subgroup <= 8 then
                for p = 1, 5 do
                    local btn = self.groupButtons[subgroup][p]
                    if not btn:IsShown() then
                        btn.unit = unit
                        btn:SetAttribute("unit", unit)
                        
                        if classFileName and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFileName] then
                            local color = RAID_CLASS_COLORS[classFileName]
                            btn.bg:SetColorTexture(color.r, color.g, color.b, 1)
                        end
                        
                        btn:Show()
                        break
                    end
                end
            end
        end
    end
    self:UpdateAuras()
end

function FroBuff:UpdateAuras()
    local allGood = true

    for g = 1, 8 do
        for p = 1, 5 do
            local btn = self.groupButtons[g][p]
            if btn:IsShown() and btn.unit then
                local missing = self:GetMissingPriorityBuff(btn.unit)
                if missing then
                    btn.missingBuff = missing
                    btn.indicator:Show()
                    allGood = false
                else
                    btn.missingBuff = nil
                    btn.indicator:Hide()
                end
            end
        end
    end

    if self.frame then
        if not IsInGroup() and allGood then
            self.frame:SetAlpha(0)
        else
            self.frame:SetAlpha(1)
        end
    end
end
