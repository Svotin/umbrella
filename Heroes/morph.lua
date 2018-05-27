local morph = {}

morph.optionEnable = Menu.AddOptionBool({"Hero Specific", "Morph"}, "Enable", false)
morph.AutoShift = Menu.AddOptionBool({"Hero Specific", "Morph","AutoShift"}, "Enable", false)
morph.AdditionalAbilities = Menu.AddOptionBool({"Hero Specific", "Morph","AutoShift"}, "[unstable]additionalAbilities", false)
morph.AutoKill = Menu.AddOptionBool({"Hero Specific", "Morph", "EBladeAutoKill"}, "Enable", false)
morph.AutoKillKey = Menu.AddKeyOption({"Hero Specific",  "Morph", "EBladeAutoKill"}, "Toggle Key", Enum.ButtonCode.KEY_0)
morph.customResist = Menu.AddOptionSlider({"Hero Specific", "Morph", "EBladeAutoKill"}, "customResist", 0, 80, 25)

morph.myHero = nil
morph.players = {}
morph.ability = {}
Font = Renderer.LoadFont("Tahoma", 22, Enum.FontWeight.BOLD)
morph.localDmg = 0

morph.defaultAbilities = {
	{"npc_dota_hero_axe", "axe_berserkers_call", 300, false},   		--false - пробивает через бкб
	{"npc_dota_hero_tidehunter", "tidehunter_ravage", 1250, true},      --true - не пробивает бкб
	{"npc_dota_hero_enigma", "enigma_black_hole", 720, false},
	{"npc_dota_hero_magnataur", "magnataur_reverse_polarity", 430, false},
	{"npc_dota_hero_slardar", "slardar_slithereen_crush", 355, true},
	{"npc_dota_hero_centaur", "centaur_hoof_stomp", 345, true}

--	{"npc_dota_hero_batrider", "batrider_flaming_lasso", 170},
--	{"npc_dota_hero_faceless_void", "faceless_void_chronosphere", 1100},
--	{"npc_dota_hero_legion_commander", "legion_commander_duel", 150},
--	{"npc_dota_hero_beastmaster", "beastmaster_primal_roar", 600},
--	{"npc_dota_hero_sven", "sven_storm_bolt", 600},
--	{"npc_dota_hero_bane", "bane_fiends_grip", 625},
--	{"npc_dota_hero_pudge", "pudge_dismember", 160},
--	{"npc_dota_hero_doom_bringer", "doom_bringer_doom", 550},
--	{"npc_dota_hero_disruptor", "disruptor_static_storm", 1450}
}
morph.additionalAbilities = {
	{"npc_dota_hero_axe", "axe_berserkers_call", 300, false},
	{"npc_dota_hero_tidehunter", "tidehunter_ravage", 1250, true},
	{"npc_dota_hero_enigma", "enigma_black_hole", 720, false},
	{"npc_dota_hero_magnataur", "magnataur_reverse_polarity", 430, false},
	{"npc_dota_hero_slardar", "slardar_slithereen_crush", 355, true},
	{"npc_dota_hero_centaur", "centaur_hoof_stomp", 345, true},

	--------------------------------------------------------------------

	{"npc_dota_hero_batrider", "batrider_flaming_lasso", 170, false},
	{"npc_dota_hero_faceless_void", "faceless_void_chronosphere", 1100, false},
	{"npc_dota_hero_legion_commander", "legion_commander_duel", 150, false},
	{"npc_dota_hero_pudge", "pudge_dismember", 160, false}
}


