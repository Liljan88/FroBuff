local FroBuff = LibStub("AceAddon-3.0"):NewAddon("FroBuff", "AceConsole-3.0", "AceEvent-3.0")

FroBuff.buttons = {} -- Tabell för att spara våra 5 knappar

function FroBuff:OnInitialize()
    if self.SetupOptions then
        self:SetupOptions()
    end
    self:CreateMatrixFrame()
end

function FroBuff:OnEnable()
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateBuffStatus")
    -- NY: Lyssna på när folk går med i eller lämnar din grupp!
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateBuffStatus")
end

function FroBuff:UNIT_AURA(event, unit)
    -- Vi bryr oss bara om det är du eller någon i din grupp som fick/tappade en buff
    if unit == "player" or string.match(unit, "^party%d$") then
        self:UpdateBuffStatus()
    end
end

function FroBuff:PLAYER_REGEN_ENABLED()
    self:UpdateBuffStatus()
end

function FroBuff:CreateMatrixFrame()
    -- Skapa behållaren
    self.matrixFrame = CreateFrame("Frame", "FroBuffMatrix", UIParent)
    self.matrixFrame:SetSize(36, 36)
    
    local pos = self.db.profile.framePosition
    if pos then
        self.matrixFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        self.matrixFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    end
    self.matrixFrame:SetMovable(true)

    -- Skapa de 5 enhets-knapparna (Dig själv + max 4 partymedlemmar)
    local units = {"player", "party1", "party2", "party3", "party4"}
    
    for i, unit in ipairs(units) do
        local btn = CreateFrame("Button", "FroBuffButton"..i, self.matrixFrame, "SecureActionButtonTemplate")
        btn:SetSize(36, 36)
        
        if i == 1 then
            -- Spelarens knapp fästs i toppen av matrix-behållaren
            btn:SetPoint("TOPLEFT", self.matrixFrame, "TOPLEFT", 0, 0)
        else
            -- Partymedlemmars knappar fästs precis under föregående knapp
            btn:SetPoint("TOP", self.buttons[i-1], "BOTTOM", 0, -5)
        end
        
        btn:SetAttribute("type1", "macro")
        btn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")

        -- Eftersom ActionButtons blockerar mus-klick, sätter vi Drag-funktionen på knapparna 
        -- men säger åt koden att flytta HUVUDRAMEN (matrixFrame)
        btn:RegisterForDrag("LeftButton")
        btn:SetScript("OnDragStart", function(self)
            if not FroBuff.db.profile.locked then
                self:GetParent():StartMoving()
            end
        end)
        btn:SetScript("OnDragStop", function(self)
            self:GetParent():StopMovingOrSizing()
            local point, relativeTo, relativePoint, xOfs, yOfs = self:GetParent():GetPoint()
            FroBuff.db.profile.framePosition = { point = point, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
        end)

        btn.icon = btn:CreateTexture(nil, "BACKGROUND")
        btn.icon:SetAllPoints()
        btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetSize(62, 62)
        btn.border:SetPoint("CENTER", 0, 0)
        btn.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("RIGHT", btn, "LEFT", -10, 0)
        btn.text:SetText("")

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local spell = self:GetAttribute("currentSpell")
            local unitName = UnitName(unit) or "Okänd"
            if spell then
                GameTooltip:SetText(unitName .. " saknar:\n|cFFFFFFFF" .. spell .. "|r")
            else
                GameTooltip:SetText(unitName .. " är fullbuffad!")
            end
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        btn.unit = unit -- Spara vilken enhet knappen övervakar (t.ex. "party2")
        self.buttons[i] = btn
    end
end

function FroBuff:UpdateBuffStatus()
    if InCombatLockdown() then return end
    
    local myBuffs = self:GetMyClassBuffs()
    
    for i, btn in ipairs(self.buttons) do
        local unit = btn.unit
        
        -- Finns enheten? (Är du solo finns t.ex. inte 'party1')
        if UnitExists(unit) then
            btn:Show() -- Visa knappen om personen existerar
            
            local missingBuff = self:GetFirstMissingBuff(myBuffs, unit)
            
            if missingBuff then
                local spellName, _, spellIcon = GetSpellInfo(missingBuff)
                if spellIcon then
                    btn.icon:SetTexture(spellIcon)
                    btn.icon:SetDesaturated(false)
                end

                local name = UnitName(unit) or "Okänd"
                btn.text:SetText(name .. " ->")
                
                -- Här sätter vi målet för magin dynamiskt: /cast [@party1] Arcane Intellect
                btn:SetAttribute("macrotext1", "/cast [@" .. unit .. "] " .. missingBuff)
                btn:SetAttribute("currentSpell", missingBuff)
            else
                btn.icon:SetDesaturated(true)
                btn.text:SetText("") 
                btn:SetAttribute("macrotext1", nil)
                btn:SetAttribute("currentSpell", nil)
            end
        else
            btn:Hide() -- Göm knappen om platsen i gruppen är tom
        end
    end
end
