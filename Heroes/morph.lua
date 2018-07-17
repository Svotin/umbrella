local Morphling = {}

Morphling.optionEnable = Menu.AddOptionBool({"Hero Specific", "Morphling"}, "Enable", false)
Morphling.optionIcon = Menu.AddOptionIcon({ "Hero Specific", "Morphling" }, "panorama/images/heroes/icons/npc_dota_hero_morphling_png.vtex_c")
Morphling.maxWaveRange =  Menu.AddOptionBool({"Hero Specific", "Morphling"}, "Max Waveform Range", false)
Morphling.AutoKill = Menu.AddOptionBool({"Hero Specific", "Morphling", "EBlade Auto Kill"}, "Enable", false)
Morphling.AutoKillKey = Menu.AddKeyOption({"Hero Specific",  "Morphling", "EBlade Auto Kill"}, "Toggle Key", Enum.ButtonCode.KEY_0)
Morphling.QOP = Menu.AddOptionBool({"Hero Specific",  "Morphling", "EBlade Auto Kill"}, "QOP has Level 25: 15s Spell Block?", false)
Morphling.Display = Menu.AddOptionBool({"Hero Specific", "Morphling"}, "Damage Info", false)
Morphling.AutoShift = Menu.AddOptionBool({"Hero Specific", "Morphling","Auto Shift"}, "Enable", false)
Morphling.optionHeroMorphHPBalanceDeviation = Menu.AddOptionSlider({"Hero Specific", "Morphling", "Auto Shift" }, "HP Deviation", 50, 250, 50)

Morphling.AutoShiftKey = Menu.AddKeyOption({"Hero Specific",  "Morphling", "Auto Shift"}, "Toggle Key", Enum.ButtonCode.KEY_8)
Morphling.optionHeroMorphDrawBoardXPos = Menu.AddOptionSlider({ "Hero Specific", "Morphling","Auto Shift" }, "X-Pos Adjustment", -500, 1500, 10)
Morphling.optionHeroMorphDrawBoardYPos = Menu.AddOptionSlider({ "Hero Specific", "Morphling","Auto Shift"}, "Y-Pos Adjustment", -500, 760, 10)

Morphling.AutoShiftBeforeGetStunned = Menu.AddOptionBool({"Hero Specific", "Morphling", "Auto Shift"}, "Auto Shift Before Get Stunned", false) 
Morphling.AutoShiftBeforeGetStunnedAdd = Menu.AddOptionBool({"Hero Specific", "Morphling", "Auto Shift"}, "Add unstable abilities", false) 

Morphling.replicateBack = Menu.AddOptionBool({"Hero Specific", "Morphling"}, "Auto Replicate Back", false)
Morphling.ReplicateBackHP = Menu.AddOptionSlider({"Hero Specific", "Morphling"}, "Replicate Back HP Treshold", 5, 40, 5)


Morphling.myHero = nil
Morphling.players = { { } }
Morphling.players_mark = {}
local Font = Renderer.LoadFont("Tahoma", 20, Enum.FontWeight.BOLD)
local FontForStatus = Renderer.LoadFont("Tahoma", 17, Enum.FontWeight.BOLD)
Morphling.localDmg = 0
Morphling.Toggler = true
Morphling.lastTick = {[0] = 0, [1] = 0}
Morphling.MorphBalanceToggler = true
Morphling.MorphBalanceTimer = 0
Morphling.MorphBalanceSelectedHP = 0
Morphling.MorphBalanceSelected = 0
local castRange = 0
local ebladeDmg = 0
local strikeDmg = 0
local indexes = {}

Morphling.dangerousAnimation = {
	{"crush_anim", 355, false},
	{"cast_hoofstomp_anim", 345, false},
	{"polarity_anim", 430, true},
	{"ravage_anim", 1250, false},
	{"cast4_black_hole_anim", 720, true},
	{"fissure_anim", 300, false},
	{"enchant_totem_anim", 300, false},
	{"chronosphere_anim", 1100, false}
}

Morphling.projectileAbilities = {	
	{"npc_dota_hero_alchemist", "alchemist_unstable_concoction_projectile"},	
	{"npc_dota_hero_sven", "sven_spell_storm_bolt"},	
	{"npc_dota_hero_chaos_knight", "chaos_knight_chaos_bolt"},	
	{"npc_dota_hero_skeleton_king", "skeletonking_hellfireblast"},	
	{"npc_dota_hero_vengefulspirit", "vengeful_magic_missle"},	
	{"npc_dota_hero_dragon_knight", "dragon_knight_dragon_tail_dragonform_proj"},	
	{"npc_dota_hero_windrunner", "windrunner_shackleshot"}	
}

Morphling.additionalAbilities = {	
	{"lasso_start_anim", 170},	
	{"legion_commander_duel_anim", 150},	
	{"pudge_dismember_start", 160},	
	{"cast_doom_anim", 650},	
	{"fiends_grip_cast_anim", 625},	
	{"cast4_primal_roar_anim", 600},	
}



