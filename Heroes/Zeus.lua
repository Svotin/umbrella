Zeus = {}


Zeus.optionEnable = Menu.AddOptionBool({"Hero Specific", "Zeus"}, "Enable", false)
Zeus.TPcancel = Menu.AddOptionBool({"Hero Specific", "Zeus"}, "Cancel TP's", false)
Zeus.autoUlt = Menu.AddOptionBool({"Hero Specific", "Zeus"}, "Auto Wrath", false)
Zeus.KillForUlt = Menu.AddOptionSlider({"Hero Specific", "Zeus"}, "Minimum Killed by Wrath", 1, 5, 1)
Zeus.comboKey = Menu.AddKeyOption({"Hero Specific", "Zeus"}, "Combo Key", Enum.ButtonCode.KEY_7)
Zeus.lastHitKey = Menu.AddKeyOption({"Hero Specific", "Zeus"}, "LastHit Key", Enum.ButtonCode.KEY_6)
Zeus.harrasKey = Menu.AddKeyOption({"Hero Specific", "Zeus"}, "Harras Key", Enum.ButtonCode.KEY_5)

Zeus.AutoArcane = Menu.AddOptionBool({"Hero Specific", "Zeus"}, "Auto Arcane Boots", false)


Zeus.optionArc = Menu.AddOptionBool({"Hero Specific", "Zeus", "Ablilities"}, "Arc Lightning", false)
Zeus.optionBolt = Menu.AddOptionBool({"Hero Specific", "Zeus", "Ablilities"}, "Lightining Bolt", false)
Zeus.optionNimbus = Menu.AddOptionBool({"Hero Specific", "Zeus", "Ablilities"}, "Nimbus", false)

Zeus.optionSoulRing = Menu.AddOptionBool({"Hero Specific", "Zeus", "Items"}, "Soul Ring", false)
Zeus.optionDagon = Menu.AddOptionBool({"Hero Specific", "Zeus", "Items"}, "Dagon", false)
Zeus.optionDiscord = Menu.AddOptionBool({"Hero Specific", "Zeus", "Items"}, "Veil of Discord", false)
Zeus.optionHex = Menu.AddOptionBool({"Hero Specific", "Zeus", "Items"}, "Skythe of Vyse", false)
Zeus.optionAtos = Menu.AddOptionBool({"Hero Specific", "Zeus", "Items"}, "Rod of Atos", false)
Zeus.optionEBlade = Menu.AddOptionBool({"Hero Specific", "Zeus", "Items"}, "Ethereal Blade", false)
Zeus.optionShiva = Menu.AddOptionBool({"Hero Specific", "Zeus", "Items"}, "Shiva's Guard", false)

myHero = nil
myMana = nil

tp_index = nil
tp_position = nil
flag = false

arc = nil
castRangeBonus = nil
wrath = nil
target = nil

