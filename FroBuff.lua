local FroBuff = LibStub("AceAddon-3.0"):NewAddon("FroBuff", "AceConsole-3.0", "AceEvent-3.0")

function FroBuff:OnInitialize()
    if self.SetupOptions then
        self:SetupOptions()
    end
    self:CreateMatrixFrame()
end

function FroBuff:OnEnable()
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateBuffStatus")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateBuffStatus")
    self:RegisterEvent("UNIT_CONNECTION", "UpdateBuffStatus") -- När någon loggar in/ut
    
    -- Ticker var 2:a sekund för att kolla Range (UnitIsVisible saknar event)
    self.ticker = C_Timer.NewTicker(2, function() self:UpdateBuffStatus() end)
end

function FroBuff:OnDisable()
    if self.ticker then self.ticker:Cancel(); self.ticker = nil end
end

function FroBuff:UNIT_AURA(event, unit)
    if unit == "player" or string.match(unit, "^party%d$") then
        self:UpdateBuffStatus()
    end
end

function FroBuff:PLAYER_REGEN_DISABLED() 
    if self.matrixFrame then 
        ClearOverrideBindings(self.matrixFrame) 
    end 
end

function FroBuff:PLAYER_REGEN_ENABLED()
    self:UpdateBuffStatus()
end

function FroBuff:CreateMatrixFrame()
    self.matrixFrame = CreateFrame("Frame", "FroBuffMatrix", UIParent)
    self.matrixFrame:SetSize(36, 54) 
    
    local pos = self.db.profile.framePosition
    if pos then
        self.matrixFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        self.matrixFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    end
    self.matrixFrame:SetMovable(true)

    local btnUp = CreateFrame("Button", "FroBuffScrollUpButton", UIParent, "SecureActionButtonTemplate")
    btnUp:SetAttribute("type", "macro")
    btnUp:RegisterForClicks("AnyUp", "AnyDown")
    self.btnUp = btnUp

    local btnDown = CreateFrame("Button", "FroBuffScrollDownButton", UIParent, "SecureActionButtonTemplate")
    btnDown:SetAttribute("type", "macro")
    btnDown:RegisterForClicks("AnyUp", "AnyDown")
    self.btnDown = btnDown

    -- 1. SPELARENS KNAPP
    local playerBtn = CreateFrame("Button", "FroBuffPlayerButton", self.matrixFrame, "SecureActionButtonTemplate")
    playerBtn:SetSize(36, 36)
    playerBtn:SetPoint("TOP", self.matrixFrame, "TOP", 0, 0)
    playerBtn:SetAttribute("type1", "macro")
    playerBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    self:ApplyDragScripts(playerBtn)

    playerBtn.icon = playerBtn:CreateTexture(nil, "BACKGROUND")
    playerBtn.icon:SetAllPoints()
    playerBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    playerBtn.border = playerBtn:CreateTexture(nil, "BORDER")
    playerBtn.border:SetSize(62, 62)
    playerBtn.border:SetPoint("CENTER", 0, 0)
    playerBtn.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    playerBtn.text = playerBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerBtn.text:SetPoint("RIGHT", playerBtn, "LEFT", -10, 0)
    playerBtn.text:SetText("")

    playerBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local spell = self:GetAttribute("currentSpell")
        if self.statusReason then
            GameTooltip:SetText("Solo (" .. self.statusReason .. ")")
        elseif spell then
            GameTooltip:SetText("Solo Missing:\n|cFFFFFFFF" .. spell .. "|r")
        else
            GameTooltip:SetText("Solo buffs active!")
        end
        GameTooltip:Show()
    end)
    playerBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.playerButton = playerBtn

    -- 2. PARTY-KNAPPAR
    self.partyButtons = {}
    local units = {"party1", "party2", "party3", "party4"}
    
    for _, unit in ipairs(units) do
        local btn = CreateFrame("Button", "FroBuff_"..unit, self.matrixFrame, "SecureActionButtonTemplate")
        btn:SetSize(18, 18)
        btn:SetAttribute("type1", "macro")
        btn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
        self:ApplyDragScripts(btn)

        btn.icon = btn:CreateTexture(nil, "BACKGROUND")
        btn.icon:SetAllPoints()
        btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetSize(32, 32)
        btn.border:SetPoint("CENTER", 0, 0)
        btn.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local spell = self:GetAttribute("currentSpell")
            local name = UnitName(unit) or unit
            if self.statusReason then
                GameTooltip:SetText(name .. " (" .. self.statusReason .. ")")
            elseif spell then
                GameTooltip:SetText(name .. " saknar:\n|cFFFFFFFF" .. spell .. "|r")
            else
                GameTooltip:SetText(name .. " är buffad!")
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        btn.unit = unit
        btn:Hide()
        self.partyButtons[unit] = btn
    end
end

