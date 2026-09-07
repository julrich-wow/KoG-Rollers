-- Capture player name
v_kog_playername = UnitName("player")

-- Player Character sheet default array
v_kog_character_sheet = {
	base_hp = 10,
	bad_luck_protection = "None",
	playstyle = "None",
	skills = {
		physical_attack = 0,
		defense = 0,
		healing_support = 0,
		magic_attack = 0,
		stealth = 0
	},
	traits = { "", "", ""},
	attack_combat_focus_stacks = 0,
	react_combat_focus_stacks = 0,
	reroll_charges = 0,
	adhoc_attack_roll = 0,
	adhoc_attack_dealt = 0,
	adhoc_attack_taken = 0,
	adhoc_reaction_roll = 0,
	adhoc_reaction_dealt = 0,
	adhoc_reaction_taken = 0,
	selected_skill = "Phys Attk",
	character_frame_visible = true,
	modifier_frame_visible = true,
	compact_mode = false,
	version = ""
}

-- Combat Playstyle Modifiers
v_kog_combat_playstyle = {
	combatant = {
		physical_attack = 1,
		physical_damage = 0,
		damage_taken = 0,
		defense = 0,
		healing_support = 0,
		healing_done = 0,
		magic_attack = 1,
		magic_damage = 0,
		stealth=0
	},
	ravager = {
		physical_attack = 0,
		physical_damage = 1,
		damage_taken = 0,
		defense = 0,
		healing_support = 0,
		healing_done = 0,
		magic_attack = 0,
		magic_damage = 1,
		stealth=0
	},
	mender = {
		physical_attack = 0,
		physical_damage = 0,
		damage_taken = 0,
		defense = 0,
		healing_support = 0,
		healing_done = 1,
		magic_attack = 0,
		magic_damage = 0,
		stealth=0
	},
	guardian = {
		physical_attack = 0,
		physical_damage = 0,
		damage_taken = -1,
		defense = 0,
		healing_support = 0,
		healing_done = 1,
		magic_attack = 0,
		magic_damage = 0,
		stealth=0
	},
	berserker = {
		physical_attack = 2,
		physical_damage = 0,
		damage_taken = 0,
		defense = -2,
		healing_support = 0,
		healing_done = 1,
		magic_attack = 0,
		magic_damage = 0,
		stealth=0
	},
	bulwark = {
		physical_attack = -2,
		physical_damage = 0,
		damage_taken = 0,
		defense = 2,
		healing_support = 0,
		healing_done = 0,
		magic_attack = -2,
		magic_damage = 0,
		stealth=0
	},
	juggernaut = {
		physical_attack = 0,
		physical_damage = 0,
		damage_taken = 0,
		defense = 2,
		healing_support = 0,
		healing_done = 0,
		magic_attack = 0,
		magic_damage = 0,
		stealth=0
	},
	glass_cannon = {
		physical_attack = 0,
		physical_damage = 2,
		damage_taken = 0,
		defense = -2,
		healing_support = 0,
		healing_done = 0,
		magic_attack = 0,
		magic_damage = 2,
		stealth=0
	},
	assassin_sniper = {
		physical_attack = 0,
		physical_damage = 0,
		damage_taken = 0,
		defense = -2,
		healing_support = 0,
		healing_done = 0,
		magic_attack = 0,
		magic_damage = 0,
		stealth=2
	},
	 battlefield_chirurgeon = {
		physical_attack = -2,
		physical_damage = 0,
		damage_taken = 0,
		defense = 0,
		healing_support = 2,
		healing_done = 0,
		magic_attack = -2,
		magic_damage = 0,
		stealth=0
	},
}

-- Map dropdown text strings to the keys in v_kog_combat_playstyle
playstyleMap = {
    ["Combatant"] = "combatant",
    ["Ravager"] = "ravager",
    ["Mender"] = "mender",
    ["Guardian"] = "guardian",
    ["Berserker"] = "berserker",
    ["Bulwark"] = "bulwark",
    ["Juggernaut"] = "juggernaut",
    ["Glass Cannon"] = "glass_cannon",
    ["Assassin/Sniper"] = "assassin_sniper",
    ["Battlefield Chirurgeon"] = "battlefield_chirurgeon"
}

