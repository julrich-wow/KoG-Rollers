-- Roll Event Handler
local event_frame = CreateFrame("FRAME");
event_frame:RegisterEvent("CHAT_MSG_SYSTEM"); -- Fired when a system message is received

event_frame:SetScript("OnEvent", function(self, event, arg1)
		-- Add a line here along the lines of "If conquest roller calculations are disabled, end function.
		-- Make enable/disable a toggle in the UI.

		-- Get the position the character name is found at. If it isn't 1, then the roll isn't for this character.
		local v_kog_name_pos
		local v_kog_roll_type_pos 
		
		-- Grab the roll from chat
		v_kog_name_pos = string.find(arg1, v_kog_playername)
		v_kog_roll_type_pos = string.find(arg1, "(1-20)")
        
		-- Break out of this function if the roll detected isn't the player running the addon or it isn't a 1-20 roll
		if v_kog_name_pos ~= 1 or v_kog_roll_type_pos == nil then
			return
		end

		if v_kog_name_pos==1 and string.find(arg1, "(1-20)") then 
			-- Extract the roll, convert to a number
			v_kog_d20_roll = string.match(arg1,"%d+") -- This is vaguely regexian nonsense. "%d+" means "Find one or more digits"
		end

        -- Combat Focus for Reaction
        --[[if v_kog_character_sheet.bad_luck_protection == "Combat Focus" then
            local v_kog_last_roll = tonumber(v_kog_d20_roll_total:GetText())
            -- Add combat focus stack if last roll was < 6. Reset Combat Focus stack if roll is > 10.
            if v_kog_last_roll < v_kog_combat_focus_roll_under then
	            v_kog_character_sheet.attack_combat_focus_stacks = v_kog_character_sheet.attack_combat_focus_stacks + 1
	        elseif v_kog_last_roll > v_kog_combat_focus_roll_over then
	            v_kog_character_sheet.attack_combat_focus_stacks = 0
	        end
        end]]

        kog_roll_result(v_kog_d20_roll)
	end)


-- Helper function to apply behavior and bind a variable to an EditBox
function SetEditBoxBehaviors(editBox, updateFunc)
    -- Store the original value when the user clicks into the box
    editBox:SetScript("OnEditFocusGained", function(self)
        self.originalValue = self:GetText()
    end)

    -- Revert to the original value and drop focus on Escape
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(self.originalValue or "")
        self:ClearFocus()
    end)

    -- Drop focus on Enter
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    -- Drop focus on Tab
    editBox:SetScript("OnTabPressed", function(self)
        self:ClearFocus()
    end)
    
    -- Trigger the update function whenever the text is modified
    editBox:SetScript("OnTextChanged", function(self, isUserInput)
        if updateFunc then
            -- GetNumber() converts the text to a math-safe integer (returns 0 if empty/invalid)
            updateFunc(self:GetNumber()) 
        end
    end)
end

