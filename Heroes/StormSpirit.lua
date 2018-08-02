local StormSpirit = {}

StormSpirit.optionEnable = Menu.AddOptionBool({"Hero Specific", "Storm Spirit"}, "Enable",false)
StormSpirit.ComboKey = Menu.AddKeyOption({"Hero Specific", "Storm Spirit"}, "Combo Key", Enum.ButtonCode.KEY_V)
StormSpirit.NearestTarget =  Menu.AddOptionSlider({"Hero Specific", "Storm Spirit"}, "Closest to mouse range", 200, 800, 100)
StormSpirit.optionHex = Menu.AddOptionBool({"Hero Specific", "Storm Spirit", "Items"}, "Skythe of Vyse", false)
StormSpirit.optionShiva = Menu.AddOptionBool({"Hero Specific", "Storm Spirit", "Items"}, "Shiva's Guard", false)
StormSpirit.optionOrchid = Menu.AddOptionBool({"Hero Specific", "Storm Spirit", "Items"}, "Orchid/Bloodthorn", false)
StormSpirit.optionNullifier = Menu.AddOptionBool({"Hero Specific", "Storm Spirit", "Items"}, "Nullifier", false)
StormSpirit.manaThreshold =  Menu.AddOptionSlider({"Hero Specific", "Storm Spirit"}, "Dont use ult onto themselves then mana less than", 5, 100, 30)
StormSpirit.targetIndicator = Menu.AddOptionBool({"Hero Specific", "Storm Spirit"}, "Target Indicator",false)
StormSpirit.optionIcon = Menu.AddOptionIcon({ "Hero Specific","Storm Spirit"}, "panorama/images/heroes/icons/npc_dota_hero_storm_spirit_png.vtex_c")
StormSpirit.drawing = Menu.AddOptionBool({"Hero Specific", "Storm Spirit"}, "Calculator",false)
StormSpirit.drawPlace = Menu.AddOptionCombo({"Hero Specific", "Storm Spirit"}, "Drawing Type", {"Static", "Depending on cursor"}, 0)
StormSpirit.optionDrawingX = Menu.AddOptionSlider({"Hero Specific", "Storm Spirit"},"X Coord", 1, 100, 1)
StormSpirit.optionDrawingY = Menu.AddOptionSlider({"Hero Specific", "Storm Spirit"},"Y Coord", 1, 100, 1)

StormSpirit.fontItem = Renderer.LoadFont("Arial", 18, Enum.FontWeight.EXTRABOLD)


local null, hex, orchid, shiva, dagon
local myHero = nil
local heroName = nil
local myPlayer = nil
local myTeam = nil
local cm_in_team = false
local cm_talant = false
local last_update = 0

local ult = nil
local remnant = nil
local vortex = nil
local aghanim = nil

local arcaneRune = false
local kaya = false
local cm_reduction = false

local manaStartUltimatePerc  = 0
local manaStartUltimateConst = 0

local w, h = 0
local x = 0
local y = 0
local outsizeWidth = 0
local insizeWidth = 0
local loss_mana = 0
local time_ultimate_to_point = 0
local damage = 0
local enemy = 0


local targetParticle = 0




function StormSpirit.OnUpdate()
	if not Menu.IsEnabled(StormSpirit.optionEnable) or not Engine.IsInGame() then return end
	if not myHero then
		return
	end
	if heroName ~= "npc_dota_hero_storm_spirit" then return end
---------------------------------------------------------------------------------------------------------------------------
	if Menu.GetValue(StormSpirit.drawPlace) == 0 then
		if Input.IsKeyDown(Enum.ButtonCode.KEY_RIGHT) and Menu.GetValue(StormSpirit.optionDrawingX) < 100 then
			Menu.SetValue(StormSpirit.optionDrawingX, (Menu.GetValue(StormSpirit.optionDrawingX)+1))
		elseif Input.IsKeyDown(Enum.ButtonCode.KEY_LEFT) and Menu.GetValue(StormSpirit.optionDrawingX) > 1 then
			Menu.SetValue(StormSpirit.optionDrawingX, (Menu.GetValue(StormSpirit.optionDrawingX)-1))
		elseif Input.IsKeyDown(Enum.ButtonCode.KEY_UP) and Menu.GetValue(StormSpirit.optionDrawingY) > 1 then
			Menu.SetValue(StormSpirit.optionDrawingY, (Menu.GetValue(StormSpirit.optionDrawingY)-1))
		elseif Input.IsKeyDown(Enum.ButtonCode.KEY_DOWN) and Menu.GetValue(StormSpirit.optionDrawingY) < 100 then
			Menu.SetValue(StormSpirit.optionDrawingY, (Menu.GetValue(StormSpirit.optionDrawingY)+1))
		end
	end
