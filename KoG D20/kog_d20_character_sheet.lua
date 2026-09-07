-- Ensure the character sheet tables exist to prevent nil errors
v_kog_character_sheet = v_kog_character_sheet or {}
v_kog_character_sheet.skills = v_kog_character_sheet.skills or {}

-- ==========================================
-- 1. MAIN CONTAINER FRAME
-- ==========================================
v_kog_character_frame = CreateFrame("Frame", "kog_d20_character_sheet", UIParent, "BasicFrameTemplateWithInset")
v_kog_character_frame:SetSize(250, 325)
v_kog_character_frame:SetPoint("CENTER")

-- Layering & Stacking Management
v_kog_character_frame:SetToplevel(true)
v_kog_character_frame:SetFrameStrata("MEDIUM")
v_kog_character_frame:SetFrameLevel(30) -- Higher base level than modifier frame

-- Frame Interactivity & Dragging
v_kog_character_frame:SetMovable(true)
v_kog_character_frame:EnableMouse(true)
v_kog_character_frame:RegisterForDrag("LeftButton")
v_kog_character_frame:SetScript("OnDragStart", v_kog_character_frame.StartMoving)
v_kog_character_frame:SetScript("OnDragStop", v_kog_character_frame.StopMovingOrSizing)
v_kog_character_frame:SetScript("OnMouseDown", function(self)
    self:Raise()
end)

-- Frame Title
v_kog_character_frame.title = v_kog_character_frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
v_kog_character_frame.title:SetPoint("CENTER", v_kog_character_frame.TitleBg, "CENTER", 0, 0)
v_kog_character_frame.title:SetText("KoG D20 - v"..C_AddOns.GetAddOnMetadata("KoG_D20", "Version"))

-- Close Logic
v_kog_character_frame:SetScript("OnHide", function(self)
    v_kog_character_sheet.character_frame_visible = false    
end)

-- ==========================================
-- 2. VIEW SUB-CONTAINERS (FULL VS COMPACT)
-- ==========================================
v_kog_full_view = CreateFrame("Frame", nil, v_kog_character_frame)
v_kog_full_view:SetAllPoints(v_kog_character_frame)

v_kog_compact_view = CreateFrame("Frame", nil, v_kog_character_frame)
v_kog_compact_view:SetAllPoints(v_kog_character_frame)
v_kog_compact_view:Hide() -- Hidden by default

-- Toggle Button (Placed next to close button in title bar)
v_kog_compact_toggle_button = CreateFrame("Button", nil, v_kog_character_frame, "UIPanelButtonTemplate")
v_kog_compact_toggle_button:SetSize(20, 18)
v_kog_compact_toggle_button:SetPoint("TOPRIGHT", v_kog_character_frame, "TOPRIGHT", -26, -3)
v_kog_compact_toggle_button:SetText("_")

local function SetViewMode(isCompact)
    --v_kog_character_sheet.compact_mode = isCompact
    if isCompact then
        v_kog_full_view:Hide()
        v_kog_compact_view:Show()
        v_kog_character_frame:SetSize(250, 155) -- Expanded height to comfortably accommodate controls and results without overlapping
        v_kog_compact_toggle_button:SetText("+")
        v_kog_character_sheet.compact_mode = true
    else
        v_kog_compact_view:Hide()
        v_kog_full_view:Show()
        v_kog_character_frame:SetSize(250, 325)
        v_kog_compact_toggle_button:SetText("-")
        v_kog_character_sheet.compact_mode = false
    end
end

v_kog_compact_toggle_button:SetScript("OnClick", function()
    SetViewMode(not v_kog_character_sheet.compact_mode)
end)


-- ==========================================
-- 3. PLAYSTYLE DATA MAPPING & UPDATE LOGIC
-- ==========================================

local function UpdateRowTotal(editBox, psLabel, totalLabel)
    if not editBox or not psLabel or not totalLabel then return end
    local skillVal = tonumber(editBox:GetText()) or 0
    local playstyleVal = tonumber(psLabel:GetText()) or 0
    totalLabel:SetText(skillVal + playstyleVal)

    if kog_roll_recalculate then
        kog_roll_recalculate()
    end
end

