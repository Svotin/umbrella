local morph = {}

morph.optionEnable = Menu.AddOptionBool({"Hero Specific", "Morphling"}, "Enable", false)
morph.maxWaveRange =  Menu.AddOptionBool({"Hero Specific", "Morphling"}, "Max Waveform Range", false)
morph.AutoKill = Menu.AddOptionBool({"Hero Specific", "Morphling", "EBlade Auto Kill"}, "Enable", false)
morph.AutoKillKey = Menu.AddKeyOption({"Hero Specific",  "Morphling", "EBlade Auto Kill"}, "Toggle Key", Enum.ButtonCode.KEY_0)
morph.Display = Menu.AddOptionBool({"Hero Specific", "Morphling"}, "Damage Info", false)
morph.AutoShift = Menu.AddOptionBool({"Hero Specific", "Morphling","Auto Shift"}, "Enable", false)
morph.AdditionalAbilities = Menu.AddOptionBool({"Hero Specific", "Morphling","Auto Shift"}, "[BETA]Additional Abilities", false)

morph.myHero = nil
morph.players = {}
Font = Renderer.LoadFont("Tahoma", 20, Enum.FontWeight.BOLD)
FontForStatus = Renderer.LoadFont("Tahoma", 17, Enum.FontWeight.BOLD)
morph.localDmg = 0

morph.defaultAbilities = {
	{"npc_dota_hero_axe", "axe_berserkers_call", 300, false},   		--false - пробивает через бкб
	{"npc_dota_hero_tidehunter", "tidehunter_ravage", 1250, true},      --true - не пробивает бкб
	{"npc_dota_hero_enigma", "enigma_black_hole", 720, false},
	{"npc_dota_hero_magnataur", "magnataur_reverse_polarity", 430, false},
	{"npc_dota_hero_slardar", "slardar_slithereen_crush", 355, true},
	{"npc_dota_hero_centaur", "centaur_hoof_stomp", 345, true},
	{"npc_dota_hero_earthshaker" ,"earthshaker_fissure", 300, true},
	{"npc_dota_hero_earthshaker" ,"earthshaker_enchant_totem", 300, true},
	{"npc_dota_hero_faceless_void", "faceless_void_chronosphere", 1100, false}
}

morph.additionalAbilities = {
	{"npc_dota_hero_batrider", "batrider_flaming_lasso", 170},
	{"npc_dota_hero_legion_commander", "legion_commander_duel", 150},
	{"npc_dota_hero_pudge", "pudge_dismember", 160},
	{"npc_dota_hero_doom_bringer", "doom_bringer_doom", 650},
	{"npc_dota_hero_bane", "bane_fiends_grip", 625},
	{"npc_dota_hero_beastmaster", "beastmaster_primal_roar", 600},
}