function FroBuff:ApplyDragScripts(btn)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        if not FroBuff.db.profile.locked then
            self:GetParent():StartMoving()
        end
    end)
    btn:SetScript("OnDragStop", function(self)
        self:GetParent():StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = self:GetParent():GetPoint()
        FroBuff.db.profile.framePosition = { point = point, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
    end)
end

function FroBuff:UpdateBuffStatus()
    if InCombatLockdown() then return end
    
    local myBuffs = self:GetMyClassBuffs()
    
    -- Uppdatera Spelaren
    local playerDead = UnitIsDeadOrGhost("player")
    if not playerDead then
        self.playerButton.statusReason = nil
        local missingPlayerBuff = self:GetFirstMissingBuff(myBuffs, "player")
        if missingPlayerBuff then
            local _, _, icon = GetSpellInfo(missingPlayerBuff)
            if icon then self.playerButton.icon:SetTexture(icon) end
            self.playerButton.icon:SetDesaturated(false)
            self.playerButton.icon:SetVertexColor(1, 1, 1)
            self.playerButton.text:SetText(missingPlayerBuff .. " ->")
            
            self.playerButton:SetAttribute("macrotext1", "/cast " .. missingPlayerBuff)
            self.playerButton:SetAttribute("currentSpell", missingPlayerBuff)

            local macroText = "/cast [@" .. "player" .. "] " .. missingPlayerBuff .. "\n"
            self.btnUp:SetAttribute("macrotext", macroText .. "/run CameraZoomIn(1.5)")
            self.btnDown:SetAttribute("macrotext", macroText .. "/run CameraZoomOut(1.5)")
            
            SetOverrideBindingClick(self.matrixFrame, true, "MOUSEWHEELUP", "FroBuffScrollUpButton")
            SetOverrideBindingClick(self.matrixFrame, true, "MOUSEWHEELDOWN", "FroBuffScrollDownButton")
        else
            self.playerButton.icon:SetDesaturated(true)
            self.playerButton.icon:SetVertexColor(1, 1, 1)
            self.playerButton.text:SetText("")
            self.playerButton:SetAttribute("macrotext1", nil)
            self.playerButton:SetAttribute("currentSpell", nil)
            self.btnUp:SetAttribute("macrotext", nil)
            self.btnDown:SetAttribute("macrotext", nil)
            ClearOverrideBindings(self.matrixFrame)
        end
    else
        self.playerButton.statusReason = "Död"
        self.playerButton.icon:SetDesaturated(true)
        self.playerButton.icon:SetVertexColor(0.5, 0.5, 0.5)
        self.playerButton.text:SetText("")
        self.playerButton:SetAttribute("macrotext1", nil)
        self.playerButton:SetAttribute("currentSpell", nil)
        self.btnUp:SetAttribute("macrotext", nil)
        self.btnDown:SetAttribute("macrotext", nil)
        ClearOverrideBindings(self.matrixFrame)
    end

    local activeUnits = {}
    for _, unit in ipairs({"party1", "party2", "party3", "party4"}) do
        if UnitExists(unit) then
            table.insert(activeUnits, unit)
        end
    end

    for _, btn in pairs(self.partyButtons) do
        btn:Hide()
    end

    local count = #activeUnits
    if count > 0 then
        local size = 18
        local spacing = 4
        local totalWidth = (count * size) + ((count - 1) * spacing)
        local startX = -totalWidth / 2 + size / 2

        for i, unit in ipairs(activeUnits) do
            local btn = self.partyButtons[unit]
            btn:ClearAllPoints()
            local xOffset = startX + (i - 1) * (size + spacing)
            btn:SetPoint("TOP", self.playerButton, "BOTTOM", xOffset, -8)

            -- Kolla tillgänglighet
            local online = UnitIsConnected(unit)
            local isDead = UnitIsDeadOrGhost(unit)
            local isVisible = UnitIsVisible(unit)
            
            if online and not isDead and isVisible then
                btn.statusReason = nil 
                local missingBuff = self:GetFirstMissingBuff(myBuffs, unit)
                
                if missingBuff then
                    local _, _, icon = GetSpellInfo(missingBuff)
                    if icon then btn.icon:SetTexture(icon) end
                    btn.icon:SetDesaturated(false)
                    btn.icon:SetVertexColor(1, 1, 1) 
                    
                    btn:SetAttribute("macrotext1", "/cast [@" .. unit .. "] " .. missingBuff)
                    btn:SetAttribute("currentSpell", missingBuff)
                else
                    btn.icon:SetDesaturated(true)
                    btn.icon:SetVertexColor(1, 1, 1)
                    btn:SetAttribute("macrotext1", nil)
                    btn:SetAttribute("currentSpell", nil)
                end
            else
                -- Inaktiverad (Offline/Död/Utom räckhåll)
                if not online then
                    btn.statusReason = "Offline"
                elseif isDead then
                    btn.statusReason = "Död"
                elseif not isVisible then
                    btn.statusReason = "Utom räckhåll"
                end
                
                btn.icon:SetDesaturated(true)
                btn.icon:SetVertexColor(0.4, 0.4, 0.4) -- Mörkgrå
                btn:SetAttribute("macrotext1", nil)
                btn:SetAttribute("currentSpell", nil)
            end
            btn:Show()
        end
    end
end