---------------------------------------------------------------------------------------------------------------------------
	local myMana = NPC.GetMana(myHero)
	if Menu.IsEnabled(StormSpirit.drawing) then
		time_ultimate_to_point, loss_mana, damage,outsizeWidth, insizeWidth = StormSpirit.calc(myHero,myMana,Input.GetWorldCursorPos())
	end
	if cm_in_team and cm_talant == false then
		StormSpirit.FindCMTalant()
	end
    if Menu.IsKeyDown(StormSpirit.ComboKey) then
    	StormSpirit.Combo(myMana)
    elseif enemy and enemy ~= 0 then
    	enemy = nil
	end
    StormSpirit.GetInfo(myHero)
end

local sleep_after_gameinfo_upd = 0  
function StormSpirit.GetInfo(hero)
	if not StormSpirit.SleepReady(0.5, sleep_after_gameinfo_upd) then return end
	ult = NPC.GetAbility(hero, "storm_spirit_ball_lightning")
	remnant =  NPC.GetAbility(hero, "storm_spirit_static_remnant")
	vortex =  NPC.GetAbility(hero, "storm_spirit_electric_vortex")

	arcaneRune = NPC.HasModifier(hero,"modifier_rune_arcane") 
	kaya = NPC.GetItem(hero, "item_kaya", true)
	if cm_talant and NPC.GetModifier(hero, "modifier_crystal_maiden_brilliance_aura_effect") then
		cm_reduction = true
	else
		cm_reduction = false
	end
	if not aghanim and (NPC.HasModifier(myHero, "modifier_item_ultimate_scepter") or NPC.HasModifier(myHero, "modifier_item_ultimate_scepter_consumed")) then
		aghanim = true
	end
	manaStartUltimatePerc = Ability.GetLevelSpecialValueForFloat(ult, "ball_lightning_initial_mana_percentage")
	manaStartUltimateConst = Ability.GetLevelSpecialValueForFloat(ult, "ball_lightning_initial_mana_base")
	StormSpirit.GetItems(hero)

	sleep_after_gameinfo_upd = os.clock()
end

function StormSpirit.GetItems(hero)
    null = NPC.GetItem(hero, "item_nullifier")
	hex = NPC.GetItem(hero, "item_sheepstick")
	orchid = NPC.GetItem(hero, "item_bloodthorn")
    if not orchid then
        orchid = NPC.GetItem(hero, "item_orchid")
	end
	shiva = NPC.GetItem(myHero, "item_shivas_guard", true)
end


