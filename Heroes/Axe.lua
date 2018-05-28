local axe = {}

axe.optionEnable = Menu.AddOptionBool({"Hero Specific", "Axe"}, "Enable", false)
axe.optionAutoUltEnable = Menu.AddOptionBool({"Hero Specific", "Axe", "Auto Culling"}, "Enable", false)
axe.customRange = Menu.AddOptionSlider({"Hero Specific", "Axe", "Auto Culling"}, "Range to Target", 120, 300, 120)
axe.optionKey = Menu.AddKeyOption({"Hero Specific", "Axe"}, "Combo Key", Enum.ButtonCode.KEY_Z)
axe.enemyInRange = Menu.AddOptionSlider({"Hero Specific", "Axe"}, "Closest to mouse range for Combo", 100, 600, 100)
axe.optionEnableBlink = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Blink", false)
axe.optionEnableCrimson = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Crimson Guard", false)
axe.optionEnableHood = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Hood of Defiance", false)
axe.optionEnablePipe = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Pipe of Insight", false)
axe.optionEnableBlademail = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Blade Mail", false)
axe.optionEnableBkb = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "BKB", false)
axe.optionEnableMjolnir = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Mjolnir", false)
axe.optionEnableLotus = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Lotus Orb", false)
axe.optionEnableShiva = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Shiva's Guard", false)

axe.myHero = nil
enemy = nil
Font = Renderer.LoadFont("Tahoma", 22, Enum.FontWeight.BOLD)

function axe.OnUpdate()
	if not Menu.IsEnabled(axe.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	axe.myHero = Heroes.GetLocal()
	if NPC.GetUnitName(axe.myHero) ~= "npc_dota_hero_axe" then return end
	if not Entity.IsAlive(axe.myHero) or NPC.IsStunned(axe.myHero) or NPC.IsSilenced(axe.myHero)  then return end
	if Menu.IsKeyDown(axe.optionKey) then
		if enemy == nil then 
			enemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(axe.myHero), Enum.TeamType.TEAM_ENEMY)
			if not NPC.IsPositionInRange(enemy, Input.GetWorldCursorPos(), Menu.GetValue(axe.enemyInRange), 0) then
				enemy = nil 
			end
		else
			if axe.Combo(axe.myHero, enemy) == false then
				enemy = nil
			end
		end
	end
	if not Menu.IsEnabled(axe.optionAutoUltEnable) then return end
	local ulti = NPC.GetAbility(axe.myHero, "axe_culling_blade")
	local mana = Ability.GetManaCost(ulti)
	if not Ability.IsReady(ulti) then return end
	local AllHeroes = Heroes.GetAll()
	local lvlUlti = Ability.GetLevel(ulti)
	local damage = 175 + (75*lvlUlti)
	local customRange = Menu.GetValue(axe.customRange)
	local castRange = Ability.GetCastRange(ulti) + customRange
	for _,hero in pairs(AllHeroes) do
		if hero ~= nil and hero ~= 0 and NPCs.Contains(hero) and NPC.IsEntityInRange(axe.myHero, hero,castRange) and not Entity.IsSameTeam(hero,axe.myHero) then
			if Entity.IsAlive(hero) and not Entity.IsDormant(hero) and not NPC.IsIllusion(hero) then 
				if Entity.GetHealth(hero) + NPC.GetHealthRegen(hero) <= damage and not NPC.IsLinkensProtected(hero) and mana <= NPC.GetMana(axe.myHero) then
					Ability.CastTarget(ulti, hero)
					break
				end
			end
		end
	end
end


