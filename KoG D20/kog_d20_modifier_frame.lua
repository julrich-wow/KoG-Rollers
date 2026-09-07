-- Ensure the character sheet table exists to prevent nil errors
v_kog_character_sheet = v_kog_character_sheet or {}

-- ==========================================
-- 1. MAIN WINDOW CONTAINER
-- ==========================================
v_kog_modifier_frame = CreateFrame("Frame", "kog_d20_modifier_frame", UIParent, "BasicFrameTemplateWithInset")
v_kog_modifier_frame:SetSize(300, 150) -- Height increased to 150 to fit the 3rd row
v_kog_modifier_frame:SetPoint("CENTER")

-- Enable automatic bring-to-front behavior
v_kog_modifier_frame:SetToplevel(true)
v_kog_modifier_frame:SetFrameStrata("MEDIUM")
v_kog_modifier_frame:SetFrameLevel(5) -- Lower base level so Character Sheet defaults on top

-- Frame Interactivity & Dragging
v_kog_modifier_frame:SetMovable(true)
v_kog_modifier_frame:EnableMouse(true)
v_kog_modifier_frame:RegisterForDrag("LeftButton")
v_kog_modifier_frame:SetScript("OnDragStart", v_kog_modifier_frame.StartMoving)
v_kog_modifier_frame:SetScript("OnDragStop", v_kog_modifier_frame.StopMovingOrSizing)
v_kog_modifier_frame:SetScript("OnMouseDown", function(self)
    self:Raise()
end)

-- Addon Title Text
v_kog_modifier_frame.title = v_kog_modifier_frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
v_kog_modifier_frame.title:SetPoint("CENTER", v_kog_modifier_frame.TitleBg, "CENTER", 0, 0)
v_kog_modifier_frame.title:SetText("Roll Modifiers")

-- Close Logic
v_kog_modifier_frame:SetScript("OnHide", function(self)
    -- Insert whatever logic you want to happen when the frame closes
    v_kog_character_sheet.modifier_frame_visible = false    
end)

-- ==========================================
-- 2. HIGH-PRIORITY CONTENT LAYER
-- ==========================================
local contentFrame = CreateFrame("Frame", nil, v_kog_modifier_frame)
contentFrame:SetAllPoints(v_kog_modifier_frame)
contentFrame:SetFrameLevel(v_kog_modifier_frame:GetFrameLevel() + 10)

-- ==========================================
-- HELPER: ROW CREATION W/ TOOLTIPS
-- ==========================================
local function CreateModRow(parent, labelText, mainTooltip, xOffset, yOffset, totalTooltip)

    -- 1. Wrapper frame for the Label to capture mouse events for the tooltip
    local labelFrame = CreateFrame("Frame", nil, parent)
    labelFrame:SetSize(45, 20)
    labelFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    
    local label = labelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetAllPoints(labelFrame)
    label:SetJustifyH("RIGHT")
    label:SetText(labelText)

    labelFrame:EnableMouse(true)
    labelFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(mainTooltip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    labelFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- 2. The EditBox
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(35, 20)
    editBox:SetPoint("LEFT", labelFrame, "RIGHT", 5, 0)
    editBox:SetAutoFocus(false)
    
    -- Adding the tooltip to the edit box as well for better UX
    editBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(mainTooltip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    editBox:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- 3. Wrapper frame for the Total to capture mouse events for the total tooltip
    local totalFrame = CreateFrame("Frame", nil, parent)
    totalFrame:SetSize(35, 20)
    totalFrame:SetPoint("LEFT", editBox, "RIGHT", 10, 0)

    local totalLabel = totalFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalLabel:SetAllPoints(totalFrame)
    totalLabel:SetJustifyH("LEFT")
    totalLabel:SetText("-")

    totalFrame:EnableMouse(true)
    totalFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(totalTooltip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    totalFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return editBox, totalLabel
end

-- ==========================================
-- 3. ATTACK COLUMN (LEFT SIDE)
-- ==========================================
local attackHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
attackHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 50, -35)
attackHeader:SetText("Attack")

v_kog_modifier_frame.attackRollMod, v_kog_adhoc_attack_total = CreateModRow(contentFrame, "Roll:", "Attack roll modifier.", 10, -55, "Situational attack roll.")
v_kog_modifier_frame.attackDealtMod, v_kog_adhoc_attack_dealt_total = CreateModRow(contentFrame, "Dealt:", "Modifier to damage or healing dealt.", 10, -85, "Situational damage/healing dealt.")
v_kog_modifier_frame.attackTakenMod, v_kog_adhoc_attack_taken_total = CreateModRow(contentFrame, "Taken:", "Modifier to damage or healing taken.", 10, -115, "Situational damage taken.")

-- ==========================================
-- 4. REACTION COLUMN (RIGHT SIDE)
-- ==========================================
local reactionHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
reactionHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 195, -35)
reactionHeader:SetText("Reaction")

v_kog_modifier_frame.reactionRollMod, v_kog_adhoc_reaction_total = CreateModRow(contentFrame, "Roll:", "Modifier to your reaction roll", 155, -55, "Situational reaction roll.")
v_kog_modifier_frame.reactionDealtMod, v_kog_adhoc_reaction_dealt_total = CreateModRow(contentFrame, "Dealt:", "Damage dealt by this reaction roll", 155, -85, "Situational damage dealt by reaction roll.")
v_kog_modifier_frame.reactionTakenMod, v_kog_adhoc_reaction_taken_total = CreateModRow(contentFrame, "Taken:", "Additional damage taken by your character on reaction rolls", 155, -115, "Situational damage taken by reaction rolls.")

-- ==========================================
-- 5. DATA BINDINGS & BEHAVIORS
-- ==========================================

SetEditBoxBehaviors(v_kog_modifier_frame.attackRollMod, function(value)
    v_kog_character_sheet.adhoc_attack_roll = value
    kog_roll_recalculate()
end)

SetEditBoxBehaviors(v_kog_modifier_frame.attackDealtMod, function(value)
    v_kog_character_sheet.adhoc_attack_dealt = value
    kog_roll_recalculate()
end)

SetEditBoxBehaviors(v_kog_modifier_frame.attackTakenMod, function(value)
    v_kog_character_sheet.adhoc_attack_taken = value
    kog_roll_recalculate()
end)

SetEditBoxBehaviors(v_kog_modifier_frame.reactionRollMod, function(value)
    v_kog_character_sheet.adhoc_reaction_roll = value
    kog_roll_recalculate()
end)

SetEditBoxBehaviors(v_kog_modifier_frame.reactionDealtMod, function(value)
    v_kog_character_sheet.adhoc_reaction_dealt = value
    kog_roll_recalculate()
end)

SetEditBoxBehaviors(v_kog_modifier_frame.reactionTakenMod, function(value)
    v_kog_character_sheet.adhoc_reaction_taken = value
    kog_roll_recalculate()
end)