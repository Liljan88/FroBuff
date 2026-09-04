local FroBuff = LibStub("AceAddon-3.0"):NewAddon("FroBuff", "AceConsole-3.0", "AceEvent-3.0")

function FroBuff:OnInitialize()
    if self.SetupOptions then self:SetupOptions() end
    self:CreateMatrixFrame()
end

function FroBuff:OnEnable()
    self:RegisterEvent("UNIT_AURA", "UpdateBuffStatus")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateBuffStatus")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateBuffStatus")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateBuffStatus")
    self:RegisterEvent("UNIT_CONNECTION", "UpdateBuffStatus")
    self.ticker = C_Timer.NewTicker(2, function() self:UpdateBuffStatus() end)
end

function FroBuff:OnDisable() if self.ticker then self.ticker:Cancel(); self.ticker = nil end end

function FroBuff:PLAYER_REGEN_DISABLED() 
    if self.matrixFrame then ClearOverrideBindings(self.matrixFrame) end 
end

function FroBuff:CreateMatrixFrame()
    self.matrixFrame = CreateFrame("Frame", "FroBuffMatrix", UIParent)
    self.matrixFrame:SetSize(36, 54) 
    
    local pos = self.db.profile.framePosition
    if pos then self.matrixFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else self.matrixFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100) end
    self.matrixFrame:SetMovable(true)

    -- SCROLL KNAPPAR
    self.btnUp = CreateFrame("Button", "FroBuffScrollUpButton", UIParent, "SecureActionButtonTemplate")
    self.btnUp:SetAttribute("type", "macro")
    self.btnUp:RegisterForClicks("AnyUp", "AnyDown")

    self.btnDown = CreateFrame("Button", "FroBuffScrollDownButton", UIParent, "SecureActionButtonTemplate")
    self.btnDown:SetAttribute("type", "macro")
    self.btnDown:RegisterForClicks("AnyUp", "AnyDown")

    -- 1. SPELARENS KNAPP
    self.playerButton = self:CreateBaseButton("FroBuffPlayerButton", 36, self.matrixFrame, "TOP", 0, 0)
    self.playerButton:SetAttribute("type1", "macro")
    
    -- 2. GRUPP BUFF KNAPP
    self.groupButton = self:CreateBaseButton("FroBuffGroupButton", 24, self.matrixFrame, "LEFT", 12, 0)
    self.groupButton:SetPoint("LEFT", self.playerButton, "RIGHT", 8, 0)
    self.groupButton:SetAttribute("type1", "macro")
    self.groupButton.border:SetVertexColor(1, 0.8, 0)

    -- 3. PARTY SATELLITER
    self.partyButtons = {}
    for _, unit in ipairs({"party1", "party2", "party3", "party4"}) do
        local btn = self:CreateBaseButton("FroBuff_"..unit, 18, self.matrixFrame, "CENTER", 0, 0)
        btn:SetAttribute("type1", "spell") 
        btn.unit = unit
        btn:Hide()
        self.partyButtons[unit] = btn
    end
end

function FroBuff:CreateBaseButton(name, size, parent, anchor, x, y)
    local btn = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    btn:SetSize(size, size)
    if anchor then btn:SetPoint(anchor, parent, anchor, x, y) end
    btn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")

    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function() if not FroBuff.db.profile.locked then parent:StartMoving() end end)
    btn:SetScript("OnDragStop", function()
        parent:StopMovingOrSizing()
        local p, _, rp, xo, yo = parent:GetPoint()
        FroBuff.db.profile.framePosition = { point = p, relativePoint = rp, xOfs = xo, yOfs = yo }
    end)

    btn.icon = btn:CreateTexture(nil, "BACKGROUND")
    btn.icon:SetAllPoints()
    
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetSize(size * 1.6, size * 1.6)
    btn.border:SetPoint("CENTER", 0, 0)
    btn.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("RIGHT", btn, "LEFT", -10, 0)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.tooltipText then GameTooltip:SetText(self.tooltipText) end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return btn
end