function morph.OnUpdate()
	if not Menu.IsEnabled(morph.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then 
		for i = 0, 10 do
      		if morph.players[i] then
        		Menu.RemoveOption(morph.players[i]) 
        		morph.players[i] = nil
     		end
    	end return 
    end
	morph.myHero = Heroes.GetLocal()
	if NPC.GetUnitName(morph.myHero) ~= "npc_dota_hero_morphling" then return end
	if Menu.IsKeyDownOnce(morph.AutoKillKey) then
		if Menu.IsEnabled(morph.AutoKill) then
			Menu.SetEnabled(morph.AutoKill, false)
		else 
			Menu.SetEnabled(morph.AutoKill, true)
		end		
	end
	local FHeroes = Heroes.GetAll()
	if Menu.IsEnabled(morph.AutoShift) then
		if not Entity.IsAlive(morph.myHero) or NPC.IsStunned(morph.myHero) or NPC.IsSilenced(morph.myHero) then return end
		local shift = NPC.GetAbilityByIndex(morph.myHero, 4)
		if Menu.IsEnabled(morph.AdditionalAbilities) then
			morph.ability = morph.additionalAbilities
		else 
			morph.ability = morph.defaultAbilities
		end
		for _,v in pairs(FHeroes) do
			if v and Entity.IsHero(v) and Entity.IsAlive(v) and not Entity.IsSameTeam(morph.myHero, v) and not Entity.IsDormant(v) and not NPC.IsIllusion(v) then
				for i,k in pairs(morph.ability) do
					if NPC.GetUnitName(v) == k[1] then
						local p1 = NPC.GetAbility(v, k[2])
						if p1 ~= (nil or 0) and Ability.IsInAbilityPhase(p1) then								 
							local p2 = Ability.GetCastPoint(p1)
							if NPC.IsEntityInRange(morph.myHero, v, k[3]) then
								if NPC.HasState(morph.myHero,Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) and k[4] then 
									return 
								end
								if not Ability.GetToggleState(shift) then
									Ability.Toggle(shift)
											return
								end
							end
						end
					end
				end		
			end
		end
	end
	if Menu.IsEnabled(morph.AutoKill) then
		for i = 1, Heroes.Count() do
   			local hero = Heroes.Get(i)
   			if not Entity.IsSameTeam(morph.myHero, hero) and not morph.players[Hero.GetPlayerID(hero)] and hero ~= morph.myHero then 
   				morph.players[Hero.GetPlayerID(hero)] = Menu.AddOptionBool({"Hero Specific", "Morph", "EBladeAutoKill"}, string.upper(string.sub(NPC.GetUnitName(hero), 15)), false)
   				return
   			end
   		end 
   		local strike = NPC.GetAbilityByIndex(morph.myHero, 1)
   		local eblade = NPC.GetItem(morph.myHero, "item_ethereal_blade", true)
		local agility = Hero.GetAgilityTotal(morph.myHero)
		local strenght = Hero.GetStrengthTotal(morph.myHero)
		local intellect = Hero.GetIntellectTotal(morph.myHero)
		local strikeDmg =  getStrikeDmg(agility, strenght, strike)
		local totalMana = 0
		local castRange = 0
		local ebladeMultiplier = 1
		local ebladeDmg = 0
		if strikeDmg ~= 0 then 
			if Ability.GetManaCost(strike)<= NPC.GetMana(morph.myHero) then
				totalMana = totalMana + Ability.GetManaCost(strike)
				castRange = Ability.GetCastRange(strike)
			end
		end
		if eblade and Ability.IsReady(eblade) then
			if Ability.GetManaCost(eblade)+totalMana <= NPC.GetMana(morph.myHero) then
				ebladeMultiplier = 1.4
				ebladeDmg = 75 + (2 * agility)
				totalMana = totalMana + Ability.GetManaCost(eblade)
				castRange = Ability.GetCastRange(eblade)
			end
		end
		if ebladeDmg == 0 and strikeDmg == 0 then  morph.localDmg = 0 return end
		local intMultiplier = ((0.069 * intellect) / 100) + 1
		morph.localDmg = ((strikeDmg+ebladeDmg)*ebladeMultiplier)*intMultiplier
		for _,hero in pairs(FHeroes) do
			if hero ~= nil and hero ~= 0 and NPCs.Contains(hero) and NPC.IsEntityInRange(morph.myHero, hero,castRange) and not Entity.IsSameTeam(hero,morph.myHero) then
				if Entity.IsAlive(hero) and not Entity.IsDormant(hero) and not NPC.IsIllusion(hero) and Menu.IsEnabled(morph.players[Hero.GetPlayerID(hero)]) and morph.IsHasGuard(hero)=="nil"  then
					local totalDmg = morph.GetTotalDmg(hero, morph.localDmg, morph.myHero) - 2
					if Entity.GetHealth(hero) <= totalDmg then
						if ebladeDmg > 0 then
							Ability.CastTarget(eblade, hero)
						end
						if strikeDmg > 0 then 
							Ability.CastTarget(strike, hero)
						end return
					end
				end
			end
		end
	end
end

function getStrikeDmg(agility, strenght, strike)
	if not strike then return 0 end
	if not Ability.IsReady(strike) then return 0 end
	local strikeLevel = Ability.GetLevel(strike)
	if strikeLevel == 0 then return 0 end
	local damageMultiplier = 0.5
	local minMultiplier  = 0.5
	local maxMultiplier = 0.5 + (strikeLevel*0.5)
	local totalAttributies = agility + strenght
	if (totalAttributies/100*75 < agility) then 
		damageMultiplier = maxMultiplier
	else
		damageMultiplier = minMultiplier
	end
	strikeDmg = 100 + (agility*damageMultiplier)
	return strikeDmg
end


function morph.IsHasGuard(npc) --ЧЕСТНО СПИЗДИЛ
	local guarditis = "nil"
	if NPC.IsLinkensProtected(npc) then guarditis = "Linkens" end
	if NPC.HasModifier(npc,"modifier_item_blade_mail_reflect") then guarditis = "BM" end
	local spell_shield = NPC.GetAbility(npc, "antimage_spell_shield")
	if spell_shield and Ability.IsReady(spell_shield) and (NPC.HasModifier(npc, "modifier_item_ultimate_scepter") or NPC.HasModifier(npc, "modifier_item_ultimate_scepter_consumed")) then
		guarditis = "Lotus"
	end
	if NPC.HasModifier(npc,"modifier_item_lotus_orb_active") then guarditis = "Lotus" end
	if 	NPC.HasState(npc,Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) or 
		NPC.HasState(npc,Enum.ModifierState.MODIFIER_STATE_OUT_OF_GAME) or
		NPC.HasModifier(npc,"modifier_medusa_stone_gaze_stone") or
		NPC.HasModifier(npc,"modifier_winter_wyvern_winters_curse") or
		NPC.HasModifier(npc,"modifier_templar_assassin_refraction_absorb") or
		NPC.HasModifier(npc,"modifier_nyx_assassin_spiked_carapace") or
		NPC.HasModifier(npc,"modifier_abaddon_borrowed_time") or
		NPC.HasModifier(npc,"modifier_item_aeon_disk_buff") or

		NPC.HasModifier(npc,"modifier_special_bonus_spell_block") then
			guarditis = "Immune"
	end
	if NPC.HasModifier(npc,"modifier_legion_commander_duel") then
		local duel = NPC.GetAbility(npc, "legion_commander_duel")
		if duel then
			if NPC.HasModifier(npc, "modifier_item_ultimate_scepter") or NPC.HasModifier(npc, "modifier_item_ultimate_scepter_consumed") then
				guarditis = "Immune"
			end
		else
			for _,hero in pairs(Heroes.GetAll()) do
				if hero ~= nil and hero ~= 0 and NPCs.Contains(hero) and not Entity.IsSameTeam(hero,npc) and NPC.HasModifier(hero,"modifier_legion_commander_duel") then
					local dueltarget = NPC.GetAbility(hero, "legion_commander_duel")
					if dueltarget then
						if NPC.HasModifier(hero, "modifier_item_ultimate_scepter") or NPC.HasModifier(hero, "modifier_item_ultimate_scepter_consumed") then
							guarditis = "Immune"
						end
					end
				end
			end
		end
	end
	local aeon_disk = NPC.GetItem(npc, "item_aeon_disk")
	if aeon_disk and Ability.IsReady(aeon_disk) then guarditis = "Immune" end
	return guarditis
end

function morph.GetTotalDmg(target,dmg, myHero)--ЧЕСТНО СПИЗДИЛ
	if not target or not myHero then return end
	local totalDmg = (dmg * NPC.GetMagicalArmorDamageMultiplier(target))
	local kaya = NPC.GetItem(morph.myHero, "item_kaya", true)
	if kaya then 
		totalDmg = totalDmg*1.1 
	end
	if NPC.HasModifier(target,"modifier_dark_willow_shadow_realm_buff") then 
		return 0
	end
	local mana_shield = NPC.GetAbility(target, "medusa_mana_shield")
	if mana_shield and Ability.GetToggleState(mana_shield) then
			totalDmg = totalDmg * 0.4
	end
	if NPC.HasModifier(target,"modifier_ursa_enrage") then
		totalDmg = totalDmg * 0.2
	end
	local dispersion = NPC.GetAbility(target, "spectre_dispersion")
	if dispersion then
		if NPC.GetAbility(target, "special_bonus_unique_spectre") then
			totalDmg = totalDmg * 0.70
		else
			totalDmg = totalDmg*0.78
		end
	end
	if NPC.HasModifier(target, "modifier_wisp_overcharge") then 
		totalDmg = totalDmg*0.80
	end
	local bristleback = NPC.GetAbility(target, "bristleback_bristleback")
	if bristleback then 
		totalDmg = totalDmg * 0.4
	end
	if NPC.HasModifier(target,"modifier_bloodseeker_bloodrage") then
		totalDmg = totalDmg * 1.4
	end
	if NPC.HasModifier(target,"modifier_chen_penitence") then
		totalDmg = totalDmg * 1.36
	end
	if NPC.HasModifier(myHero, "modifier_bloodseeker_bloodrage") then
		totalDmg = totalDmg * 1.4
	end
	if NPC.HasModifier(target,"modifier_item_hood_of_defiance_barrier") then 
		totalDmg = totalDmg - 325
	end
	if NPC.HasModifier(target,"modifier_item_pipe_barrier") then 
		totalDmg = totalDmg - 400
	end
	if NPC.HasModifier(target,"modifier_ember_spirit_flame_guard") then 
		totalDmg = totalDmg - 500
	end
	return totalDmg
end

function morph.OnDraw()
	if morph.myHero == nil or NPC.GetUnitName(morph.myHero) ~= "npc_dota_hero_morphling" then return end
	local autoKillMode
	local x, y = Renderer.GetScreenSize()
	local x1, y1
	if x == 1920 and y == 1080 then
		x, y = 1150, 910
	elseif x== 1600 and y == 900 then
		x, y = 950, 755
	elseif x== 1366 and y == 768 then
		x, y = 805, 643
	elseif x==1280 and y == 720 then
		x, y = 752, 600
	elseif x==1280 and y == 1024 then
		x, y = 800, 860
	elseif x==1440 and y == 900 then
		x, y = 870, 755
	elseif x== 1680 and y == 1050 then
		x, y = 1025, 885
	end
	x1 = x
	y1 = y-20
	if Menu.IsEnabled(morph.AutoKill)  then
		Renderer.SetDrawColor(255, 255, 0)
		autoKillMode = "ON"		
	else
		Renderer.SetDrawColor(255, 0, 0)
		autoKillMode = "OFF"
		morph.localDmg = 0
	end
	local customResist = (100-Menu.GetValue(morph.customResist)-1)/100
	Renderer.DrawText(Font, x, y, "AutoKill: ["..autoKillMode.."]")
	Renderer.DrawText(Font, x1, y1, "Damage: ["..math.floor(morph.localDmg*customResist).."]")
end

return morph