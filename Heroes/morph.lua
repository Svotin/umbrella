local Utility = require("scripts/Utility")
local morph = {}

morph.optionEnable = Menu.AddOptionBool({"Hero Specific", "Morph"}, "Enable", false)
morph.AutoShift = Menu.AddOptionBool({"Hero Specific", "Morph","AutoShift"}, "Enable", false)
morph.AdditionalAbilities = Menu.AddOptionBool({"Hero Specific", "Morph","AutoShift"}, "[unstable]additionalAbilities", false)
morph.AutoKill = Menu.AddOptionBool({"Hero Specific", "Morph", "EBladeAutoKill"}, "Enable", false)

morph.myHero = nil
morph.players = {}
morph.ability = {}


morph.defaultAbilities = {
	{"npc_dota_hero_axe", "axe_berserkers_call", 300},
	{"npc_dota_hero_tidehunter", "tidehunter_ravage", 1250},
	{"npc_dota_hero_enigma", "enigma_black_hole", 720},
	{"npc_dota_hero_magnataur", "magnataur_reverse_polarity", 430},
	{"npc_dota_hero_slardar", "slardar_slithereen_crush", 355},
	{"npc_dota_hero_centaur", "centaur_hoof_stomp", 345}

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
	{"npc_dota_hero_axe", "axe_berserkers_call", 300},
	{"npc_dota_hero_tidehunter", "tidehunter_ravage", 1250},
	{"npc_dota_hero_enigma", "enigma_black_hole", 720},
	{"npc_dota_hero_magnataur", "magnataur_reverse_polarity", 430},
	{"npc_dota_hero_slardar", "slardar_slithereen_crush", 355},
	{"npc_dota_hero_centaur", "centaur_hoof_stomp", 345},

	--------------------------------------------------------------------

	{"npc_dota_hero_batrider", "batrider_flaming_lasso", 170},
	{"npc_dota_hero_faceless_void", "faceless_void_chronosphere", 1100},
	{"npc_dota_hero_legion_commander", "legion_commander_duel", 150},
	{"npc_dota_hero_pudge", "pudge_dismember", 160}
}


function morph.OnUpdate()
	if not Menu.IsEnabled(morph.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then 
		for i = 0, 10 do
      		if morph.players[i] then
        		Menu.RemoveOption(morph.players[i]) 
        		morph.players[i] = nil
      end
    end
		return end
	morph.myHero = Heroes.GetLocal()
	if NPC.GetUnitName(morph.myHero) ~= "npc_dota_hero_morphling" then return end
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
   		if eblade and Ability.IsReady(strike) and Ability.IsReady(eblade) then
   			local agility = Hero.GetAgilityTotal(morph.myHero)
   			local strenght = Hero.GetStrengthTotal(morph.myHero)
   			local intellect = Hero.GetIntellectTotal(morph.myHero)
   			local strikeDmg =  getStrikeDmg(agility, strenght)
   			local ebladeDmg = 75 + (2 * agility)
   			local intMultiplier = ((0.069 * intellect) / 100) + 1
   			for _,hero in pairs(FHeroes) do
				if hero ~= nil and hero ~= 0 and NPCs.Contains(hero) and NPC.IsEntityInRange(morph.myHero, hero,Ability.GetCastRange(eblade)) and NPC.IsEntityInRange(morph.myHero, hero,Ability.GetCastRange(strike)) and not Entity.IsSameTeam(hero,morph.myHero) then
					if Entity.IsAlive(hero) and not Entity.IsDormant(hero) and not NPC.IsIllusion(hero) and Menu.IsEnabled(morph.players[Hero.GetPlayerID(hero)]) and morph.IsHasGuard(hero)=="nil"  then
						local localDmg = ((strikeDmg+ebladeDmg)*1.4)*intMultiplier
						local totalDmg = morph.GetTotalDmg(hero, localDmg, morph.myHero)-2
						-- if Entity.GetHealth(hero) <= strikeDmg*intMultiplier and Ability.GetManaCost(strike) <= NPC.GetMana(morph.myHero) then
						-- 		Ability.CastTarget(strike, hero)
						-- 		return
						if Entity.GetHealth(hero) <= totalDmg and (Ability.GetManaCost(strike)+Ability.GetManaCost(eblade)) <= NPC.GetMana(morph.myHero) then
							Ability.CastTarget(eblade, hero)
							Ability.CastTarget(strike, hero)
							return
						end
					end
				end
			end
		end
   	end
end
function getStrikeDmg(agility, strenght)
	local strikeDmg = 0
	local damageMultiplier = 0.5
	local totalAttributies = agility + strenght
	if (totalAttributies/100*75 < agility) then 
		damageMultiplier = 2.5
	end
	strikeDmg = 100 + agility*damageMultiplier
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
	local mana_shield = NPC.GetAbility(target, "medusa_mana_shield")
	if mana_shield and Ability.GetToggleState(mana_shield) then
			totalDmg = totalDmg * 0.4
	end
	if NPC.HasModifier(target,"modifier_ursa_enrage") then
		totalDmg = totalDmg * 0.2
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
	if NPC.HasModifier(target,"modifier_item_hood_of_defiance_barrier") then --НЕ РАБОТАЕТ, ПОДОЖДУ ПОКА ДРУГИЕ СДЕЛАЮТ И СПИЗЖУ!
		totalDmg = totalDmg - 400
	end
	return totalDmg
end

return morph