local sleep_after_cast = 0
local sleep_after_attack = 0
function StormSpirit.Combo(mana)
    enemy = Input.GetNearestHeroToCursor(myTeam, Enum.TeamType.TEAM_ENEMY)
    if not enemy or enemy == 0 then return end
    local enemy_origin = Entity.GetAbsOrigin(enemy)
    local cursor_pos = Input.GetWorldCursorPos()
	if (cursor_pos - enemy_origin):Length2D() > Menu.GetValue(StormSpirit.NearestTarget) then return end
	local in_ult =  NPC.HasModifier(myHero, "modifier_storm_spirit_ball_lightning") 
	if in_ult then
		sleep_after_cast = os.clock()
	end
    local my_origin = Entity.GetAbsOrigin(myHero)
	local range_to_enemy = (my_origin - enemy_origin):Length2D() 
	local protection = StormSpirit.checkProtection(enemy)
	if range_to_enemy < 450 then
		StormSpirit.UseItems(enemy,mana,protection)
    	if NPC.HasModifier(myHero, "modifier_storm_spirit_overload") or protection == "IMMUNE" then
    		if StormSpirit.SleepReady(0.1, sleep_after_attack)  then 
	    		Player.AttackTarget(myPlayer, myHero, enemy)
	    		sleep_after_attack = os.clock()
	    	end
    	else
    		if StormSpirit.SleepReady(0.4, sleep_after_cast) then
	    		if vortex and Ability.IsReady(vortex) and Ability.IsCastable(vortex, mana) then
	    			if not aghanim then
	    				Ability.CastTarget(vortex, enemy)
	    			else
	    				Ability.CastNoTarget(vortex)
	    			end
	    			sleep_after_cast = os.clock()
	    		elseif remnant and Ability.IsReady(remnant) and Ability.IsCastable(remnant, mana) then
	    			Ability.CastNoTarget(remnant)
	    			sleep_after_cast = os.clock()
	    		elseif ult and Ability.IsReady(ult) and Ability.IsCastable(ult, mana) and StormSpirit.SleepReady(0.8, sleep_after_cast) then
	    			local ult_pos = my_origin
	    			if range_to_enemy > 350 then
	    				if NPC.IsRunning(enemy) then
	    					ult_pos = (enemy_origin + (my_origin - enemy_origin):Normalized():Scaled(100))
	    				else
	    					ult_pos = (enemy_origin + (my_origin - enemy_origin):Normalized():Scaled(250))
	    				end
	    			elseif mana * 100 / NPC.GetMaxMana(myHero) < Menu.GetValue(StormSpirit.manaThreshold) then
	    				return
	    			end
	    			Ability.CastPosition(ult, ult_pos)
	    			sleep_after_cast = os.clock()
	    		elseif StormSpirit.SleepReady(0.4, sleep_after_attack) then
	    			Player.AttackTarget(myPlayer, myHero, enemy)
	    			sleep_after_attack = os.clock()
	    		end
	    	end
		end
		
    else
    	if ult and Ability.IsReady(ult) and Ability.IsCastable(ult, mana) and StormSpirit.SleepReady(0.4, sleep_after_cast) then
    		local time_to_enemy, mana_loss = StormSpirit.calc(myHero, mana, enemy_origin)
    		local scale = 250
    		if NPC.IsRunning(enemy) then
    			enemy_origin = StormSpirit.castPrediction(myHero, enemy, enemy_origin, time_to_enemy+(NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)))
    			scale = -100
    		end
    		ult_pos = (enemy_origin + (my_origin - enemy_origin):Normalized():Scaled(scale))
			Ability.CastPosition(ult, ult_pos, true)
    		sleep_after_cast = os.clock()
    	else 
    		StormSpirit.SleepReady(0.4, sleep_after_attack) 
			Player.AttackTarget(myPlayer, myHero, enemy)
			sleep_after_attack = os.clock()
		end
	end
end

function StormSpirit.UseItems(enemy,mana, protection)
	if not protection then
		if hex and Menu.IsEnabled(StormSpirit.optionHex) and Ability.IsReady(hex) and Ability.IsCastable(hex,mana) then
			Ability.CastTarget(hex, enemy)
			return
		end
		if shiva and Menu.IsEnabled(StormSpirit.optionShiva) and Ability.IsReady(shiva) and Ability.IsCastable(shiva,mana) then
			Ability.CastNoTarget(shiva)
			return
		end
		if null and Menu.IsEnabled(StormSpirit.optionNullifier) and Ability.IsReady(null) and Ability.IsCastable(null,mana) then
			Ability.CastTarget(null, enemy)
			return
		end
		if orchid and Menu.IsEnabled(StormSpirit.optionOrchid) and Ability.IsReady(orchid) and Ability.IsCastable(orchid,mana) then
			Ability.CastTarget(orchid, enemy)
			return
		end
	end
end