function Morphling.Zeroing()
	Morphling.myHero = nil
	Morphling.players = { { } }
	Morphling.players_mark = {}
	Font = Renderer.LoadFont("Tahoma", 20, Enum.FontWeight.BOLD)
	FontForStatus = Renderer.LoadFont("Tahoma", 17, Enum.FontWeight.BOLD)
	Morphling.localDmg = 0
	Morphling.Toggler = true
	Morphling.lastTick = {[0] = 0, [1] = 0}
	Morphling.MorphBalanceToggler = true
	Morphling.MorphBalanceTimer = 0
	Morphling.MorphBalanceSelectedHP = 0
	Morphling.MorphBalanceSelected = 0
	castRange = 0
	ebladeDmg = 0
	strikeDmg = 0
	indexes = {}
end

function Morphling.OnGameStart()
	Morphling.Zeroing()
end

function Morphling.OnGameEnd()
	Morphling.Zeroing()
end

function Morphling.OnUnitAnimation(a)
	if not Menu.IsEnabled(Morphling.AutoShiftBeforeGetStunned) or not Menu.IsEnabled(Morphling.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	Morphling.myHero = Heroes.GetLocal()	
	if Morphling.myHero == nil or NPC.GetUnitName(Morphling.myHero) ~= "npc_dota_hero_morphling" then return end 	
	if Entity.IsSameTeam(a.unit,Morphling.myHero) then return end 
	for i=1, #Morphling.dangerousAnimation do
		if Morphling.dangerousAnimation[i][1] == a.sequenceName then
			if NPC.IsEntityInRange(Morphling.myHero, a.unit, Morphling.dangerousAnimation[i][2]) then  	
				if NPC.HasState(Morphling.myHero,Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) and not Morphling.dangerousAnimation[i][3] then 	
					return 	
				end	
				Morphling.toggleShift(Morphling.myHero)	
				return
			end
		end
	end
	if Menu.IsEnabled(Morphling.AutoShiftBeforeGetStunnedAdd) then
		for i=1, #Morphling.additionalAbilities do
			if Morphling.additionalAbilities[i][1] == a.sequenceName then
				if NPC.IsLinkensProtected(Morphling.myHero) then return end
				if NPC.IsEntityInRange(Morphling.myHero, a.unit, Morphling.additionalAbilities[i][2]) and NPC.FindFacingNPC(a.unit)==Morphling.myHero then  	
					Morphling.toggleShift(Morphling.myHero)	
					return
				end
			end
		end
	end
end


function Morphling.OnUpdate()
	if not Menu.IsEnabled(Morphling.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then 
		for i = 1, Heroes.Count(), 1 do
			local hero = Heroes.Get(i)
      		if Morphling.players_mark[Hero.GetPlayerID(hero)] then
        		Menu.RemoveOption(Morphling.players[Hero.GetPlayerID(hero)][0]) 
        		Morphling.players[Hero.GetPlayerID(hero)][0] = nil
        		Morphling.players[Hero.GetPlayerID(hero)][1] = nil
        		Morphling.players[Hero.GetPlayerID(hero)][2] = nil
        		Morphling.players[Hero.GetPlayerID(hero)][3] = nil
        		Morphling.players_mark[Hero.GetPlayerID(hero)] = false
        		indexes = {}
     		end
    	end 
    	Morphling.myHero = nil
		Morphling.players = { { } }
		Morphling.players_mark = {}
    	return 
    end
	Morphling.myHero = Heroes.GetLocal()
	if NPC.GetUnitName(Morphling.myHero) ~= "npc_dota_hero_morphling" then return end
---- AUTO SHIFT BORD MOVING ----
if Menu.IsEnabled(Morphling.AutoShift) then
	if Input.IsKeyDown(Enum.ButtonCode.KEY_LEFT) and Menu.GetValue(Morphling.optionHeroMorphDrawBoardXPos) < 1495 then
		Menu.SetValue(Morphling.optionHeroMorphDrawBoardXPos, (Menu.GetValue(Morphling.optionHeroMorphDrawBoardXPos)+5))
	elseif Input.IsKeyDown(Enum.ButtonCode.KEY_RIGHT) and Menu.GetValue(Morphling.optionHeroMorphDrawBoardXPos) > -495 then
		Menu.SetValue(Morphling.optionHeroMorphDrawBoardXPos, (Menu.GetValue(Morphling.optionHeroMorphDrawBoardXPos)-5))
	elseif Input.IsKeyDown(Enum.ButtonCode.KEY_UP) and Menu.GetValue(Morphling.optionHeroMorphDrawBoardYPos) > -496 then
		Menu.SetValue(Morphling.optionHeroMorphDrawBoardYPos, (Menu.GetValue(Morphling.optionHeroMorphDrawBoardYPos)-4))
	elseif Input.IsKeyDown(Enum.ButtonCode.KEY_DOWN) and Menu.GetValue(Morphling.optionHeroMorphDrawBoardYPos) < 756 then
		Menu.SetValue(Morphling.optionHeroMorphDrawBoardYPos, (Menu.GetValue(Morphling.optionHeroMorphDrawBoardYPos)+4))
	end
end
-----------------------TOGGLERS------------------------------

	if Menu.IsKeyDownOnce(Morphling.AutoShiftKey) then
		if Menu.IsEnabled(Morphling.AutoShift) then
			Menu.SetEnabled(Morphling.AutoShift, false)
		else 
			Menu.SetEnabled(Morphling.AutoShift, true)
			Menu.SetEnabled(Morphling.AutoShiftBeforeGetStunned, false)
		end		
	end
-------------------------------------------------------------
	if Menu.IsKeyDownOnce(Morphling.AutoKillKey) then
		if Menu.IsEnabled(Morphling.AutoKill) then
			Menu.SetEnabled(Morphling.AutoKill, false)
		else 
			Menu.SetEnabled(Morphling.AutoKill, true)
		end		
	end
-------------------------------------------------------------
	if Menu.IsEnabled(Morphling.AutoShift) then
		Morphling.MorphBalaceHP(Morphling.myHero)
	end

	if Menu.IsEnabled(Morphling.AutoShiftBeforeGetStunned) then
		if Entity.IsAlive(Morphling.myHero) and not NPC.IsStunned(Morphling.myHero) and not NPC.IsSilenced(Morphling.myHero) then 
			local heroes = Entity.GetUnitsInRadius(Morphling.myHero, 300, Enum.TeamType.TEAM_ENEMY)
			if heroes and #heroes>0 then
				local shift = NPC.GetAbilityByIndex(Morphling.myHero, 4)
				for i=1, #heroes do
					if heroes[i] and Entity.IsAlive(heroes[i]) and not Entity.IsSameTeam(Morphling.myHero, heroes[i]) then
						if NPC.GetUnitName(heroes[i]) == "npc_dota_hero_axe" then
							local p1 = NPC.GetAbility(heroes[i], "axe_berserkers_call")
							if p1 ~= (nil or 0) and Ability.IsInAbilityPhase(p1) then								 
								Morphling.toggleShift(Morphling.myHero)
								return
							end
						end
					end
				end	
			end
		end
	end

	if Menu.IsEnabled(Morphling.replicateBack) then
		local replicate = NPC.GetAbility(Morphling.myHero, "morphling_morph_replicate")
		if replicate and not Ability.IsHidden(replicate) and Ability.IsReady(replicate) then
			if Entity.IsAlive(Morphling.myHero) and not NPC.IsStunned(Morphling.myHero) and not NPC.IsSilenced(Morphling.myHero) then 
				if Entity.GetHealth(Morphling.myHero) / Entity.GetMaxHealth(Morphling.myHero) < Menu.GetValue(Morphling.ReplicateBackHP) / 100 then
					Ability.CastNoTarget(replicate)
					return
				end
			end
		end
	end

	if Menu.IsEnabled(Morphling.AutoKill) or Menu.IsEnabled(Morphling.Display) then
		for i = 1, Heroes.Count(), 1 do
   			local hero = Heroes.Get(i)
   			if not Entity.IsSameTeam(Morphling.myHero, hero) and hero ~= Morphling.myHero and not Morphling.players_mark[Hero.GetPlayerID(hero)] then 
   				Morphling.players[Hero.GetPlayerID(hero)] = {}
   				Morphling.players[Hero.GetPlayerID(hero)][0] = Menu.AddOptionBool({"Hero Specific", "Morphling", "EBlade Auto Kill"}, string.upper(string.sub(NPC.GetUnitName(hero), 15)), true)
   				Morphling.players[Hero.GetPlayerID(hero)][1] = hero
   				Morphling.players[Hero.GetPlayerID(hero)][2] = 0 -- total damage
   				Morphling.players[Hero.GetPlayerID(hero)][3] = 0 -- ethereal blade damage only
   				Morphling.players_mark[Hero.GetPlayerID(hero)] = true
   				indexes[#indexes+1] = Hero.GetPlayerID(hero)
   				return
   			end
   		end 
   	end
   	if Menu.IsEnabled(Morphling.AutoKill) or Menu.IsEnabled(Morphling.Display) then
   		local strike = NPC.GetAbilityByIndex(Morphling.myHero, 1)
   		local eblade = NPC.GetItem(Morphling.myHero, "item_ethereal_blade", true)
   		if Morphling.SleepReady(0.2, 1) then
   			Morphling.init_heroes_dmg(Morphling.myHero, eblade, strike)
   			Morphling.lastTick[1] = os.clock()
   		end
   		if not Morphling.SleepReady(1.0, 0) then return end
   		if not Entity.IsAlive(Morphling.myHero) or not Menu.IsEnabled(Morphling.AutoKill) then return end
   		local heroes = Entity.GetHeroesInRadius(Morphling.myHero, castRange, Enum.TeamType.TEAM_ENEMY)
   		if not heroes or #heroes < 1 then return end
   		for i=1, #heroes do
			if Entity.GetHealth(heroes[i])+NPC.GetHealthRegen(heroes[i]) <= Morphling.players[Hero.GetPlayerID(heroes[i])][3] then
				if ebladeDmg > 0 then
					Ability.CastTarget(eblade, heroes[i])
					Morphling.lastTick[0] = os.clock()
					break
				end
				return
			elseif Entity.GetHealth(heroes[i]) + NPC.GetHealthRegen(heroes[i]) <= Morphling.players[Hero.GetPlayerID(heroes[i])][2] then 
				if ebladeDmg > 0 then
					Ability.CastTarget(eblade, heroes[i])
				end
				if strikeDmg > 0 then 
					Ability.CastTarget(strike, heroes[i])
					break
				end 
				return
			end
		end
	end
end

function Morphling.init_heroes_dmg(myHero, eblade, strike)
	local agility = Hero.GetAgilityTotal(myHero)
	local strenght = Hero.GetStrengthTotal(myHero)
	local intellect = Hero.GetIntellectTotal(myHero)
	strikeDmg =  Morphling.getStrikeDmg(agility, strenght, strike)
	local totalMana = 0
	castRange = 0
	local ebladeMultiplier = 1
	ebladeDmg = 0
	if strikeDmg ~= 0 then 
		if Ability.GetManaCost(strike) <= NPC.GetMana(myHero) then
			totalMana = totalMana + Ability.GetManaCost(strike)
			castRange = Ability.GetCastRange(strike)
		end
	end
	if eblade and Ability.IsReady(eblade) then
		if Ability.GetManaCost(eblade)+totalMana <= NPC.GetMana(myHero) then
			ebladeMultiplier = 1.4
			ebladeDmg = 75 + (2 * agility)
			totalMana = totalMana + Ability.GetManaCost(eblade)
			castRange = Ability.GetCastRange(eblade)
		end
	end
	if ebladeDmg == 0 and strikeDmg == 0 then  Morphling.localDmg = 0 return end
	local intMultiplier = ((0.069 * intellect) / 100) + 1
	Morphling.localDmg = ((strikeDmg+ebladeDmg)*ebladeMultiplier)*intMultiplier
	local ebladeOnly = ebladeDmg*intMultiplier*ebladeMultiplier
	if not Menu.IsEnabled(Morphling.AutoKill)  then return end
	for i=1, #indexes do
		if Morphling.players[indexes[i]][1] and Morphling.players[indexes[i]][1] ~= 0 and Heroes.Contains(Morphling.players[indexes[i]][1])
			and Entity.IsAlive(Morphling.players[indexes[i]][1]) and not Entity.IsDormant(Morphling.players[indexes[i]][1]) and Menu.IsEnabled(Morphling.players[indexes[i]][0]) and Morphling.IsHasGuard(Morphling.players[indexes[i]][1])=="nil" then
				local totalDmg = Morphling.GetTotalDmg(Morphling.players[indexes[i]][1], Morphling.localDmg, myHero) - 2
				Morphling.players[indexes[i]][2] = totalDmg
				local ebladeTotal = Morphling.GetTotalDmg(Morphling.players[indexes[i]][1], ebladeOnly, myHero) - 2	
				Morphling.players[indexes[i]][3] = ebladeTotal
		else
			Morphling.players[indexes[i]][2] = 0
			Morphling.players[indexes[i]][3] = 0
		end
	end
end

function Morphling.getStrikeDmg(agility, strenght, strike)
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


function Morphling.IsHasGuard(npc) 
	local guarditis = "nil"
	if NPC.IsLinkensProtected(npc) then guarditis = "Linkens" end
	if NPC.HasModifier(npc,"modifier_item_blade_mail_reflect") then guarditis = "BM" end
	local spell_shield = NPC.GetAbility(npc, "antimage_spell_shield")
	if spell_shield and Ability.GetLevel(spell_shield)>0 and Ability.IsReady(spell_shield) and (NPC.HasModifier(npc, "modifier_item_ultimate_scepter") or NPC.HasModifier(npc, "modifier_item_ultimate_scepter_consumed")) 
	and not NPC.HasModifier(npc,"modifier_silver_edge_debuff") and not NPC.HasModifier(npc,"modifier_viper_nethertoxin") then
		guarditis = "Lotus"
	end
	local abaddonUlt = NPC.GetAbility(npc, "abaddon_borrowed_time")
	if abaddonUlt and Ability.GetLevel(abaddonUlt)>0 then
			if (Ability.IsReady(abaddonUlt)) then
				if NPC.HasModifier(npc,"modifier_silver_edge_debuff") or NPC.HasModifier(npc,"modifier_viper_nethertoxin") then 
					guarditis = "nil"
				else
					guarditis = "Immune"
				end
			elseif Ability.SecondsSinceLastUse(abaddonUlt)<=1 then --рот ебал этого казино, он даёт прокаст, когда абилка уже в кд, а модификатора ещё нет.
				guarditis = "Immune"
			end
	end
	if Menu.IsEnabled(Morphling.QOP) then
		if NPC.GetCurrentLevel(npc) == 25 and NPC.GetAbility(npc,"special_bonus_unique_queen_of_pain") then 
			guarditis = "Linkens"
		end
	end
	if NPC.HasModifier(npc,"modifier_item_lotus_orb_active") then guarditis = "Lotus" end
	if 	NPC.HasState(npc,Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) or 
		NPC.HasState(npc,Enum.ModifierState.MODIFIER_STATE_OUT_OF_GAME) or
		NPC.HasModifier(npc,"modifier_medusa_stone_gaze_stone") or
		NPC.HasModifier(npc,"modifier_winter_wyvern_winters_curse") or
		NPC.HasModifier(npc,"modifier_winter_wyvern_winters_curse_aura") or
		NPC.HasModifier(npc,"modifier_templar_assassin_refraction_absorb") or
		NPC.HasModifier(npc,"modifier_nyx_assassin_spiked_carapace") or
		NPC.HasModifier(npc,"modifier_item_aeon_disk_buff") or
		NPC.HasModifier(npc,"modifier_abaddon_borrowed_time") or
		NPC.HasModifier(npc,"modifier_dark_willow_shadow_realm_buff") or
		NPC.HasModifier(npc,"modifier_dazzle_shallow_grave") or 
		NPC.HasModifier(npc,"modifier_special_bonus_spell_block") or
		NPC.HasModifier(npc,"modifier_skeleton_king_reincarnation_scepter_active") or
		NPC.HasModifier(npc,"modifier_eul_cyclone") or
		NPC.HasModifier(npc,"modifier_brewmaster_storm_cyclone") or 
		NPC.HasModifier(npc,"modifier_clinkz_strafe") then	
			guarditis = "Immune"
	end

	if NPC.HasModifier(npc,"modifier_legion_commander_duel") then
		local duel = Modifier.GetAbility(NPC.GetModifier(npc, "modifier_legion_commander_duel")) 
		if duel and duel ~= 0 then
			if NPC.HasModifier(Ability.GetOwner(duel), "modifier_item_ultimate_scepter") or NPC.HasModifier(Ability.GetOwner(duel), "modifier_item_ultimate_scepter_consumed") then
				guarditis = "Immune"
			end
		end
	end

	local aeon_disk = NPC.GetItem(npc, "item_aeon_disk")
	if aeon_disk and (Ability.IsReady(aeon_disk) or Ability.SecondsSinceLastUse(aeon_disk)<=1) then guarditis = "Immune" end --тоже казино, что и с абаддоном
	return guarditis
end

function Morphling.GetTotalDmg(target,dmg, myHero)
	if not target or not myHero then return end
	local totalDmg = (dmg * NPC.GetMagicalArmorDamageMultiplier(target))
	local rainDrop = NPC.GetItem(target, "item_infused_raindrop", true)
	if rainDrop and Ability.IsReady(rainDrop) then
		totalDmg = totalDmg - 120
	end
	local kaya = NPC.GetItem(myHero, "item_kaya", true)
	if kaya then 
		totalDmg = totalDmg * 1.1 
	end

	if NPC.HasModifier(target, "modifier_ember_spirit_flame_guard") then 
		local guard = NPC.GetAbility(target, "ember_spirit_flame_guard")
		if guard and guard~=0 then
			totalDmg = totalDmg - Ability.GetLevelSpecialValueFor(guard, "absorb_amount")
			local talant = NPC.GetAbility(target, "special_bonus_unique_ember_spirit_1")
			if talant and talant~=0 and Ability.GetLevel(talant) ~= 0 then
				totalDmg = totalDmg - Ability.GetLevelSpecialValueFor(talant, "value")
			end
		end
	end

	if NPC.HasModifier(target,"modifier_abaddon_aphotic_shield") then 
		local shield = Modifier.GetAbility(NPC.GetModifier(target, "modifier_abaddon_aphotic_shield"))
		if shield and shield ~= 0 then
			totalDmg = totalDmg - Ability.GetLevelSpecialValueForFloat(shield, "damage_absorb")
			local talant = NPC.GetAbility(Ability.GetOwner(shield), "special_bonus_unique_abaddon")
			if talant and talant~=0 and Ability.GetLevel(talant) ~= 0 then
				totalDmg = totalDmg - Ability.GetLevelSpecialValueFor(talant, "value")
			end
		end
	end	

	if NPC.HasModifier(target,"modifier_item_hood_of_defiance_barrier") then 
		totalDmg = totalDmg - 325
	end

	if NPC.HasModifier(target,"modifier_item_pipe_barrier") then 
		totalDmg = totalDmg - 400
	end

	local mana_shield = NPC.GetAbility(target, "medusa_mana_shield") 

	if mana_shield and Ability.GetToggleState(mana_shield) then
		totalDmg = totalDmg * 0.4
	end

	if NPC.HasModifier(target,"modifier_nyx_assassin_burrow") then
		totalDmg = totalDmg * 0.6
	end

	if NPC.HasModifier(target,"modifier_ursa_enrage") then
		totalDmg = totalDmg * 0.2
	end

	local dispersion = NPC.GetAbility(target, "spectre_dispersion")
	if dispersion and dispersion ~= 0 and Ability.GetLevel(dispersion) > 0 then
		totalDmg = totalDmg * ((100 - Ability.GetLevelSpecialValueFor(dispersion, "damage_reflection_pct"))/100)
		local talant = NPC.GetAbility(target, "special_bonus_unique_spectre_5")
		if talant and talant~=0 and Ability.GetLevel(talant) ~= 0 then
			totalDmg = totalDmg * ((100 - Ability.GetLevelSpecialValueFor(talant, "value"))/100)
		end
	end

	if NPC.HasModifier(target, "modifier_wisp_overcharge") then 
		local overcharge = Modifier.GetAbility(NPC.GetModifier(target, "modifier_wisp_overcharge")) 
		if overcharge and overcharge ~= 0 then
			totalDmg = totalDmg * ((100 + Ability.GetLevelSpecialValueForFloat(overcharge, "bonus_damage_pct"))/100)
		end
	end

	local bristleback = NPC.GetAbility(target, "bristleback_bristleback")
	if bristleback and bristleback ~= 0 and Ability.GetLevel(bristleback) > 0 then
		totalDmg = totalDmg * ((100 - Ability.GetLevelSpecialValueFor(bristleback, "back_damage_reduction"))/100)
	end

	if NPC.HasModifier(target,"modifier_bloodseeker_bloodrage") then
		local bloodrage = Modifier.GetAbility(NPC.GetModifier(target, "modifier_bloodseeker_bloodrage")) 
		if bloodrage and bloodrage ~= 0 then
			totalDmg = totalDmg * ((100 + Ability.GetLevelSpecialValueForFloat(bloodrage, "damage_increase_pct"))/100)
		end
	end

	if NPC.HasModifier(target,"modifier_chen_penitence") then
		local penis = Modifier.GetAbility(NPC.GetModifier(target, "modifier_chen_penitence")) 
		if penis and penis ~= 0 then
			totalDmg = totalDmg * ((100 + Ability.GetLevelSpecialValueForFloat(penis, "bonus_damage_taken"))/100)
		end
	end

	if NPC.HasModifier(myHero, "modifier_bloodseeker_bloodrage") then
		local bloodrage = Modifier.GetAbility(NPC.GetModifier(myHero, "modifier_bloodseeker_bloodrage")) 
		if bloodrage and bloodrage ~= 0 then
			totalDmg = totalDmg * ((100 + Ability.GetLevelSpecialValueForFloat(bloodrage, "damage_increase_pct"))/100)
		end
	end

	local pangoCrash = NPC.GetModifier(target, "modifier_pangolier_shield_crash_buff")
	if pangoCrash and pangoCrash ~= 0 then
		local pangoStack = Modifier.GetStackCount(pangoCrash)
		totalDmg = totalDmg*((100 - pangoStack)/100)
	end

	local visageCloak = NPC.GetModifier(target, "modifier_visage_gravekeepers_cloak")
	if visageCloak and visageCloak ~= 0 then
		local visageStack = Modifier.GetStackCount(visageCloak)
		totalDmg = totalDmg * (1 - (0.2*visageStack))
	end

	if NPC.HasModifier(target, "modifier_kunkka_ghost_ship_damage_absorb") then
		local ghostShip = Modifier.GetAbility(NPC.GetModifier(target, "modifier_kunkka_ghost_ship_damage_absorb")) 
		if ghostShip and ghostShip ~= 0 then
			totalDmg = totalDmg * ((100 - Ability.GetLevelSpecialValueForFloat(ghostShip, "ghostship_absorb"))/100)
		end
	end

	if NPC.HasModifier(target, "modifier_shadow_demon_soul_catcher") then
		local soulCatcherLvl = Ability.GetLevel(Modifier.GetAbility(NPC.GetModifier(target, "modifier_shadow_demon_soul_catcher")))
		totalDmg = totalDmg * (1.1 + (0.1 * soulCatcherLvl))
	end
	return totalDmg
end

function Morphling.OnDraw()
	if not Menu.IsEnabled(Morphling.optionEnable) then return end
	if Morphling.myHero == nil or NPC.GetUnitName(Morphling.myHero) ~= "npc_dota_hero_morphling" then return end
	local autoKillMode
	x, y = 1150, 910
	if Menu.IsEnabled(Morphling.AutoKill)  then
		Renderer.SetDrawColor(255, 255, 0)
		autoKillMode = "ON"		
	else
		Renderer.SetDrawColor(255, 0, 0)
		autoKillMode = "OFF"
	end
	Renderer.DrawText(Font, x, y, "AutoKill: ["..autoKillMode.."]")
	---- Damage Info ----
	if Menu.IsEnabled(Morphling.Display) then
   		local nearHero = Input.GetNearestHeroToCursor(Entity.GetTeamNum(Morphling.myHero), Enum.TeamType.TEAM_ENEMY)
	   	if nearHero then  
		   	if not NPC.IsPositionInRange(nearHero, Input.GetWorldCursorPos(), 450, 0) then nearHero = 0 end
				for i=1,#indexes do
				if Morphling.players[indexes[i]] and Morphling.players[indexes[i]][1] ~= nil and Morphling.players[indexes[i]][1] ~= 0 and Heroes.Contains(Morphling.players[indexes[i]][1]) and Entity.IsAlive(Morphling.players[indexes[i]][1]) and not Entity.IsDormant(Morphling.players[indexes[i]][1])
					and (NPC.IsEntityInRange(Morphling.myHero, Morphling.players[indexes[i]][1], 2000) or (Morphling.players[indexes[i]][1] == nearHero)) then
						local totalDmg = Morphling.players[indexes[i]][2]
						local dmg = Entity.GetHealth(Morphling.players[indexes[i]][1]) - totalDmg 

						if dmg > 0 then
							Renderer.SetDrawColor(255, 0, 0)
						else
							Renderer.SetDrawColor(90, 255, 100)
						end
						local pos = Entity.GetAbsOrigin(Morphling.players[indexes[i]][1])
			            local x, y, visible = Renderer.WorldToScreen(pos)

			            if visible and pos then
			                Renderer.DrawText(FontForStatus, x, y-12, math.abs(math.floor(dmg)), 1)
			            end
				end
			end
		end
	end
	if Menu.IsEnabled(Morphling.AutoShift) then
			Morphling.MorphDrawBalanceBoard(Morphling.myHero)
	end
end


function  Morphling.toggleShift(myHero)
	local shift = NPC.GetAbilityByIndex(myHero, 4)
	if not shift then return end
	if not Ability.GetToggleState(shift) then
		Ability.Toggle(shift)
				return
	end
end

function Morphling.OnProjectile(projectile)	
	Morphling.myHero = Heroes.GetLocal()	
	if Morphling.myHero == nil or NPC.GetUnitName(Morphling.myHero) ~= "npc_dota_hero_morphling" then return end 	
	if not Menu.IsEnabled(Morphling.AutoShiftBeforeGetStunned) or not Menu.IsEnabled(Morphling.optionEnable) or not projectile.target or Entity.IsSameTeam(projectile.source, Morphling.myHero) then return end		
	local source = nil	
	if projectile.source and projectile.source~=0 then	
		source = NPC.GetUnitName(projectile.source)	
	else return end
	if projectile.target ~= Morphling.myHero then return end
	local name = projectile.name	
	for k,hero in pairs(Morphling.projectileAbilities) do	
		if source == hero[1] and name == hero[2] and not NPC.IsLinkensProtected(Morphling.myHero) then	
			Morphling.toggleShift(Morphling.myHero)	
			return	
		end 	
	end	 		
 end

function Morphling.OnPrepareUnitOrders(orders) --xenohack
	if not orders then return true end
	if not Menu.IsEnabled(Morphling.maxWaveRange) then return true end
	
	if not orders.order or orders.order ~= Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION then return true end
	if not orders.npc or orders.npc == 0 or NPC.GetUnitName(orders.npc) ~= "npc_dota_hero_morphling" then return true end
	if not orders.ability or not Entity.IsAbility(orders.ability) or Ability.GetName(orders.ability) ~= "morphling_waveform" then return true end

	local castRange = Ability.GetCastRange(orders.ability)
	if NPC.IsPositionInRange(orders.npc, orders.position, castRange, 0) then return true end
	
    local origin = Entity.GetAbsOrigin(orders.npc)
    local dir = orders.position - origin

    dir:SetZ(0)
    dir:Normalize()
    dir:Scale(castRange - 1)

    local pos = origin + dir

    Player.PrepareUnitOrders(orders.player, orders.order, nil, pos, orders.ability, orders.orderIssuer, orders.npc, orders.queue, orders.showEffects)

    return false
end

function Morphling.MorphBalaceHP(myHero)

	if not myHero then return end
	if not Morphling.MorphBalanceToggler then return end
	if os.clock() - Morphling.MorphBalanceTimer < 0.1 then return end

	if NPC.IsSilenced(myHero) then return end
	if NPC.IsStunned(myHero) then return end
	local targetHP
	if Morphling.MorphBalanceSelectedHP > 0 then
		targetHP = Morphling.MorphBalanceSelectedHP
	end

	if not targetHP then return end

	local morphAGI = NPC.GetAbility(myHero, "morphling_morph_agi")
	local morphSTR = NPC.GetAbility(myHero, "morphling_morph_str")

		if not morphAGI or not morphSTR then return end
		if Ability.GetLevel(morphAGI) < 1 then return end
		if NPC.HasModifier(myHero, "modifier_morphling_replicate") then return end

	local myHP = Entity.GetHealth(myHero)
	local myMAXHP = Entity.GetMaxHealth(myHero)

	local shouldToggleAGI = false
	local shouldToggleStr = false
	local allowedDeviation = Menu.GetValue(Morphling.optionHeroMorphHPBalanceDeviation)

	if NPC.HasModifier(myHero, "modifier_fountain_aura_buff") then return end
		if targetHP - myHP >= allowedDeviation then
			if Hero.GetAgility(myHero) > 1 then
				shouldToggleStr = true
			else
				shouldToggleStr = false
			end
		else
			shouldToggleStr = false
		end

		if myMAXHP - targetHP >= allowedDeviation and (myHP - targetHP) >= allowedDeviation then
			if Hero.GetStrength(myHero) > 1 then
				shouldToggleAGI = true
			else
				shouldToggleAGI = false
			end
		else
			shouldToggleAGI = false
		end

	if shouldToggleStr then
		if not Ability.GetToggleState(morphSTR) then
			Ability.Toggle(morphSTR)
			Morphling.MorphBalanceTimer = os.clock()
			return
		end
	else
		if Ability.GetToggleState(morphSTR) then
			Ability.Toggle(morphSTR)
			Morphling.MorphBalanceTimer = os.clock()
			return
		end
	end

	if shouldToggleAGI then
		if not Ability.GetToggleState(morphAGI) then
			Ability.Toggle(morphAGI)
			Morphling.MorphBalanceTimer = os.clock()
			return
		end
	else
		if Ability.GetToggleState(morphAGI) then
			Ability.Toggle(morphAGI)
			Morphling.MorphBalanceTimer = os.clock()
			return
		end
	end
end

function Morphling.MorphDrawBalanceBoard(myHero)

	if not myHero then return end
	if not Menu.IsEnabled(Morphling.AutoShift) then return end

	local maxMorphAGI = math.floor(Hero.GetAgility(myHero))
	local maxMorphSTR = math.floor(Hero.GetStrength(myHero))
	local currentMAXHP = Entity.GetMaxHealth(myHero)

	local minHP = currentMAXHP - maxMorphSTR * 18 
	local maxHP = currentMAXHP + maxMorphAGI * 18

	local w, h = Renderer.GetScreenSize()
	Renderer.SetDrawColor(255, 255, 255)

	local startX = w - 300 - Menu.GetValue(Morphling.optionHeroMorphDrawBoardXPos)
	local startY = 300 + Menu.GetValue(Morphling.optionHeroMorphDrawBoardYPos)
	

		
	-- black background
	Renderer.SetDrawColor(0, 0, 0, 150)
	Renderer.DrawFilledRect(startX-1, startY, 202, 25)
	-- black border
	Renderer.SetDrawColor(0, 0, 0, 255)
	Renderer.DrawOutlineRect(startX-1, startY, 202, 25)

	-- min/max HP
	Renderer.SetDrawColor(0, 255, 0, 150)
	Renderer.DrawText(Font, startX-25, startY-25, minHP, 0)
	Renderer.SetDrawColor(255, 0, 0, 150)
	Renderer.DrawText(Font, startX+175, startY-25, maxHP, 0)

	-- colored rect
	for i = 1, 20 do
		Renderer.SetDrawColor(25 + i*10, 230 - i*10, 0, 150)
		Renderer.DrawFilledRect(startX + (i-1)*10 , startY+1, 10, 23)
	end

	-- hovering rects
	local hoveringTable = {}
	if next(hoveringTable) == nil then
		for i = 1, 20 do
			hoveringTable[i] = Input.IsCursorInRect(startX + (i-1)*10 , startY+1, 10, 23)
		end
	end

	-- on/off rects
	Renderer.SetDrawColor(0, 0, 0, 255)
	Renderer.DrawOutlineRect(startX+75, startY-25, 50, 20)
	Renderer.SetDrawColor(0, 0, 0, 150)
	Renderer.DrawFilledRect(startX+75, startY-25, 50, 20)
		local togglerHovering = Input.IsCursorInRect(startX+75, startY-25, 50, 20)
		if togglerHovering and Input.IsKeyDownOnce(Enum.ButtonCode.MOUSE_LEFT) then
			Morphling.MorphBalanceToggler = not Morphling.MorphBalanceToggler
		end

	if Morphling.MorphBalanceToggler then
		Renderer.SetDrawColor(0, 255, 0, 150)
		Renderer.DrawText(Font, startX+100, startY-27, "ON", 0)
	else
		Renderer.SetDrawColor(255, 0, 0, 150)
		Renderer.DrawText(Font, startX+100, startY-27, "OFF", 0)
	end

	local HPsteps = math.floor((maxHP - minHP) / 20)

	if Input.IsKeyDownOnce(Enum.ButtonCode.MOUSE_LEFT) then
		for i, v in ipairs(hoveringTable) do
			if hoveringTable[1] == true then
				Morphling.MorphBalanceSelectedHP = minHP
				Morphling.MorphBalanceSelected = 1
			elseif hoveringTable[20] == true then
				Morphling.MorphBalanceSelectedHP = maxHP
				Morphling.MorphBalanceSelected = 20
			else
				if v == true then
					Morphling.MorphBalanceSelectedHP = minHP + HPsteps*i
					Morphling.MorphBalanceSelected = i
				end
			end		
		end
	end

	if Morphling.MorphBalanceSelected > 0 then
		Renderer.SetDrawColor(0, 0, 0, 200)
		Renderer.DrawFilledRect(startX+3+10*(Morphling.MorphBalanceSelected-1), startY, 4, 30)
		Renderer.DrawText(Font, startX+3+10*(Morphling.MorphBalanceSelected-1), startY+30, Morphling.MorphBalanceSelectedHP, 0)
	end

end

function Morphling.OnMenuOptionChange(option, oldValue, newValue)
  if option == Morphling.AutoShiftBeforeGetStunned then
	if newValue then
		Menu.SetEnabled(Morphling.AutoShift, false)
	end
  end
  if option == Morphling.AutoShift then
  	if newValue then
  		Menu.SetEnabled(Morphling.AutoShiftBeforeGetStunned, false)
	end
  end
end


function Morphling.SleepReady(sleep, index)
	if (os.clock() - Morphling.lastTick[index]) >= sleep then
		return true
	end
	return false
end

return Morphling