function axe.Combo(myHero,enemy)
	if not enemy then return false end
	if not NPC.IsEntityInRange(myHero, enemy, 1199) then return false end
    local call = NPC.GetAbility(myHero, "axe_berserkers_call")
    local Blademail = NPC.GetItem(myHero, "item_blade_mail", true)
    local blink = NPC.GetItem(myHero, "item_blink", true)
    local bkb = NPC.GetItem(myHero, "item_black_king_bar", true)
    local mjolnir = NPC.GetItem(myHero, "item_mjollnir", true)
    local lotus = NPC.GetItem(myHero, "item_lotus_orb", true)
    local hood = NPC.GetItem(myHero, "item_hood_of_defiance", true)
    local pipe = NPC.GetItem(myHero, "item_pipe", true)
    local crimson = NPC.GetItem(myHero, "item_crimson_guard", true)
    local shiva = NPC.GetItem(myHero, "item_shivas_guard")
    local callManaCost = 0
 --    local callRange = 300
	-- if NPC.HasAbility(myHero, "special_bonus_unique_axe_2") then
	-- 	if Ability.GetLevel(NPC.GetAbility(myHero, "special_bonus_unique_axe_2")) > 0 then
	-- 		callRange = 400
	-- 	end
	-- end
    -- if not NPC.IsEntityInRange(myHero, enemy, callRange) then
    if Ability.IsReady(call) then 
    	callManaCost = Ability.GetManaCost(call)
	end
    local myMana = NPC.GetMana(myHero) - callManaCost

    if Blademail and Menu.IsEnabled(axe.optionEnableBlademail) and Ability.IsCastable(Blademail, myMana) then
      	Ability.CastNoTarget(Blademail)
      	return true
    end
    if bkb and Menu.IsEnabled(axe.optionEnableBkb) and Ability.IsCastable(bkb, myMana) then
      	Ability.CastNoTarget(bkb)
      	return true
    end
    if lotus and Menu.IsEnabled(axe.optionEnableLotus) and Ability.IsCastable(lotus, myMana) then
      	Ability.CastTarget(lotus, myHero)
      	return true
    end
    if mjolnir and Menu.IsEnabled(axe.optionEnableMjolnir) and Ability.IsCastable(mjolnir, myMana) then
      	Ability.CastTarget(mjolnir, myHero)
      	return true
    end
    if pipe and Menu.IsEnabled(axe.optionEnablePipe) and Ability.IsCastable(pipe, myMana) then
      	Ability.CastNoTarget(pipe)
      	return true
    end
    if crimson and Menu.IsEnabled(axe.optionEnableCrimson) and Ability.IsCastable(crimson, myMana) then
      	Ability.CastNoTarget(crimson)
      	return true
    end
    if hood and Menu.IsEnabled(axe.optionEnableHood) and Ability.IsCastable(hood, myMana) then
      	Ability.CastNoTarget(hood)
      	return true
    end
    if shiva and Menu.IsEnabled(axe.optionEnableShiva) and Ability.IsCastable(shiva, myMana) then
      	Ability.CastNoTarget(shiva)
      	return true
    end
    if blink and Menu.IsEnabled(axe.optionEnableBlink) and Ability.IsReady(blink) then
      	Ability.CastPosition(blink, Entity.GetAbsOrigin(enemy))
      	if Ability.IsReady(call) then 
      		Ability.CastNoTarget(call)
      	end
     	return false
    end
    return false
end

function axe.OnDraw()
	if axe.myHero == nil or NPC.GetUnitName(axe.myHero) ~= "npc_dota_hero_axe" or not Menu.IsEnabled(axe.optionEnable) then return end
	local target = Input.GetNearestHeroToCursor(Entity.GetTeamNum(axe.myHero), Enum.TeamType.TEAM_ENEMY)
	if target then
		if not NPC.IsPositionInRange(target, Input.GetWorldCursorPos(), Menu.GetValue(axe.enemyInRange), 0) then
			target = nil 
		end
	end
	local x, y = Renderer.GetScreenSize()
	if x == 1920 and y == 1080 then
		x, y = 1150+205, 910+150
	-- elseif x== 1600 and y == 900 then
	-- 	x, y = 950, 755
	-- elseif x== 1366 and y == 768 then
	-- 	x, y = 805, 643
	-- elseif x==1280 and y == 720 then
	-- 	x, y = 752, 600
	-- elseif x==1280 and y == 1024 then
	-- 	x, y = 800, 860
	-- elseif x==1440 and y == 900 then
	-- 	x, y = 870, 755
	-- elseif x== 1680 and y == 1050 then
	-- 	x, y = 1025, 885
	-- end
	-- x = x + 210
	-- y = y + 150
	end
	Renderer.DrawFilledRect(x-15, y-5, 350, 25)
	local msg
	Renderer.SetDrawColor(0, 0, 0)
	if target == nil or target == 0 then 
		msg = "NONE"
	else 
		msg = NPC.GetUnitName(target)
	end
	Renderer.DrawText(Font, x, y, "["..msg.."]")
end

return axe