function kog_roll_result(d20_roll)
    -- Pull modifiers from their text boxes 
    local currentSkill = v_kog_character_sheet.selected_skill
    local v_kog_skill_modifier
    local adhocAttackMod = tonumber(v_kog_character_sheet.adhoc_attack_roll) or 0
    local adhocReactMod = tonumber(v_kog_character_sheet.adhoc_reaction_roll) or 0
    local v_kog_d20_roll_local = tonumber(d20_roll)
    
    -- Match the selected string to the UI element row
    local v_kog_clean_skill_name = currentSkill and currentSkill:match("^([^:*]+)")

    if v_kog_clean_skill_name == "Phys Attk" then
        v_kog_skill_modifier = v_kog_character_frame.totalLabelPhys:GetText()
    elseif v_kog_clean_skill_name == "Defense" then
        v_kog_skill_modifier = v_kog_character_frame.totalLabelDef:GetText()
    elseif v_kog_clean_skill_name == "Heal/Supp" then
        v_kog_skill_modifier = v_kog_character_frame.totalLabelHeal:GetText()
    elseif v_kog_clean_skill_name == "Magic Attk" then
        v_kog_skill_modifier = v_kog_character_frame.totalLabelMagic:GetText()
    elseif v_kog_clean_skill_name == "Stealth" then
        v_kog_skill_modifier = v_kog_character_frame.totalLabelStealth:GetText()
    end
    
    local combat_focus_stacks = v_kog_character_sheet.attack_combat_focus_stacks or 0
    -- Calculate final roll values
    local v_kog_d20_modified_roll = v_kog_d20_roll_local + tonumber(v_kog_skill_modifier) 
    local v_kog_d20_attack_roll = v_kog_d20_modified_roll + tonumber(adhocAttackMod) + (combat_focus_stacks * v_kog_combat_focus_mod)
    local v_kog_d20_react_roll = v_kog_d20_modified_roll + tonumber(adhocReactMod)

    -- Initialize result values
    -- How this will work: Store the combat roll results in these variables.
    -- Add logic after the combat result checks that updates the appropriate field.
    -- This is a placeholder. If they add a significant number of cases where damage is dealt and damage is taken, it will be easier 
	-- to process using a dual array like this: attack_result.dealt[19], attack_result.taken[19]
    -- Or if it's possible: attack_result[19].dealt, attack_result[19.taken
    -- Attack variables
	local v_kog_combat_dealt_result = 0
    local v_kog_combat_taken_result = 0
    local v_kog_adhoc_attack_dealt = 0
    local v_kog_adhoc_attack_taken = 0

    -- Reaction Variables
    local v_kog_react_result = 0
    local v_kog_adhoc_react_dealt = 0
    local v_kog_adhoc_react_taken = 0

    -- Display the roll
    --if v_kog_adhoc_attack_total then v_kog_adhoc_attack_total:SetText(tostring(v_kog_d20_attack_roll)) end
    --if v_kog_adhoc_reaction_total then v_kog_adhoc_reaction_total:SetText(tostring(v_kog_d20_react_roll)) end

    -- Display the d20 roll
    --v_kog_d20_roll_total:SetText(v_kog_d20_modified_roll.." ( "..d20_roll..")")
    v_kog_d20_roll_total:SetText(d20_roll)
    v_kog_adhoc_attack_display:SetText(v_kog_d20_attack_roll)
    v_kog_adhoc_reaction_display:SetText(v_kog_d20_react_roll)

    -- Calculate
    -- Implement updated Damage Dealt and Damage Taken logic.
    if v_kog_d20_attack_roll >= 9 and v_kog_d20_attack_roll <=20 then
	    if v_kog_d20_attack_roll == 9 then v_kog_combat_taken_result = -1 end -- "Set damage dealt when players roll a dual result" code. Expand as necessary.
        v_kog_combat_dealt_result = v_kog_attack_table[v_kog_d20_attack_roll] -- Calculate baseline attack dealt total
    elseif v_kog_d20_attack_roll >= 1 and v_kog_d20_attack_roll <=8 then
	    v_kog_combat_taken_result = v_kog_attack_table[v_kog_d20_attack_roll] 
    elseif v_kog_d20_attack_roll > 20 then
	    v_kog_combat_dealt_result = v_kog_attack_table[20]
    else
	    v_kog_combat_taken_result = v_kog_attack_table[1]
	end

    -- Apply and calculate ad-hoc modifiers to attack
    v_kog_adhoc_attack_roll = v_kog_d20_attack_roll + v_kog_modifier_frame.attackRollMod:GetNumber() -- Set adhoc modified dealt result
    v_kog_adhoc_attack_dealt = v_kog_combat_dealt_result + v_kog_modifier_frame.attackDealtMod:GetNumber() -- Set adhoc modified dealt result
    v_kog_adhoc_attack_taken = v_kog_combat_taken_result + v_kog_modifier_frame.attackTakenMod:GetNumber() -- Set adhoc modified taken result

    -- Set combat damage Dealt and Taken results. Eventual goal is to integrate all results into the baseline window and eliminate 
	-- the sub-results in the modifier window
    
	--[[ -- Commenting this out while I test moving the results to the main character sheet. If this works out and people like it, this code can be removed later.
    -- Commented out 7/27/2026 in v 1.0.5
	v_kog_d20_roll_dealt_result:SetText(v_kog_combat_dealt_result) -- Baseline attack dealt
    v_kog_d20_roll_taken_result:SetText(v_kog_combat_taken_result) -- Baseline attack taken
    v_kog_adhoc_attack_dealt_total:SetText(v_kog_adhoc_attack_dealt) -- Adhoc dealt
    v_kog_adhoc_attack_taken_total:SetText(v_kog_adhoc_attack_taken) -- Adhoc taken ]]

    v_kog_d20_roll_dealt_result:SetText(v_kog_adhoc_attack_dealt) -- Display the Ad Hoc Dealt value in the main character sheet
    v_kog_d20_roll_taken_result:SetText(v_kog_adhoc_attack_taken) -- display the Ad Hoc Taken value in the main character sheet

    -- Display the react result
    -- Need to implement Damage Dealt and Damage Taken logic.
    if v_kog_d20_react_roll >= 1 and v_kog_d20_react_roll <=20 then
        v_kog_d20_roll_reaction_result:SetText(v_kog_reaction_table[v_kog_d20_react_roll]+v_kog_modifier_frame.reactionTakenMod:GetNumber()) -- Set main character frame result
        --v_kog_adhoc_reaction_taken_total:SetText(v_kog_reaction_table[v_kog_d20_react_roll]+v_kog_modifier_frame.reactionTakenMod:GetNumber()) -- Set adhoc modified result
    elseif v_kog_d20_react_roll > 20 then
	    v_kog_d20_roll_reaction_result:SetText(v_kog_reaction_table[20]+v_kog_modifier_frame.reactionTakenMod:GetNumber())
        --v_kog_adhoc_reaction_taken_total:SetText(v_kog_reaction_table[20]+v_kog_modifier_frame.reactionTakenMod:GetNumber())
	else
	    v_kog_d20_roll_reaction_result:SetText(v_kog_reaction_table[1]+v_kog_modifier_frame.reactionTakenMod:GetNumber())
        --v_kog_adhoc_reaction_taken_total:SetText(v_kog_reaction_table[1]+v_kog_modifier_frame.reactionTakenMod:GetNumber())
	end

    -- Set Reaction Dealt to be equal to whatever the modifier is, since there's no reaosn to calculate it.
    v_kog_adhoc_reaction_dealt_total:SetText(v_kog_modifier_frame.reactionDealtMod:GetNumber()+v_kog_modifier_frame.reactionTakenMod:GetNumber())

    -- Commented out; may not need these in the future.
    -- Klugey fix for now. Want to make sure that no one ever thinks they somehow heal from succeeding on a Reaction roll.
    --if tonumber(v_kog_d20_roll_reaction_result:GetText()) > 0 then v_kog_d20_roll_reaction_result:SetText(0) end
    --if tonumber(v_kog_adhoc_reaction_taken_total:GetText()) >= 0 then v_kog_adhoc_reaction_taken_total:SetText(0) end
end

function kog_roll_recalculate()
    -- Called whenever a field changes to recalculate totals across the sheet.
    -- Get the unmodified roll result stored next to Roll Total in the main sheet.
    -- The call the roll calculator function using that value.
    kog_roll_result(v_kog_d20_roll)
end