function UpdateAllRowTotals()
    UpdateRowTotal(v_kog_character_frame.physAttkMod, v_kog_character_frame.psLabelPhys, v_kog_character_frame.totalLabelPhys)
    UpdateRowTotal(v_kog_character_frame.defenseMod, v_kog_character_frame.psLabelDef, v_kog_character_frame.totalLabelDef)
    UpdateRowTotal(v_kog_character_frame.healSuppMod, v_kog_character_frame.psLabelHeal, v_kog_character_frame.totalLabelHeal)
    UpdateRowTotal(v_kog_character_frame.magicAttkMod, v_kog_character_frame.psLabelMagic, v_kog_character_frame.totalLabelMagic)
    UpdateRowTotal(v_kog_character_frame.stealthMod, v_kog_character_frame.psLabelStealth, v_kog_character_frame.totalLabelStealth)
end

local function UpdatePlaystyleLabels(playstyle)
    local dataKey = playstyleMap[playstyle] or "combatant"
    v_kog_character_sheet.playstyle = playstyleMap[playstyle]

    if not v_kog_combat_playstyle then return end 
    
    local stats = v_kog_combat_playstyle[dataKey]
    
    if v_kog_character_frame.psLabelPhys and stats then
        v_kog_character_frame.psLabelPhys:SetText(stats.physical_attack)
        v_kog_character_frame.psLabelDef:SetText(stats.defense)
        v_kog_character_frame.psLabelHeal:SetText(stats.healing_support)
        v_kog_character_frame.psLabelMagic:SetText(stats.magic_attack)
        v_kog_character_frame.psLabelStealth:SetText(stats.stealth)
        
        UpdateAllRowTotals()
    end
end


-- ==========================================
-- 4. HELPER FUNCTIONS
-- ==========================================

-- Forward declaration of synchronization function
local SelectSkillByName

local function CreateDropdown(name, parent, width, options, defaultText, xOffset, yOffset)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOP", parent, "TOP", xOffset or 0, yOffset)
    dropdown:SetFrameLevel(parent:GetFrameLevel() + 5)
    UIDropDownMenu_SetWidth(dropdown, width)
    UIDropDownMenu_SetText(dropdown, defaultText)

    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for _, option in ipairs(options) do
            info.text = option
            info.arg1 = option
            info.checked = (UIDropDownMenu_GetText(dropdown) == option)
            info.func = function(self, arg1)
                UIDropDownMenu_SetText(dropdown, arg1)
                CloseDropDownMenus()
                
                if name == "PlaystyleDropdown" then 
                    v_kog_character_sheet.playstyle = arg1
                    UpdatePlaystyleLabels(arg1)
                elseif name == "HPDropdown" then 
                    v_kog_character_sheet.base_hp = arg1
                elseif name == "BLPDropdown" then 
                    v_kog_character_sheet.bad_luck_protection = arg1 
                    if arg1 ~= "Combat Focus" then
                        v_kog_character_sheet.combat_focus_stacks = 0
                    end
                elseif name == "SkillDropdownCompact" then
                    SelectSkillByName(arg1)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    return dropdown
end

radioGroup = {}

local function CreateField(parent, labelText, x, y)
    local radioButton = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    radioButton:SetSize(16, 16)
    radioButton:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 25, y - 2)
    radioButton.skillName = labelText
    table.insert(radioGroup, radioButton)

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetText(labelText)
    label:SetSize(80, 20) 
    label:SetJustifyH("RIGHT") 
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    -- Independent Colon Field placed directly next to the label string
    local colonLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colonLabel:SetText(":")
    colonLabel:SetPoint("LEFT", label, "RIGHT", 1, 0)

    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(35, 20)
    editBox:SetPoint("LEFT", colonLabel, "RIGHT", 10, 0) 
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)

    local playstyleLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playstyleLabel:SetText("0")
    playstyleLabel:SetPoint("LEFT", editBox, "RIGHT", 15, 0)
    
    local totalLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    totalLabel:SetText("0")
    totalLabel:SetPoint("LEFT", playstyleLabel, "RIGHT", 25, 0)
    
    radioButton:SetScript("OnClick", function(self)
        SelectSkillByName(self.skillName)
    end)
    
    return editBox, label, playstyleLabel, totalLabel, radioButton, colonLabel
end


-- ==========================================
-- 5. FULL VIEW LAYOUT
-- ==========================================

