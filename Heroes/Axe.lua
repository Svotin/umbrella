local axe = {}

axe.optionEnable = Menu.AddOptionBool({"Hero Specific", "Axe"}, "Enable", false)
axe.blinkRadius = Menu.AddOptionBool({"Hero Specific", "Axe"}, "Range of the Blink Distance", false)
axe.optionAutoUltEnable = Menu.AddOptionBool({"Hero Specific", "Axe", "Auto Culling"}, "Enable", false)
axe.customRange = Menu.AddOptionSlider({"Hero Specific", "Axe", "Auto Culling"}, "Range to Target", 120, 300, 120)
axe.cullingRange = Menu.AddOptionBool({"Hero Specific", "Axe", "Auto Culling"}, "[debug]Show Auto Culling Range", false)
axe.optionKey = Menu.AddKeyOption({"Hero Specific", "Axe"}, "Combo Key", Enum.ButtonCode.KEY_Z)
axe.blinkType = Menu.AddOptionCombo({"Hero Specific", "Axe"}, "Blink Type", {"Blink to best Position", "Blink to Cursor"}, 0)
axe.comboType = Menu.AddOptionCombo({"Hero Specific", "Axe"}, "Combo Type", {"Blink+Call first", "Items first"}, 1)
axe.optionEnableBlink = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Blink", false)
axe.hunger = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Battle Hanger", false)
axe.optionEnableCrimson = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Crimson Guard", false)
axe.optionEnableHood = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Hood of Defiance", false)
axe.optionEnablePipe = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Pipe of Insight", false)
axe.optionEnableBlademail = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Blade Mail", false)
axe.optionEnableBkb = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "BKB", false)
axe.optionEnableMjolnir = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Mjolnir", false)
axe.optionEnableLotus = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Lotus Orb", false)
axe.optionEnableShiva = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Shiva's Guard", false)

local AllHeroes = nil
axe.myHero = nil
local enemy1 = nil
local flagForCall = false  --костыль
axe.sleepers = {}

