local morph = {}

morph.optionEnable = Menu.AddOptionBool({"Hero Specific", "Morphling"}, "Enable", false)
morph.maxWaveRange =  Menu.AddOptionBool({"Hero Specific", "Morphling"}, "Max Waveform Range", false)
morph.AutoKill = Menu.AddOptionBool({"Hero Specific", "Morphling", "EBlade Auto Kill"}, "Enable", false)
morph.AutoKillKey = Menu.AddKeyOption({"Hero Specific",  "Morphling", "EBlade Auto Kill"}, "Toggle Key", Enum.ButtonCode.KEY_0)
morph.Display = Menu.AddOptionBool({"Hero Specific", "Morphling"}, "Damage Info", false)
morph.AutoShift = Menu.AddOptionBool({"Hero Specific", "Morphling","Auto Shift"}, "Enable", false)
morph.optionHeroMorphHPBalanceDeviation = Menu.AddOptionSlider({"Hero Specific", "Morphling", "Auto Shift" }, "HP Deviation", 50, 250, 50)

morph.AutoShiftKey = Menu.AddKeyOption({"Hero Specific",  "Morphling", "Auto Shift"}, "Toggle Key", Enum.ButtonCode.KEY_8)
morph.optionHeroMorphDrawBoardXPos = Menu.AddOptionSlider({ "Hero Specific", "Morphling","Auto Shift" }, "X-Pos Adjustment", -500, 500, 10)
morph.optionHeroMorphDrawBoardYPos = Menu.AddOptionSlider({ "Hero Specific", "Morphling","Auto Shift"}, "Y-Pos Adjustment", -500, 760, 10)


morph.myHero = nil
morph.players = {}
Font = Renderer.LoadFont("Tahoma", 20, Enum.FontWeight.BOLD)
FontForStatus = Renderer.LoadFont("Tahoma", 17, Enum.FontWeight.BOLD)
morph.localDmg = 0
morph.Toggler = true
morph.MorphBalanceToggler = true
morph.MorphBalanceTimer = 0
morph.MorphBalanceSelectedHP = 0
morph.MorphBalanceSelected = 0

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
	local FHeroes = Heroes.GetAll()
	if NPC.GetUnitName(morph.myHero) ~= "npc_dota_hero_morphling" then return end
	if Menu.IsKeyDownOnce(morph.AutoShiftKey) then
		if Menu.IsEnabled(morph.AutoShift) then
			Menu.SetEnabled(morph.AutoShift, false)
		else 
			Menu.SetEnabled(morph.AutoShift, true)
		end		
	end
	if Menu.IsKeyDownOnce(morph.AutoKillKey) then
		if Menu.IsEnabled(morph.AutoKill) then
			Menu.SetEnabled(morph.AutoKill, false)
		else 
			Menu.SetEnabled(morph.AutoKill, true)
		end		
	end
	if Menu.IsEnabled(morph.AutoShift) then
		morph.MorphBalaceHP(morph.myHero)
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
	if Menu.IsEnabled(morph.AutoShift) then
			morph.MorphDrawBalanceBoard(morph.myHero)
		end
end


-- function  morph.toggleShift(myHero)
-- 	local shift = NPC.GetAbilityByIndex(myHero, 4)
-- 	if not shift then return end
-- 	if not Ability.GetToggleState(shift) then
-- 		Ability.Toggle(shift)
-- 				return
-- 	end
-- end

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

function morph.MorphBalaceHP(myHero)

	if not myHero then return end
	if not morph.MorphBalanceToggler then return end
	if os.clock() - morph.MorphBalanceTimer < 0.1 then return end

	if NPC.IsSilenced(myHero) then return end
	if NPC.IsStunned(myHero) then return end
	local targetHP
	if morph.MorphBalanceSelectedHP > 0 then
		targetHP = morph.MorphBalanceSelectedHP
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
	local allowedDeviation = Menu.GetValue(morph.optionHeroMorphHPBalanceDeviation)

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

	-- else
	-- 	if myMAXHP - myHP <= 50 then
	-- 		if myMAXHP - targetHP >= 50 then
	-- 			shouldToggleAGI = true
	-- 		elseif targetHP - myHP >= 50 then
	-- 			shouldToggleStr = true
	-- 		else
	-- 			shouldToggleAGI = false
	-- 			shouldToggleStr = false
	-- 		end
	-- 	end
	-- end
	

	if shouldToggleStr then
		if not Ability.GetToggleState(morphSTR) then
			Ability.Toggle(morphSTR)
			morph.MorphBalanceTimer = os.clock()
			return
		end
	else
		if Ability.GetToggleState(morphSTR) then
			Ability.Toggle(morphSTR)
			morph.MorphBalanceTimer = os.clock()
			return
		end
	end

	if shouldToggleAGI then
		if not Ability.GetToggleState(morphAGI) then
			Ability.Toggle(morphAGI)
			morph.MorphBalanceTimer = os.clock()
			return
		end
	else
		if Ability.GetToggleState(morphAGI) then
			Ability.Toggle(morphAGI)
			morph.MorphBalanceTimer = os.clock()
			return
		end
	end
end

function morph.MorphDrawBalanceBoard(myHero)

	if not myHero then return end
	if not Menu.IsEnabled(morph.AutoShift) then return end

	local maxMorphAGI = math.floor(Hero.GetAgility(myHero))
	local maxMorphSTR = math.floor(Hero.GetStrength(myHero))-1
	local currentMAXHP = Entity.GetMaxHealth(myHero)

	local minHP = currentMAXHP - maxMorphSTR * 18 
	local maxHP = currentMAXHP + maxMorphAGI * 18

	local w, h = Renderer.GetScreenSize()
	Renderer.SetDrawColor(255, 255, 255)

	local startX = w - 300 - Menu.GetValue(morph.optionHeroMorphDrawBoardXPos)
	local startY = 300 + Menu.GetValue(morph.optionHeroMorphDrawBoardYPos)
	

		
	-- black background
	Renderer.SetDrawColor(0, 0, 0, 150)
	Renderer.DrawFilledRect(startX-1, startY, 202, 25)
--Log.Write("lol")
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
			morph.MorphBalanceToggler = not morph.MorphBalanceToggler
		end

	if morph.MorphBalanceToggler then
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
				morph.MorphBalanceSelectedHP = minHP
				morph.MorphBalanceSelected = 1
			elseif hoveringTable[20] == true then
				morph.MorphBalanceSelectedHP = maxHP
				morph.MorphBalanceSelected = 20
			else
				if v == true then
					morph.MorphBalanceSelectedHP = minHP + HPsteps*i
					morph.MorphBalanceSelected = i
				end
			end		
		end
	end

	if morph.MorphBalanceSelected > 0 then
		Renderer.SetDrawColor(0, 0, 0, 200)
		Renderer.DrawFilledRect(startX+3+10*(morph.MorphBalanceSelected-1), startY, 4, 30)
		Renderer.DrawText(Font, startX+3+10*(morph.MorphBalanceSelected-1), startY+30, morph.MorphBalanceSelectedHP, 0)
	end

end

return morph