function FroBuff:UpdateBuffStatus()
    if InCombatLockdown() then return end
    
    local myBuffs = self:GetMyClassBuffs()
    
    local playerDead = UnitIsDeadOrGhost("player")
    if not playerDead then
        local missingPlayerBuff = self:GetFirstMissingBuff(myBuffs, "player")
        if missingPlayerBuff then
            local _, _, icon = GetSpellInfo(missingPlayerBuff)
            if icon then self.playerButton.icon:SetTexture(icon) end
            self.playerButton.icon:SetDesaturated(false)
            self.playerButton.icon:SetVertexColor(1, 1, 1)
            self.playerButton.text:SetText(missingPlayerBuff .. " ->")
            self.playerButton.tooltipText = "Solo Missing:\n|cFFFFFFFF" .. missingPlayerBuff .. "|r"
            
            -- Tyst makro för GCD (baserat på din FroCore-version)
            local macroText = "/console Sound_EnableErrorSpeech 0\n"
            macroText = macroText .. "/cast [@" .. "player" .. "] " .. missingPlayerBuff .. "\n"
            macroText = macroText .. "/console Sound_EnableErrorSpeech 1\n/run UIErrorsFrame:Clear()\n"
            
            self.playerButton:SetAttribute("macrotext1", macroText)
            
            self.btnUp:SetAttribute("macrotext", macroText .. "/run CameraZoomIn(1.5)")
            self.btnDown:SetAttribute("macrotext", macroText .. "/run CameraZoomOut(1.5)")
            
            SetOverrideBindingClick(self.matrixFrame, true, "MOUSEWHEELUP", "FroBuffScrollUpButton")
            SetOverrideBindingClick(self.matrixFrame, true, "MOUSEWHEELDOWN", "FroBuffScrollDownButton")
        else
            self.playerButton.icon:SetDesaturated(true)
            self.playerButton.text:SetText("")
            self.playerButton.tooltipText = "Solo buffs active!"
            self.playerButton:SetAttribute("macrotext1", nil)
            self.btnUp:SetAttribute("macrotext", nil)
            self.btnDown:SetAttribute("macrotext", nil)
            ClearOverrideBindings(self.matrixFrame)
        end
    end

    local neededGroupBuff, missCount = self:GetNeededGroupBuff(myBuffs)
    if neededGroupBuff then
        local _, _, icon = GetSpellInfo(neededGroupBuff)
        if icon then self.groupButton.icon:SetTexture(icon) end
        self.groupButton.icon:SetDesaturated(false)
        self.groupButton.tooltipText = "|cFFFFFF00Grupp Buff!|r\n" .. missCount .. " spelare saknar buffen.\nKlicka för att kasta:\n|cFFFFFFFF" .. neededGroupBuff .. "|r"
        self.groupButton:SetAttribute("macrotext1", "/cast " .. neededGroupBuff)
        self.groupButton:Show()
    else
        self.groupButton:Hide()
        self.groupButton:SetAttribute("macrotext1", nil)
    end

    local activeUnits = {}
    for i=1, 4 do if UnitExists("party"..i) then table.insert(activeUnits, "party"..i) end end

    for _, btn in pairs(self.partyButtons) do btn:Hide() end

    local count = #activeUnits
    if count > 0 then
        local size = 18
        local spacing = 4
        local totalWidth = (count * size) + ((count - 1) * spacing)
        local startX = -totalWidth / 2 + size / 2

        for i, unit in ipairs(activeUnits) do
            local btn = self.partyButtons[unit]
            btn:ClearAllPoints()
            btn:SetPoint("TOP", self.playerButton, "BOTTOM", startX + (i - 1) * (size + spacing), -8)

            local online, isDead, isVisible = UnitIsConnected(unit), UnitIsDeadOrGhost(unit), UnitIsVisible(unit)
            
            if online and not isDead and isVisible then
                local missingBuff = self:GetFirstMissingBuff(myBuffs, unit)
                if missingBuff then
                    local _, _, icon = GetSpellInfo(missingBuff)
                    if icon then btn.icon:SetTexture(icon) end
                    btn.icon:SetDesaturated(false)
                    btn.icon:SetVertexColor(1, 1, 1) 
                    btn.tooltipText = (UnitName(unit) or unit) .. " saknar:\n|cFFFFFFFF" .. missingBuff .. "|r"
                    
                    btn:SetAttribute("spell", missingBuff)
                    btn:SetAttribute("unit", unit)
                else
                    btn.icon:SetDesaturated(true)
                    btn.icon:SetVertexColor(1, 1, 1)
                    btn.tooltipText = (UnitName(unit) or unit) .. " är fullbuffad."
                    btn:SetAttribute("spell", nil)
                    btn:SetAttribute("unit", nil)
                end
            else
                local reason = not online and "Offline" or (isDead and "Död" or "Utom räckhåll")
                btn.icon:SetDesaturated(true)
                btn.icon:SetVertexColor(0.4, 0.4, 0.4)
                btn.tooltipText = (UnitName(unit) or unit) .. " (" .. reason .. ")"
                btn:SetAttribute("spell", nil)
                btn:SetAttribute("unit", nil)
            end
            btn:Show()
        end
    end
end