-- Dropdowns Row 1: Playstyle & HP
local playstyles = {"Combatant", "Ravager", "Mender", "Guardian", "Berserker", "Bulwark", "Juggernaut", "Glass Cannon", "Assassin/Sniper", "Battlefield Chirurgeon"}
v_kog_character_frame.playstyleDrop = CreateDropdown("PlaystyleDropdown", v_kog_full_view, 95, playstyles, "Combatant", -45, -35)

local hpOptions = {"8", "10", "12"}
v_kog_character_frame.hpDrop = CreateDropdown("HPDropdown", v_kog_full_view, 45, hpOptions, "10", 65, -35)

-- Dropdowns Row 2: BLP & Roll Button
local blpOptions = {"Combat Focus", "Counter", "Re-roll"}
v_kog_character_frame.blpDrop = CreateDropdown("BLPDropdown", v_kog_full_view, 95, blpOptions, "Re-roll", -45, -65)

local rollButtonFull = CreateFrame("Button", nil, v_kog_full_view, "UIPanelButtonTemplate")
rollButtonFull:SetSize(55, 22)
rollButtonFull:SetPoint("LEFT", v_kog_character_frame.blpDrop, "RIGHT", 15, 3)
rollButtonFull:SetText("Roll")
rollButtonFull:SetScript("OnClick", function()
    RandomRoll(1, 20)
end)

-- Column Headers
local playstyleColumnHeader = v_kog_full_view:CreateFontString(nil, "OVERLAY", "GameFontNormal")
playstyleColumnHeader:SetText("P") 
playstyleColumnHeader:SetPoint("TOPLEFT", v_kog_full_view, "TOPLEFT", 185, -95)

local totalColumnHeader = v_kog_full_view:CreateFontString(nil, "OVERLAY", "GameFontNormal")
totalColumnHeader:SetText("Total") 
totalColumnHeader:SetPoint("TOPLEFT", v_kog_full_view, "TOPLEFT", 210, -95)

-- Stat Modifier Fields
v_kog_character_frame.physAttkMod, _, v_kog_character_frame.psLabelPhys, v_kog_character_frame.totalLabelPhys, v_kog_character_frame.radioPhys = CreateField(v_kog_full_view, "Phys Attk", 40, -115)
v_kog_character_frame.defenseMod, _, v_kog_character_frame.psLabelDef, v_kog_character_frame.totalLabelDef, v_kog_character_frame.radioDef = CreateField(v_kog_full_view, "Defense", 40, -139)
v_kog_character_frame.healSuppMod, _, v_kog_character_frame.psLabelHeal, v_kog_character_frame.totalLabelHeal, v_kog_character_frame.radioHeal = CreateField(v_kog_full_view, "Heal/Supp", 40, -163)
v_kog_character_frame.magicAttkMod, _, v_kog_character_frame.psLabelMagic, v_kog_character_frame.totalLabelMagic, v_kog_character_frame.radioMagic = CreateField(v_kog_full_view, "Magic Attk", 40, -187)
v_kog_character_frame.stealthMod, _, v_kog_character_frame.psLabelStealth, v_kog_character_frame.totalLabelStealth, v_kog_character_frame.radioStealth = CreateField(v_kog_full_view, "Stealth", 40, -211)


-- ==========================================
-- 6. COMPACT VIEW LAYOUT & DROPDOWN/ROLL BUTTON
-- ==========================================

local skillOptions = {"Phys Attk", "Defense", "Heal/Supp", "Magic Attk", "Stealth"}
v_kog_character_frame.skillDropCompact = CreateDropdown("SkillDropdownCompact", v_kog_compact_view, 105, skillOptions, "Phys Attk", -35, -33)

local rollButtonCompact = CreateFrame("Button", nil, v_kog_compact_view, "UIPanelButtonTemplate")
rollButtonCompact:SetSize(55, 22)
rollButtonCompact:SetPoint("LEFT", v_kog_character_frame.skillDropCompact, "RIGHT", 5, 3)
rollButtonCompact:SetText("Roll")
rollButtonCompact:SetScript("OnClick", function()
    RandomRoll(1, 20)
end)


-- ==========================================
-- 7. SHARED ROLL & RESULT DISPLAY FIELDS
-- ==========================================

