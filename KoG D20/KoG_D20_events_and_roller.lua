-- The string between SLASH_ and the digit is the name of the table referenced in SlashCmdList
SLASH_kogroller1 = '/kog20'

-- Slash Command Handler
SlashCmdList["kogroller"] = function(msg, editbox)
	-- Define local variables
	local v_parsed_input = {}

	-- Parse out the commands and the die modifier
	for i in string.gmatch(msg, "%S+") do
		v_parsed_input[#v_parsed_input + 1] = i
	end

	-- Testing to see if the addon can call /roll
	if v_parsed_input[1]=="roll" then 
		RandomRoll(1,20) -- Call WoW's built in die roller to roll a d20.
	elseif v_parsed_input[1]=="show" then
		v_kog_modifier_frame:Show()
		v_kog_character_frame:Show()
		v_kog_character_sheet.character_frame_visible = true
	    v_kog_character_sheet.modifier_frame_visible = true
	elseif v_parsed_input[1]=="hide" then
		v_kog_modifier_frame:Hide()
		v_kog_character_frame:Hide()
		v_kog_character_sheet.character_frame_visible = false
	    v_kog_character_sheet.modifier_frame_visible = false
	elseif v_parsed_input[1]=="setup" then
		-- Toggle the setup frame
	else
		--[[v_kog_modifier_frame:Show()
		v_kog_character_frame:Show()
		v_kog_character_sheet.character_frame_visible = true
	    v_kog_character_sheet.modifier_frame_visible = true]]
		SendSystemMessage("KoG 20 Commands:")
		SendSystemMessage("/kog20: Displays this help dialogue.")
		SendSystemMessage("/kog20 show: Shows the character sheet and modifier window.")
		SendSystemMessage("/kog20 hide: Hides the character sheet and modifier window.")
		SendSystemMessage("/kog20 roll: Rolls a d20 using Blizzard's built in functions.")

	end
end