morph.projectileAbilities = {
	{"npc_dota_hero_alchemist", 900},
	{"npc_dota_hero_sven", 1000},
	{"npc_dota_hero_chaos_knight", 1000},
	{"npc_dota_hero_skeleton_king", 1000},
	{"npc_dota_hero_vengefulspirit", 1250},
	{"npc_dota_hero_dragon_knight", 1600},
	{"npc_dota_hero_windrunner", 1650}
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
		for _,v in pairs(FHeroes) do
			if v and Entity.IsHero(v) and Entity.IsAlive(v) and not Entity.IsSameTeam(morph.myHero, v) and not Entity.IsDormant(v) and not NPC.IsIllusion(v) then
				for i,k in pairs(morph.defaultAbilities) do
					if NPC.GetUnitName(v) == k[1] then
						local p1 = NPC.GetAbility(v, k[2])
						if p1 ~= (nil or 0) and Ability.IsInAbilityPhase(p1) then								 
							local p2 = Ability.GetCastPoint(p1)
							if NPC.IsEntityInRange(morph.myHero, v, k[3]) then
								if NPC.HasState(morph.myHero,Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) and k[4] then 
									return 
								end
								morph.toggleShift(morph.myHero)
								return
							end
						end
					end
				end	
				if Menu.IsEnabled(morph.AdditionalAbilities) then
					for i,k in pairs(morph.additionalAbilities) do
						if NPC.GetUnitName(v) == k[1] then
							local p1 = NPC.GetAbility(v, k[2])
							if p1 ~= (nil or 0) and Ability.IsInAbilityPhase(p1) then								 
								local p2 = Ability.GetCastPoint(p1)
								if NPC.IsEntityInRange(morph.myHero, v, k[3]) and NPC.FindFacingNPC(v)==morph.myHero then
									if NPC.IsLinkensProtected(morph.myHero) then 
										return 
									end
									morph.toggleShift(morph.myHero)
									return
								end
							end
						end
					end
				end	
			end
		end
	end
	if Menu.IsEnabled(morph.AutoKill) or Menu.IsEnabled(morph.Display) then
		for i = 1, Heroes.Count() do
   			local hero = Heroes.Get(i)
   			if not Entity.IsSameTeam(morph.myHero, hero) and not morph.players[Hero.GetPlayerID(hero)] and hero ~= morph.myHero then 
   				morph.players[Hero.GetPlayerID(hero)] = Menu.AddOptionBool({"Hero Specific", "Morphling", "EBlade Auto Kill"}, string.upper(string.sub(NPC.GetUnitName(hero), 15)), true)
   				return
   			end
   		end 
   	end
   	if Menu.IsEnabled(morph.AutoKill) or Menu.IsEnabled(morph.Display) then
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
		if not Menu.IsEnabled(morph.AutoKill) then return end
		for _,hero in pairs(FHeroes) do
			if hero ~= nil and hero ~= 0 and NPCs.Contains(hero) and NPC.IsEntityInRange(morph.myHero, hero,castRange) and not Entity.IsSameTeam(hero,morph.myHero) then
				if Entity.IsAlive(hero) and not Entity.IsDormant(hero) and not NPC.IsIllusion(hero) and Menu.IsEnabled(morph.players[Hero.GetPlayerID(hero)]) and morph.IsHasGuard(hero)=="nil"  then
					local totalDmg = morph.GetTotalDmg(hero, morph.localDmg, morph.myHero) - 2
					if Entity.GetHealth(hero)+NPC.GetHealthRegen(hero) <= totalDmg then
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
	if spell_shield and Ability.IsReady(spell_shield) and (NPC.HasModifier(npc, "modifier_item_ultimate_scepter") or NPC.HasModifier(npc, "modifier_item_ultimate_scepter_consumed")) 
	and not NPC.HasModifier(npc,"modifier_silver_edge_debuff") and not NPC.HasModifier(npc,"modifier_viper_nethertoxin") then
		guarditis = "Lotus"
	end
	local abaddonUlt = NPC.GetAbility(npc, "abaddon_borrowed_time")
	if abaddonUlt then
			if Ability.IsReady(abaddonUlt) or Ability.SecondsSinceLastUse(abaddonUlt)<=1 then --рот ебал этого казино, он даёт прокаст, когда абилка уже в кд, а модификатора ещё нет.
				guarditis = "Immune"
			end
	end
	if NPC.GetAbility(npc,"special_bonus_unique_queen_of_pain") then 
		guarditis = "Linkens"
	end
	if NPC.HasModifier(npc,"modifier_item_lotus_orb_active") then guarditis = "Lotus" end
	if 	NPC.HasState(npc,Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) or 
		NPC.HasState(npc,Enum.ModifierState.MODIFIER_STATE_OUT_OF_GAME) or
		NPC.HasModifier(npc,"modifier_medusa_stone_gaze_stone") or
		NPC.HasModifier(npc,"modifier_winter_wyvern_winters_curse") or
		NPC.HasModifier(npc,"modifier_templar_assassin_refraction_absorb") or
		NPC.HasModifier(npc,"modifier_nyx_assassin_spiked_carapace") or
		NPC.HasModifier(npc,"modifier_item_aeon_disk_buff") or
		NPC.HasModifier(npc,"modifier_abaddon_borrowed_time") or
		NPC.HasModifier(npc,"modifier_dark_willow_shadow_realm_buff") or
		NPC.HasModifier(npc,"modifier_dazzle_shallow_grave") or 
		NPC.HasModifier(npc,"modifier_special_bonus_spell_block") or
		NPC.HasModifier(npc,"modifier_skeleton_king_reincarnation_scepter_active") or
		NPC.HasModifier(npc,"modifier_eul_cyclone") or
		NPC.HasModifier(npc,"modifier_brewmaster_storm_cyclone") then	
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
	local rainDrop = NPC.GetItem(target, "item_infused_raindrop", true)
	if rainDrop and Ability.IsReady(rainDrop) then
		totalDmg = totalDmg - 120
	end
	local kaya = NPC.GetItem(myHero, "item_kaya", true)
	if kaya then 
		totalDmg = totalDmg*1.1 
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
		totalDmg = totalDmg * 0.70
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
	if NPC.HasModifier(target,"abaddon_aphotic_shield") then 
		totalDmg = totalDmg - 200
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
		totalDmg = totalDmg * 0.5
	end
	if NPC.HasModifier(target, "modifier_shadow_demon_soul_catcher") then
		local soulCatcherLvl = Ability.GetLevel(Modifier.GetAbility(NPC.GetModifier(target, "modifier_shadow_demon_soul_catcher")))
		Log.Write((1.1 + (0.1 * soulCatcherLvl)))
		totalDmg = totalDmg * (1.1 + (0.1 * soulCatcherLvl))
	end
	return totalDmg
end

function morph.OnDraw()
	if not Menu.IsEnabled(morph.optionEnable) then return end
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
	end
	Renderer.DrawText(Font, x, y, "AutoKill: ["..autoKillMode.."]")
	if Menu.IsEnabled(morph.Display) then
		local FHeroes = Heroes.GetAll()
		for _,hero in pairs(FHeroes) do
			if hero ~= nil and hero ~= 0 and NPCs.Contains(hero) and not Entity.IsSameTeam(hero,morph.myHero) then
				if Entity.IsAlive(hero) and not Entity.IsDormant(hero) and not NPC.IsIllusion(hero) then
					local totalDmg = morph.GetTotalDmg(hero, morph.localDmg, morph.myHero) - 2
					local dmg = Entity.GetHealth(hero) - totalDmg 
					if dmg > 0 then
						Renderer.SetDrawColor(255, 0, 0)
					else
						Renderer.SetDrawColor(90, 255, 100)
					end
					local pos = Entity.GetAbsOrigin(hero)
		            local x, y, visible = Renderer.WorldToScreen(pos)

		            if visible and pos then
		                Renderer.DrawText(FontForStatus, x, y-12, math.abs(math.floor(dmg)), 1)
		            end
				end
			end
		end
	end
end

function morph.OnProjectile(projectile)
	morph.myHero = Heroes.GetLocal()
	if morph.myHero == nil or NPC.GetUnitName(morph.myHero) ~= "npc_dota_hero_morphling" then return end 
	if not Menu.IsEnabled(morph.AutoShift) or not Menu.IsEnabled(morph.optionEnable) then return end
	local target = projectile.target
	local source = nil
	if Entity.IsEntity(projectile.source) then
		source = NPC.GetUnitName(projectile.source)
	end
	local speed = projectile.moveSpeed
	if target == morph.myHero then
		for k,hero in pairs(morph.projectileAbilities) do
			if source == hero[1] and speed == hero[2] and not NPC.IsLinkensProtected(morph.myHero) then
				morph.toggleShift(morph.myHero)
				return
			end 
		end
	end
end

function  morph.toggleShift(myHero)
	local shift = NPC.GetAbilityByIndex(myHero, 4)
	if not shift then return end
	if not Ability.GetToggleState(shift) then
		Ability.Toggle(shift)
				return
	end
end

function morph.OnPrepareUnitOrders(orders) --xenohack
	if not orders then return true end
	if not Menu.IsEnabled(morph.maxWaveRange) then return true end
	
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

return morph