local function CreateSyncedRollField(parentFull, parentCompact, defaultText, modifyingField, xPosFull, yPosFull, xPosCompact, yPosCompact, anchorFull, anchorCompact, fontObject, titleText)
    -- Full Frame Creation
    local frameFull = CreateFrame("Frame", nil, parentFull)
    frameFull:SetSize(45, 20)
    if anchorFull then
        frameFull:SetPoint("LEFT", anchorFull, "RIGHT", 5, 0)
    else
        frameFull:SetPoint("TOPLEFT", parentFull, "TOPLEFT", xPosFull, yPosFull)
    end
    local labelFull = frameFull:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlight")
    labelFull:SetAllPoints(frameFull)
    labelFull:SetText(defaultText)
    labelFull:SetJustifyH("CENTER")
    
    if titleText then
        local tFull = parentFull:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tFull:SetPoint("BOTTOM", frameFull, "TOP", 0, 2)
        tFull:SetText(titleText)
    end

    -- Compact Frame Creation
    local frameCompact = CreateFrame("Frame", nil, parentCompact)
    frameCompact:SetSize(45, 20)
    if anchorCompact then
        frameCompact:SetPoint("LEFT", anchorCompact, "RIGHT", 5, 0)
    else
        frameCompact:SetPoint("TOPLEFT", parentCompact, "TOPLEFT", xPosCompact, yPosCompact)
    end
    local labelCompact = frameCompact:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlight")
    labelCompact:SetAllPoints(frameCompact)
    labelCompact:SetText(defaultText)
    labelCompact:SetJustifyH("CENTER")
    
    if titleText then
        local tCompact = parentCompact:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tCompact:SetPoint("BOTTOM", frameCompact, "TOP", 0, 2)
        tCompact:SetText(titleText)
    end

    -- Tooltips
    local function setupTooltip(f)
        f:EnableMouse(true)
        f:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("" .. modifyingField, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    setupTooltip(frameFull)
    setupTooltip(frameCompact)

    -- Dual-updating proxy wrapper
    local proxy = {
        SetText = function(self, text)
            labelFull:SetText(text)
            labelCompact:SetText(text)
        end,
        GetText = function(self)
            return labelFull:GetText()
        end
    }
    return frameFull, frameCompact, proxy
end

local function CreateSyncedResultField(parentFull, parentCompact, labelText, tooltipText, xPosFull, yPosFull, xPosCompact, yPosCompact, width)
    -- Full View Result
    local frameFull = CreateFrame("Frame", nil, parentFull)
    frameFull:SetSize(width, 20)
    frameFull:SetPoint("TOPLEFT", parentFull, "TOPLEFT", xPosFull, yPosFull)
    local lblFull = frameFull:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblFull:SetPoint("LEFT", frameFull, "LEFT", 0, 0)
    lblFull:SetText(labelText)
    local resFull = frameFull:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    resFull:SetPoint("LEFT", lblFull, "RIGHT", 5, 0)
    resFull:SetText("-")

    -- Compact View Result
    local frameCompact = CreateFrame("Frame", nil, parentCompact)
    frameCompact:SetSize(width, 20)
    frameCompact:SetPoint("TOPLEFT", parentCompact, "TOPLEFT", xPosCompact, yPosCompact)
    local lblCompact = frameCompact:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblCompact:SetPoint("LEFT", frameCompact, "LEFT", 0, 0)
    lblCompact:SetText(labelText)
    local resCompact = frameCompact:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    resCompact:SetPoint("LEFT", lblCompact, "RIGHT", 5, 0)
    resCompact:SetText("-")

    local function setupTooltip(f)
        f:EnableMouse(true)
        f:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    setupTooltip(frameFull)
    setupTooltip(frameCompact)

    -- Dual-updating proxy wrapper
    local proxy = {
        SetText = function(self, text)
            resFull:SetText(text)
            resCompact:SetText(text)
        end,
        GetText = function(self)
            return labelFull:GetText()
        end
    }
    return proxy
end

-- Create synced elements (adjusted compact Y-offsets to prevent overlap)
local attackFull, attackCompact
attackFull, attackCompact, v_kog_adhoc_attack_display = CreateSyncedRollField(
    v_kog_full_view, v_kog_compact_view, "-", 
    "Attack roll total.", 
    40, -255, 40, -85, 
    nil, nil, 
    "GameFontHighlightSmall", "Attack"
)

local hyphen1Full = v_kog_full_view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
hyphen1Full:SetPoint("LEFT", attackFull, "RIGHT", 5, 0)
hyphen1Full:SetText("-")

local hyphen1Compact = v_kog_compact_view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
hyphen1Compact:SetPoint("LEFT", attackCompact, "RIGHT", 5, 0)
hyphen1Compact:SetText("-")

local naturalFull, naturalCompact
naturalFull, naturalCompact, v_kog_d20_roll_total = CreateSyncedRollField(
    v_kog_full_view, v_kog_compact_view, "-", 
    "Natural D20 roll", 
    0, 0, 0, 0, 
    hyphen1Full, hyphen1Compact, 
    "GameFontHighlight", nil
)

local hyphen2Full = v_kog_full_view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
hyphen2Full:SetPoint("LEFT", naturalFull, "RIGHT", 5, 0)
hyphen2Full:SetText("-")

local hyphen2Compact = v_kog_compact_view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
hyphen2Compact:SetPoint("LEFT", naturalCompact, "RIGHT", 5, 0)
hyphen2Compact:SetText("-")

local reactFull, reactCompact
reactFull, reactCompact, v_kog_adhoc_reaction_display = CreateSyncedRollField(
    v_kog_full_view, v_kog_compact_view, "-", 
    "Reaction roll total.", 
    0, 0, 0, 0, 
    hyphen2Full, hyphen2Compact, 
    "GameFontHighlightSmall", "React"
)

v_kog_d20_roll_dealt_result = CreateSyncedResultField(v_kog_full_view, v_kog_compact_view, "Dealt:", "Damage or healing done", 15, -290, 15, -120, 65)
v_kog_d20_roll_taken_result = CreateSyncedResultField(v_kog_full_view, v_kog_compact_view, "Taken:", "Damage you take", 90, -290, 90, -120, 70)
v_kog_d20_roll_reaction_result = CreateSyncedResultField(v_kog_full_view, v_kog_compact_view, "React:", "Reaction Roll Result", 170, -290, 170, -120, 65)


-- ==========================================
-- 8. SYNCHRONIZATION LOGIC & DATA BINDINGS
-- ==========================================

SelectSkillByName = function(skillName)
    v_kog_character_sheet.selected_skill = skillName
    
    -- Sync Radio Buttons
    for _, button in ipairs(radioGroup) do
        button:SetChecked(button.skillName == skillName)
    end
    
    -- Sync Compact Dropdown Text
    if v_kog_character_frame.skillDropCompact then
        UIDropDownMenu_SetText(v_kog_character_frame.skillDropCompact, skillName)
    end

    if kog_roll_recalculate then
        kog_roll_recalculate()
    end
end

SetEditBoxBehaviors(v_kog_character_frame.physAttkMod, function(value)
    v_kog_character_sheet.skills.physical_attack = value
    UpdateRowTotal(v_kog_character_frame.physAttkMod, v_kog_character_frame.psLabelPhys, v_kog_character_frame.totalLabelPhys)
end)

SetEditBoxBehaviors(v_kog_character_frame.defenseMod, function(value)
    v_kog_character_sheet.skills.defense = value
    UpdateRowTotal(v_kog_character_frame.defenseMod, v_kog_character_frame.psLabelDef, v_kog_character_frame.totalLabelDef)
end)

SetEditBoxBehaviors(v_kog_character_frame.healSuppMod, function(value)
    v_kog_character_sheet.skills.healing_support = value
    UpdateRowTotal(v_kog_character_frame.healSuppMod, v_kog_character_frame.psLabelHeal, v_kog_character_frame.totalLabelHeal)
end)

SetEditBoxBehaviors(v_kog_character_frame.magicAttkMod, function(value)
    v_kog_character_sheet.skills.magic_attack = value
    UpdateRowTotal(v_kog_character_frame.magicAttkMod, v_kog_character_frame.psLabelMagic, v_kog_character_frame.totalLabelMagic)
end)

SetEditBoxBehaviors(v_kog_character_frame.stealthMod, function(value)
    v_kog_character_sheet.skills.stealth = value
    UpdateRowTotal(v_kog_character_frame.stealthMod, v_kog_character_frame.psLabelStealth, v_kog_character_frame.totalLabelStealth)
end)

-- Restore compact setting or default to full sheet
SetViewMode(v_kog_character_sheet.compact_mode or false)

-- Initial label & skill selection sync
UpdatePlaystyleLabels(v_kog_character_sheet.playstyle or "Combatant")
SelectSkillByName(v_kog_character_sheet.selected_skill or "Phys Attk")