function Zeus.OnUpdate()
	if not Menu.IsEnabled(Zeus.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	myHero = Heroes.GetLocal()
	if NPC.GetUnitName(myHero) ~= "npc_dota_hero_zuus" then return end
	myMana = NPC.GetMana(myHero)
	if not Entity.IsAlive(myHero) or NPC.IsStunned(myHero) or NPC.IsSilenced(myHero) then  Zeus.ZeroingVars() return end
	if Menu.IsKeyDown(Zeus.lastHitKey) or Menu.IsKeyDown(Zeus.harrasKey) and arc ~= nil and castRangeBonus ~= nil then
		Engine.ExecuteCommand("dota_range_display " .. Ability.GetCastRange(arc)+castRangeBonus)
	else
		Engine.ExecuteCommand("dota_range_display " .. 0)
	end
	if Menu.IsKeyDown(Zeus.comboKey) or Menu.IsKeyDown(Zeus.lastHitKey) or Menu.IsKeyDown(Zeus.harrasKey) then 
		if target == nil then 
			target = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
		end
		if Zeus.Combo(myHero, target) == false then
			target = nil
		end
	end
	if Menu.IsEnabled(Zeus.TPcancel) then
		local nimbus = NPC.GetAbility(myHero, "zuus_cloud")
		if not nimbus then return end
		if tp_position ~= nil then
			local AllHeroes = Heroes.GetAll()
			for i,hero in pairs(AllHeroes) do
				if hero and Entity.IsHero(hero) and Entity.IsAlive(hero) and Entity.IsSameTeam(myHero, hero)  then
					heroPos = Entity.GetAbsOrigin(hero) 
					substruct = heroPos:__sub(tp_position)
					result = math.abs (substruct:GetX() + substruct:GetY()+substruct:GetZ())
					if result < 2 then 
						Zeus.ZeroingVars()
						return 
					end
				end
			end
			if Ability.IsReady(nimbus) and Ability.GetManaCost(nimbus)<=NPC.GetMana(myHero) then
				Ability.CastPosition(nimbus, tp_position)
				Zeus.ZeroingVars()
				return
			end
		end
	end
	if Menu.IsEnabled(Zeus.AutoArcane) then
		local arcaneBoots = NPC.GetItem(myHero, "item_arcane_boots", true)
		if NPC.GetMaxMana(myHero) - NPC.GetMana(myHero) > 135 and arcaneBoots and Ability.IsReady(arcaneBoots) then
			Ability.CastNoTarget(arcaneBoots)
			return
		end
	end
	if Menu.IsEnabled(Zeus.autoUlt) then 
		wrath = NPC.GetAbility(myHero, "zuus_thundergods_wrath")
		if wrath then 
			if Zeus.UltiKillCount(myHero, myMana, wrath) then Ability.CastNoTarget(wrath) return end
		end
	end
end


function Zeus.OnParticleCreate(particle)
	if particle.name == "teleport_start" then 
		tp_index = particle.index
	end
end


function Zeus.OnParticleUpdate( particle )
	if particle.controlPoint ~= 0 then return end
	if tp_index == particle.index then 
		if tp_position ~= nil or flag == true then return end
		tp_position = particle.position
		flag = true
	end
end


function Zeus.Combo(myHero, target)
	if not myHero then return false end
	--             ABILITIES                    --
	arc = NPC.GetAbilityByIndex(myHero, 0)
 	local bolt = NPC.GetAbilityByIndex(myHero, 1)
 	local static = NPC.GetAbilityByIndex(myHero, 2)
 	wrath = NPC.GetAbility(myHero, "zuus_thundergods_wrath")
	local nimbus = NPC.GetAbility(myHero, "zuus_cloud")
	--             ITEMS                        --
	local soulRing = NPC.GetItem(myHero, "item_soul_ring", true)
	local atos = NPC.GetItem(myHero, "item_rod_of_atos", true)
	local hex = NPC.GetItem(myHero, "item_sheepstick", true)
	local veil = NPC.GetItem(myHero, "item_veil_of_discord", true)
	local eblade = NPC.GetItem(myHero, "item_ethereal_blade", true)
	local shiva = NPC.GetItem(myHero, "item_shivas_guard", true)
	local dagon = NPC.GetItem(myHero, "item_dagon", true)
	if not dagon then
		for i = 2, 5 do
			dagon = NPC.GetItem(myHero, "item_dagon_" .. i, true)
			if dagon then break end
		end
	end
	castRangeBonus = NPC.GetCastRangeBonus(myHero) 
	if soulRing and Menu.IsEnabled(Zeus.optionSoulRing) and Ability.IsReady(soulRing) and Entity.GetHealth(myHero) > 350 then 
		Ability.CastNoTarget(soulRing)
		myMana = myMana+150
	end	
	----                 COMBO               ----             
	if Menu.IsKeyDown(Zeus.comboKey) then               
		if not target then return false end
		if NPC.IsEntityInRange(myHero, target, 2000) and Entity.IsAlive(target) then
			local targetGuard = Zeus.IsHasGuard(target)
			if targetGuard ~= "Immune" and targetGuard ~= "Lotus" then
				if targetGuard == "Linkens" then 
					if arc and Ability.IsCastable(arc, myMana) then
						Ability.CastTarget(arc, target)
						return true
					else
						return false
					end
				end	
				if atos and Ability.IsCastable(atos, myMana) and Menu.IsEnabled(Zeus.optionAtos) and NPC.IsEntityInRange(myHero, target,Ability.GetCastRange(atos)+castRangeBonus) then
					Ability.CastTarget(atos, target)
					return true
				end
				if eblade and Ability.IsCastable(eblade, myMana) and Menu.IsEnabled(Zeus.optionEBlade) and NPC.IsEntityInRange(myHero, target,Ability.GetCastRange(eblade)+castRangeBonus) then
					Ability.CastTarget(eblade, target)
					return true
				end
				if hex and Ability.IsCastable(hex, myMana) and Menu.IsEnabled(Zeus.optionHex) and NPC.IsEntityInRange(myHero, target,Ability.GetCastRange(hex)+castRangeBonus) then
					Ability.CastTarget(hex, target)
					return true
				end
				if veil and Ability.IsCastable(veil, myMana) and Menu.IsEnabled(Zeus.optionDiscord) and NPC.IsEntityInRange(myHero, target,Ability.GetCastRange(veil)+castRangeBonus) then
					Ability.CastPosition(veil, Entity.GetAbsOrigin(target))
					return true
				end
				if dagon and Ability.IsCastable(dagon, myMana) and Menu.IsEnabled(Zeus.optionDagon) and NPC.IsEntityInRange(myHero, target,Ability.GetCastRange(dagon)+castRangeBonus) then
					Ability.CastTarget(dagon, target)
					return true
				end
				if shiva and Ability.IsCastable(shiva, myMana) and Menu.IsEnabled(Zeus.optionShiva) then
					Ability.CastNoTarget(shiva)
					return true
				end
				if arc and Ability.IsCastable(arc, myMana) and Menu.IsEnabled(Zeus.optionArc) and NPC.IsEntityInRange(myHero, target,Ability.GetCastRange(arc)+castRangeBonus) and not Ability.IsInAbilityPhase(arc) then
					Ability.CastTarget(arc, target)
					return true
				end
				if bolt and Ability.IsCastable(bolt, myMana) and Menu.IsEnabled(Zeus.optionBolt) and NPC.IsEntityInRange(myHero, target,Ability.GetCastRange(bolt)+castRangeBonus) and not Ability.IsInAbilityPhase(bolt)   then
					Ability.CastTarget(bolt, target)
					return true
				end
				if nimbus and Ability.IsCastable(nimbus, myMana) and Menu.IsEnabled(Zeus.optionNimbus) and not Ability.IsInAbilityPhase(nimbus) then
					Ability.CastPosition(nimbus, Entity.GetAbsOrigin(target))
					return true
				end	
			end		
		end
	end
	----                 ARC LASTHIT               ----             
	if Menu.IsKeyDown(Zeus.lastHitKey) and arc then 
		local units = Entity.GetUnitsInRadius(myHero, Ability.GetCastRange(arc)+castRangeBonus, Enum.TeamType.TEAM_ENEMY)
		if not units then return false end
		for _, unit in pairs(units) do
			if NPC.IsLaneCreep(unit) and Entity.GetHealth(unit)/NPC.GetMagicalArmorDamageMultiplier(unit)<=Ability.GetLevelSpecialValueFor(arc, "arc_damage") and not Ability.IsInAbilityPhase(arc) and Ability.IsCastable(arc, myMana) then
				Ability.CastTarget(arc, unit)
				return false
			end
		end
	end
	----                 ARC HARRAS               ---- 
	if Menu.IsKeyDown(Zeus.harrasKey) then
		if not target then return false end
		if NPC.IsEntityInRange(myHero, target, Ability.GetCastRange(arc)+castRangeBonus) and Entity.IsAlive(target) then
			if arc and Ability.IsCastable(arc, myMana) and not Ability.IsInAbilityPhase(arc) then
				Ability.CastTarget(arc, target)
				return false
			end
		end
	end
	return false
end

function Zeus.UltiKillCount(myHero, myMana, ult)
	if not myHero then return false end
	local count = 0
	local ultDamage = Zeus.GetWrathDmg(ult, myMana, myHero)
	for i = 1, Heroes.Count(), 1 do
	local enemy = Heroes.Get(i)
		if enemy ~= nil and Entity.IsHero(enemy) and not Entity.IsSameTeam(myHero, enemy) then
			if Zeus.IsHasGuard(enemy)~="Immune" then
				local totalDmg = Zeus.GetTotalWrathDmg(enemy,ultDamage, myHero)
				if Entity.GetHealth(enemy)+NPC.GetHealthRegen(enemy) <= totalDmg then
					count = count + 1
				end
			end
		end
	end
	if count >= Menu.GetValue(Zeus.KillForUlt) then return true end
	return false

end

function Zeus.GetWrathDmg(ult,myMana,myHero)
	if not ult then return 0 end
	if not Ability.IsReady(ult) then return 0 end
	if not Ability.IsCastable(ult, myMana) then return 0 end
	local ultLevel = Ability.GetLevel(ult)
	if ultLevel == 0 then return 0 end
	local wrthDmg = 125+(ultLevel*100)
	local intellect = Hero.GetIntellectTotal(myHero)
	local intMultiplier = ((0.089 * intellect) / 100) + 1
	return wrthDmg*intMultiplier
end

function Zeus.GetTotalWrathDmg(target,dmg, myHero)--ЧЕСТНО СПИЗДИЛ
	if not target or not myHero then return end
	local totalDmg = (dmg * NPC.GetMagicalArmorDamageMultiplier(target))
	local rainDrop = NPC.GetItem(target, "item_infused_raindrop", true)
	if rainDrop and Ability.IsReady(rainDrop) then
		totalDmg = totalDmg - 120
	end
	local kaya = NPC.GetItem(morph.myHero, "item_kaya", true)
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
	return totalDmg
end

function Zeus.ZeroingVars()
	tp_index = nil
	tp_position = nil
	flag = false
end

function Zeus.IsHasGuard(npc)
	local guarditis = "nil"
	if NPC.IsLinkensProtected(npc) then guarditis = "Linkens" end
	if NPC.HasModifier(npc,"modifier_item_blade_mail_reflect") then guarditis = "BM" end
	local spell_shield = NPC.GetAbility(npc, "antimage_spell_shield")
	if spell_shield and Ability.IsReady(spell_shield) and (NPC.HasModifier(npc, "modifier_item_ultimate_scepter") or NPC.HasModifier(npc, "modifier_item_ultimate_scepter_consumed")) then
		guarditis = "Linkens"
	end
	local abaddonUlt = NPC.GetAbility(npc, "abaddon_borrowed_time")
	if abaddonUlt then
			if Ability.IsReady(abaddonUlt) or Ability.SecondsSinceLastUse(abaddonUlt)<=1 then --рот ебал этого казино, он даёт прокаст, когда абилка уже в кд, а модификатора ещё нет.
				guarditis = "Immune"
			end
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

return Zeus