-- Combat Focus Modifier
v_kog_combat_focus_mod = 2			-- The bonus each combat focus stack grants.
v_kog_combat_focus_roll_under = 6	-- if you roll <= this value, you get a stack of combat focus
v_kog_combat_focus_roll_over = 10	-- When your final roll is >= this value, reset combat focus to 0

-- Attack Table
-- Rolling a 9 on the attack table deals base 1 damage/healing to the target and 1 damage to the roller
v_kog_attack_table = {-5, -4, -4, -3, -3, -3, -2, -2, 1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5}

-- These 1 and 2 actually are: -4 and DM inflicts negative status
-- 17-20 deal damage to the attacker
v_kog_reaction_table = {-5, -4, -4, -3, -3, -3, -2, -2, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

-- Natural value of last d20 roll.
v_kog_d20_roll = 20

-- Updater function
local function kog_apply_updates()
	-- v1.0.7 Updater
	if C_AddOns.GetAddOnMetadata("KoG_D20", "Version") == "1.0.8" and (v_kog_character_sheet.version == "" or v_kog_character_sheet.version == nil) then 
		if v_kog_character_sheet.selected_skill:sub(-1) == ":" then -- If the last character is a colon, then strip the colon
			v_kog_character_sheet.selected_skill = v_kog_character_sheet.selected_skill:sub(1, -2)
		end
		v_kog_character_sheet.version = "1.0.8"
	end
end

-- Load saved variables into their text boxes.
-- Register an event frame to wait for variables to load before populating UI
-- Add additional variable loads as development continues.
-- This means the addon populates with default values, then this overwrites them.
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "VARIABLES_LOADED" then
		-- Call Update function
		kog_apply_updates()

        -- Ensure the skills table exists to prevent nil indexing errors on first load
        v_kog_character_sheet = v_kog_character_sheet or {}
        v_kog_character_sheet.skills = v_kog_character_sheet.skills or {}

        -- Load the stored values into the UI, defaulting to an empty string if nil or 0
		local function GetDisplayValue(val)
		-- This now only checks if val exists. If it is 0, it will convert it to "0".
		return (val ~= nil) and tostring(val) or "" 
		end
        
        -- Modifier Frame Text Boxes
		-- Attack results
        v_kog_modifier_frame.attackRollMod:SetText(GetDisplayValue(v_kog_character_sheet.adhoc_attack_roll))
        v_kog_modifier_frame.attackDealtMod:SetText(GetDisplayValue(v_kog_character_sheet.adhoc_attack_dealt))
		v_kog_modifier_frame.attackTakenMod:SetText(GetDisplayValue(v_kog_character_sheet.adhoc_attack_taken))

		-- Reaction Result
        v_kog_modifier_frame.reactionRollMod:SetText(GetDisplayValue(v_kog_character_sheet.adhoc_reaction_roll))
		v_kog_modifier_frame.reactionDealtMod:SetText(GetDisplayValue(v_kog_character_sheet.adhoc_reaction_dealt))
        v_kog_modifier_frame.reactionTakenMod:SetText(GetDisplayValue(v_kog_character_sheet.adhoc_reaction_taken))
        
        -- Character Sheet Text Boxes
        v_kog_character_frame.physAttkMod:SetText(GetDisplayValue(v_kog_character_sheet.skills.physical_attack))
        v_kog_character_frame.defenseMod:SetText(GetDisplayValue(v_kog_character_sheet.skills.defense))
        v_kog_character_frame.healSuppMod:SetText(GetDisplayValue(v_kog_character_sheet.skills.healing_support))
        v_kog_character_frame.magicAttkMod:SetText(GetDisplayValue(v_kog_character_sheet.skills.magic_attack))
        v_kog_character_frame.stealthMod:SetText(GetDisplayValue(v_kog_character_sheet.skills.stealth))

		-- Playstyle Value & Dropdown Loading Logic
		local rawPlaystyle = v_kog_character_sheet and v_kog_character_sheet.playstyle or "Combatant"
		local dataKey = playstyleMap[rawPlaystyle] or rawPlaystyle

		-- Fallback to "combatant" if key doesn't exist in data table
		if not v_kog_combat_playstyle or not v_kog_combat_playstyle[dataKey] then
			dataKey = "combatant"
		end

		-- Reverse lookup to map database keys to formatted display labels (e.g., "bulwark" -> "Bulwark")
		local displayPlaystyle = "Combatant"
		for label, key in pairs(playstyleMap) do
			if key == dataKey then
				displayPlaystyle = label
				break
			end
		end

		-- Sync internal saved variable to raw key
		v_kog_character_sheet.playstyle = dataKey

        -- Character Sheet Dropdowns
        UIDropDownMenu_SetText(v_kog_character_frame.playstyleDrop, displayPlaystyle)
        UIDropDownMenu_SetText(v_kog_character_frame.hpDrop, v_kog_character_sheet.base_hp or "10")
        UIDropDownMenu_SetText(v_kog_character_frame.blpDrop, v_kog_character_sheet.bad_luck_protection or "Re-roll")

		-- Update the UI stat labels if frames are initialized
		local stats = v_kog_combat_playstyle[dataKey]
		if v_kog_character_frame and v_kog_character_frame.psLabelPhys and stats then
			v_kog_character_frame.psLabelPhys:SetText(stats.physical_attack)
			v_kog_character_frame.psLabelDef:SetText(stats.defense)
			v_kog_character_frame.psLabelHeal:SetText(stats.healing_support)
			v_kog_character_frame.psLabelMagic:SetText(stats.magic_attack)
			v_kog_character_frame.psLabelStealth:SetText(stats.stealth)
        
			-- Safely call row totals recalculation
			if type(UpdateAllRowTotals) == "function" then
				UpdateAllRowTotals()
			end
		end

		-- Radio button loading logic
		if not v_kog_character_sheet.selected_skill or v_kog_character_sheet.selected_skill == "" then
            v_kog_character_sheet.selected_skill = "Phys Attk"
        end

        local savedSkill = v_kog_character_sheet.selected_skill

        -- Iterate over the group and check the one matching the saved skill string
        if radioGroup then
            for _, button in ipairs(radioGroup) do
                button:SetChecked(button.skillName == savedSkill)
            end
        end

       -- Show or hide the windows based on their last shown/hidden status.
       if v_kog_character_sheet.character_frame_visible then v_kog_character_frame:Show() else v_kog_character_frame:Hide() end 
	   if v_kog_character_sheet.modifier_frame_visible then v_kog_modifier_frame:Show() else v_kog_modifier_frame:Hide() end 

		-- Set full/Compact size based on v_kog_character_sheet.compact_mode
		if v_kog_character_sheet.compact_mode then
		  v_kog_full_view:Hide()
          v_kog_compact_view:Show()
          v_kog_character_frame:SetSize(250, 155) -- Need to be sure this is sync'd with the dimensions in SetViewMode.
          v_kog_compact_toggle_button:SetText("+")
		else 
		  v_kog_compact_view:Hide()
          v_kog_full_view:Show()
          v_kog_character_frame:SetSize(250, 325)
          v_kog_compact_toggle_button:SetText("-")
		end

		v_kog_character_sheet.attack_combat_focus_stacks = v_kog_character_sheet.attack_combat_focus_stacks or 0

		-- Print the notice that the addon is loaded.
		print("|cFF00FF00[KoG d20]|r Loaded. Type /kog20 to list inputs.")
       -- Unregister the event since we only need this to happen once
        self:UnregisterEvent("VARIABLES_LOADED")
    end
end)