function axe.OnUpdate()

	if not Menu.IsEnabled(axe.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	axe.myHero = Heroes.GetLocal()
	if NPC.GetUnitName(axe.myHero) ~= "npc_dota_hero_axe" then return end
	if not Entity.IsAlive(axe.myHero) or NPC.IsStunned(axe.myHero) or NPC.IsSilenced(axe.myHero)  then return end
	if Menu.IsKeyDown(axe.optionKey) then 
    if enemy1 == nil then
      if Menu.GetValue(axe.blinkType) == 0 then
        enemy1 = Input.GetNearestHeroToCursor(Entity.GetTeamNum(axe.myHero), Enum.TeamType.TEAM_ENEMY)
      else
		    enemy1 = Input.GetWorldCursorPos()
      end
    end
		if axe.Combo(axe.myHero, enemy1) then
      enemy1 = nil
    end
	else
    enemy1 = nil
  end
  if axe.SleepCheck(0.5, "items") then
    axe.GetItems(axe.myHero)
    axe.Sleep(0.5 , "items")
  end
  ------------------------------------------------------------------
  local ulti = NPC.GetAbility(axe.myHero, "axe_culling_blade")
  local customRange = Menu.GetValue(axe.customRange)
  local castRange = Ability.GetCastRange(ulti) + customRange
  ------------------------------------------------------------------
	if Menu.IsEnabled(axe.blinkRadius) then
		Engine.ExecuteCommand("dota_range_display " .. 1200)
	elseif Menu.IsEnabled(axe.cullingRange) and ulti then
    Engine.ExecuteCommand("dota_range_display " .. castRange)
  else
		Engine.ExecuteCommand("dota_range_display " .. 0)
	end
	if not Menu.IsEnabled(axe.optionAutoUltEnable) then return end
	local mana = Ability.GetManaCost(ulti)
	if not Ability.IsReady(ulti) then return end
	AllHeroes = Entity.GetHeroesInRadius(axe.myHero, castRange, Enum.TeamType.TEAM_ENEMY)
  if not AllHeroes or #AllHeroes < 1 then return end 
	local lvlUlti = Ability.GetLevel(ulti)
	local damage = 175 + (75*lvlUlti)
	for i = 1, #AllHeroes do
		if AllHeroes[i] ~= nil and AllHeroes[i] ~= 0 then
			if Entity.IsAlive(AllHeroes[i]) and not Entity.IsDormant(AllHeroes[i]) then 
				if Entity.GetHealth(AllHeroes[i]) + NPC.GetHealthRegen(AllHeroes[i]) <= damage and mana <= NPC.GetMana(axe.myHero) and axe.SleepCheck(0.3, "delay") and axe.checkProtection(AllHeroes[i]) ~= "IMMUNE" then
          if axe.checkProtection(AllHeroes[i]) == "LINKEN" then
            local hunger_pop = NPC.GetAbilityByIndex(myHero, 1)
            if hunger_pop and Ability.IsCastable(hunger_pop, NPC.GetMana(axe.myHero)-mana) and not NPC.HasState(AllHeroes[i], Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) and not axe.IsInAbilityPhase(axe.myHero) then
              Ability.CastTarget(hunger_pop, AllHeroes[i])
              break
            end
          else
  					Ability.CastTarget(ulti, AllHeroes[i])
            if NPC.HasModifier(AllHeroes[i],"modifier_skeleton_king_reincarnation_scepter") then
              axe.Sleep(0.3,"delay")
            end
  					break
          end
				end
			end
		end
	end
end


function axe.GetItems(myHero)
  hunger = NPC.GetAbilityByIndex(myHero, 1)
  call = NPC.GetAbility(myHero, "axe_berserkers_call")
  Blademail = NPC.GetItem(myHero, "item_blade_mail", true)
  blink = NPC.GetItem(myHero, "item_blink", true)
  bkb = NPC.GetItem(myHero, "item_black_king_bar", true)
  mjolnir = NPC.GetItem(myHero, "item_mjollnir", true)
  lotus = NPC.GetItem(myHero, "item_lotus_orb", true)
  hood = NPC.GetItem(myHero, "item_hood_of_defiance", true)
  pipe = NPC.GetItem(myHero, "item_pipe", true)
  crimson = NPC.GetItem(myHero, "item_crimson_guard", true)
  shiva = NPC.GetItem(myHero, "item_shivas_guard")
end

function axe.Combo(myHero,enemy)
	if not enemy then return end
  local axePos = Entity.GetAbsOrigin(myHero)
      ---- BLINK TO THE BEST POS ----
  if Menu.GetValue(axe.blinkType) == 0 then
    local callRange = 300
    if NPC.HasAbility(myHero, "special_bonus_unique_axe_2") then
      if Ability.GetLevel(NPC.GetAbility(myHero, "special_bonus_unique_axe_2")) > 0 then
        callRange = 400
      end
    end
    if NPC.IsRunning(enemy) then
      if not blink then
        callRange = callRange - 100
      else
        if Ability.SecondsSinceLastUse(blink) > 0.75 then
          callRange = callRange - 100
        end
      end 
    end 
    enemy = axe.getBestPosition(Heroes.InRadius(Entity.GetAbsOrigin(enemy), callRange * 2, Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY), callRange)
    if not NPC.IsPositionInRange(myHero, enemy, 1200, 0) then return false end
        ---- BLINK TO CURSOR ----
  else
      local blinkPos = Vector(enemy:GetX() - axePos:GetX(),enemy:GetY() - axePos:GetY(),enemy:GetZ() - axePos:GetZ())
      local range = (blinkPos:GetX()^2+blinkPos:GetY()^2+blinkPos:GetZ()^2)^(0.5)
      if range > 1199  then return end
  end
  local myMana = NPC.GetMana(myHero)
  ----------------------------------------------------------------------------------------------------------------------------
       ---- BLINK FIRST ----
  if NPC.HasModifier(myHero, "modifier_pugna_nether_ward_aura") or Menu.GetValue(axe.comboType) == 0 then 
    if blink and Menu.IsEnabled(axe.optionEnableBlink) and Ability.IsReady(blink) and Ability.IsReady(call) and Ability.IsCastable(call, myMana) then
        Ability.CastPosition(blink,enemy)
        enemy1 = nil
        flagForCall = true
        return true
    end
    if flagForCall then
      Ability.CastNoTarget(call)
      flagForCall = false
      enemy1 = nil
      return true
    end
  end
  -----------------------------------------------------------------------------------------------------------
  ---- COMBO ----
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
   -- 	return true
  end
  if hood and Menu.IsEnabled(axe.optionEnableHood) and Ability.IsCastable(hood, myMana) then
    	Ability.CastNoTarget(hood)
   -- 	return true
  end
  if shiva and Menu.IsEnabled(axe.optionEnableShiva) and Ability.IsCastable(shiva, myMana) then
    	Ability.CastNoTarget(shiva)
    	return true
  end
  ---- ITEMS FIRST ----
  if blink and Menu.IsEnabled(axe.optionEnableBlink) and Ability.IsReady(blink) and Ability.IsReady(call) and Ability.IsCastable(call, myMana) then
      Ability.CastPosition(blink,enemy)
    	enemy1 = nil
    	flagForCall = true
   	return true
  end
  if flagForCall then
		Ability.CastNoTarget(call)
		flagForCall = false
		enemy1 = nil
 		return true
 	end
  local nearHero = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
  if hunger and nearHero and Menu.IsEnabled(axe.hunger) and Ability.IsCastable(hunger, myMana - 120) and NPC.IsEntityInRange(myHero, nearHero, Ability.GetCastRange(hunger)) and not NPC.HasState(nearHero, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE)
   and not axe.IsInAbilityPhase(myHero) then 
   Ability.CastTarget(hunger, nearHero)
    flagForCall = false
    enemy1 = nil
   return false
  end
  if axe.SleepCheck(0.5, "attack") and nearHero then
    Player.AttackTarget(Players.GetLocal(), axe.myHero, nearHero, false)
    axe.Sleep(0, "attack")
  end
 	enemy1 = nil
 	flagForCall = false
  return false
end

function axe.checkProtection(enemy)
	if NPC.IsLinkensProtected(enemy) then return "LINKEN" end
	local spell_shield = NPC.GetAbility(enemy, "antimage_spell_shield")
	if spell_shield and Ability.IsReady(spell_shield) and (NPC.HasModifier(enemy, "modifier_item_ultimate_scepter") or NPC.HasModifier(enemy, "modifier_item_ultimate_scepter_consumed")) then
		return "LINKEN"
	end
	if NPC.GetAbility(enemy,"special_bonus_unique_queen_of_pain") then return "IMMUNE" end
	if NPC.HasModifier(enemy,"modifier_dark_willow_shadow_realm_buff") then return "IMMUNE" end
  if NPC.HasModifier(enemy,"modifier_skeleton_king_reincarnation_scepter_active") then return "IMMUNE" end

	return false
end

function axe.SleepCheck(delay, id)
  if not axe.sleepers[id] or (os.clock() - axe.sleepers[id]) > delay then
    return true
  end
  return false
end

function axe.Sleep(delay, id)
  if not axe.sleepers[id] or axe.sleepers[id] < os.clock() + delay then
    axe.sleepers[id] = os.clock() + delay
  end
end

function axe.getBestPosition(unitsAround, radius)

  if not unitsAround or #unitsAround < 1 then
    return 
  end

  local countEnemies = #unitsAround

  if countEnemies == 1 then 
    return Entity.GetAbsOrigin(unitsAround[1]) 
  end

  return axe.getMidPoint(unitsAround)
end

function axe.getMidPoint(entityList)

  if not entityList then return end
  if #entityList < 1 then return end

  local pts = {}
    for i, v in ipairs(entityList) do
      if v and not Entity.IsDormant(v) then
        local pos = Entity.GetAbsOrigin(v)
        local posX = pos:GetX()
        local posY = pos:GetY()
        table.insert(pts, { x=posX, y=posY })
      end
    end
  
  local x, y, c = 0, 0, #pts

    if (pts.numChildren and pts.numChildren > 0) then c = pts.numChildren end

  for i = 1, c do

    x = x + pts[i].x
    y = y + pts[i].y

  end

  return Vector(x/c, y/c, 0)
end

function axe.IsInAbilityPhase(myHero)   --из утилити

    if not myHero then return false end

    local myAbilities = {}

    for i = 0, 10 do
      local ability = NPC.GetAbilityByIndex(myHero, i)
      if ability and Entity.IsAbility(ability) and Ability.GetLevel(ability) > 0 then
        table.insert(myAbilities, ability)
      end
    end

    if #myAbilities < 1 then return false end

    for _, v in ipairs(myAbilities) do
      if v then
          if Ability.IsInAbilityPhase(v) then
            return true
          end
      end
    end
    return false
end

function axe.OnMenuOptionChange(option, oldValue, newValue)
  if option == axe.cullingRange then
    if newValue then
      Menu.SetEnabled(axe.blinkRadius, false)
    end
  end
  if option == axe.blinkRadius then
    if newValue then
      Menu.SetEnabled(axe.cullingRange, false)
    end
  end
  ---- INIT ----
  if not Menu.IsEnabled(axe.optionEnable) then return end
  if option == axe.blinkType or option == axe.comboType then
    enemy1 = nil
    flagForCall = false 
  end
end



return axe