function StormSpirit.checkProtection(enemy)
	if NPC.IsLinkensProtected(enemy) then return "LINKEN" end
	local spell_shield = NPC.GetAbility(enemy, "antimage_spell_shield")
	if spell_shield and Ability.IsReady(spell_shield) and (NPC.HasModifier(enemy, "modifier_item_ultimate_scepter") or NPC.HasModifier(enemy, "modifier_item_ultimate_scepter_consumed")) then
		return "LINKEN"
	end
	if NPC.GetAbility(enemy,"special_bonus_unique_queen_of_pain") then return "IMMUNE" end
	if NPC.HasModifier(enemy,"modifier_dark_willow_shadow_realm_buff") then return "IMMUNE" end
	if NPC.HasModifier(enemy,"modifier_skeleton_king_reincarnation_scepter_active") then return "IMMUNE" end
	if NPC.HasState(enemy,Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then return "IMMUNE" end
    if NPC.HasState(enemy,Enum.ModifierState.MODIFIER_STATE_OUT_OF_GAME) then return "IMMUNE" end  
	return false
end

function StormSpirit.SleepReady(sleep, lastTick)
    if (os.clock() - lastTick) >= sleep then
        return true
    end
    return false
end

function StormSpirit.castPrediction(myHero, enemy, enemy_origin, time)
	local enemyRotation = Entity.GetRotation(enemy):GetVectors()
	enemyRotation:SetZ(0)
	local enemyOrigin = enemy_origin
	enemyOrigin:SetZ(0)

	if enemyRotation and enemyOrigin then
		if not NPC.IsRunning(enemy) then
			return enemyOrigin
		else 
			return enemyOrigin:__add(enemyRotation:Normalized():Scaled(NPC.GetMoveSpeed(enemy) * time))
		end
	end
end

function StormSpirit.calc(myHero, myMana, pos)
	if not ult or ult == 0 then return 0 end
	local my_pos = Entity.GetAbsOrigin(myHero)
	local mouse_pos = pos
	local ultimate_pos =  mouse_pos - my_pos
	local regen = NPC.GetManaRegen(myHero)
	if Menu.GetValue(StormSpirit.drawPlace) == 0 then
		w, h = Renderer.GetScreenSize()
		x = Menu.GetValue(StormSpirit.optionDrawingX) / 100
		y = Menu.GetValue(StormSpirit.optionDrawingY) / 100
	else
		w, h = Input.GetCursorPos()
		x = 1
		y = 1
		w = w - 80
	end
	local outsizeWidth = 140
	local insizeWidth = 131
	local speedUltimate = Ability.GetLevelSpecialValueForFloat(ult, "ball_lightning_move_speed")
	local manaForUnits = NPC.GetMaxMana(myHero) * 0.007 + 12
	local manaStartUltimate = manaStartUltimateConst + (manaStartUltimatePerc / 100) * NPC.GetMaxMana(myHero)
	local time_ultimate_to_point = math.ceil((ultimate_pos:Length() / speedUltimate * 100)) / 100
	local loss_mana = NPC.GetMana(myHero) - (ultimate_pos:Length() / 100) * manaForUnits - manaStartUltimate + regen*time_ultimate_to_point

	if cm_reduction  then loss_mana = loss_mana * 0.86 end
	if kaya then loss_mana = loss_mana * 0.9 end
	if arcaneRune then loss_mana = loss_mana * 0.7 end

	damage = (math.floor((ultimate_pos:Length() / 100))-1) * (4+(Ability.GetLevel(ult)*4))
	if damage < 0 then damage = 0 end
	return time_ultimate_to_point, loss_mana, damage,outsizeWidth, insizeWidth
end

function StormSpirit.OnDraw()
	if not Menu.IsEnabled(StormSpirit.optionEnable) or not Engine.IsInGame() or heroName ~= "npc_dota_hero_storm_spirit" or not x or x == 0 then
		if targetParticle ~= 0 then
			Particle.Destroy(targetParticle)			
			targetParticle = 0
		end
		return
	end
	if Menu.IsEnabled(StormSpirit.drawing) then
		Renderer.SetDrawColor(0, 0, 0, 170 )
		Renderer.DrawFilledRect(math.ceil(w*x-outsizeWidth/2), math.ceil(h*y), outsizeWidth, 54)	
		Renderer.SetDrawColor(57, 57, 57, 170)
		Renderer.DrawFilledRect(math.ceil(w*x-insizeWidth/2), math.ceil(h*y+3), insizeWidth, 48)
		Renderer.SetDrawColor(255, 255, 255, 255)
		if loss_mana < 0 then
			Renderer.SetDrawColor(255, 11, 11, 255)
		end
		StormSpirit.DrawTextCentered(StormSpirit.fontItem, math.ceil(w*x), math.ceil(h*y+10),"Мана: " .. math.ceil(loss_mana), 255)
		Renderer.SetDrawColor(255, 255, 255, 255)
		StormSpirit.DrawTextCentered(StormSpirit.fontItem, math.ceil(w*x), math.ceil(h*y+25),"Время: " .. time_ultimate_to_point, 255)
		StormSpirit.DrawTextCentered(StormSpirit.fontItem, math.ceil(w*x), math.ceil(h*y+40),"Урон: " .. math.ceil(damage), 255)	
	end
	local enemyStatus = (enemy and enemy~= 0)
	if Menu.IsEnabled(StormSpirit.targetIndicator)	then
		local particleEnemy = enemy
		if (not particleEnemy and targetParticle ~= 0) or not enemyStatus then
			Particle.Destroy(targetParticle)			
			targetParticle = 0
			particleEnemy = enemy
		else
			if targetParticle == 0 and enemyStatus then
				targetParticle = Particle.Create("particles/ui_mouseactions/range_finder_tower_aoe.vpcf", Enum.ParticleAttachment.PATTACH_INVALID, enemy)				
			end
			if targetParticle ~= 0 and enemyStatus then
				Particle.SetControlPoint(targetParticle, 2, Entity.GetOrigin(myHero))
				Particle.SetControlPoint(targetParticle, 6, Vector(1, 0, 0))
				Particle.SetControlPoint(targetParticle, 7, Entity.GetOrigin(enemy))
			end
		end
	else
		if targetParticle ~= 0 then
			Particle.Destroy(targetParticle)			
			targetParticle = 0
		end
	end

end

function StormSpirit.DrawTextCentered(p1, p2, p3, p4, p5)
	local wide, tall = Renderer.GetTextSize(p1, p4)
	return Renderer.DrawText(p1, p2 - wide/2 , p3 - tall/2, p4)
end

function StormSpirit.Zeroing()
	w, h = 0
	x = 0
	y = 0
	outsizeWidth = 0
	insizeWidth = 0
	loss_mana = 0
	time_ultimate_to_point = 0
	damage = 0
	myHero = nil
	heroName = nil
	myPlayer = nil
	myTeam = nil
	cm_in_team = false
	cm_talant = false
	ult = nil
	remnant = nil
	vortex = nil
	arcaneRune = false
	kaya = false
	cm_reduction = false
	manaStartUltimatePerc  = 0
	manaStartUltimateConst = 0
	targetParticle = 0
	aghanim = nil
end

function StormSpirit.Init()
	if Engine.IsInGame() then
		myHero = Heroes.GetLocal()
		heroName = NPC.GetUnitName(myHero)
		myPlayer = Players.GetLocal()
		cm_in_team = StormSpirit.FindCM()
		myTeam = Entity.GetTeamNum(myHero)
	else
		StormSpirit.Zeroing()
	end
end


function StormSpirit.OnGameStart()
	StormSpirit.Zeroing()
	StormSpirit.Init()
end
function StormSpirit.OnGameEnd()
	StormSpirit.Zeroing()
end


function StormSpirit.FindCM()
	local AllHeroes = Heroes.GetAll()
	for i, hero in pairs(AllHeroes) do
		if hero ~= nil and Entity.IsHero(hero) and Entity.IsSameTeam(myHero, hero) and NPC.GetAbility(hero, "crystal_maiden_brilliance_aura") then
			return true
		end
	end
	return false
end

function StormSpirit.FindCMTalant()
	if os.clock() < last_update then return end
	local aura_modifier = NPC.GetModifier(myHero, "modifier_crystal_maiden_brilliance_aura_effect")
	if aura_modifier and aura_modifier ~= 0 then
		local aura_ability = Modifier.GetAbility(aura_modifier)
		local cm_hero = Ability.GetOwner(aura_ability)
		if NPC.GetAbility(cm_hero,"special_bonus_unique_crystal_maiden_4") then 
			cm_talant = true
		end
	end
	last_update = os.clock() + 1
end

StormSpirit.Init()


return StormSpirit