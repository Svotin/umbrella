local axe = {}

axe.optionEnable = Menu.AddOptionBool({"Hero Specific", "Axe"}, "Enable", false)
axe.blinkRadius = Menu.AddOptionBool({"Hero Specific", "Axe"}, "Range of the Blink Distance", false)
axe.optionAutoUltEnable = Menu.AddOptionBool({"Hero Specific", "Axe", "Auto Culling"}, "Enable", false)
axe.customRange = Menu.AddOptionSlider({"Hero Specific", "Axe", "Auto Culling"}, "Range to Target", 120, 300, 120)
axe.optionKey = Menu.AddKeyOption({"Hero Specific", "Axe"}, "Combo Key", Enum.ButtonCode.KEY_Z)
axe.optionEnableBlink = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Blink", false)
axe.optionEnableCrimson = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Crimson Guard", false)
axe.optionEnableHood = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Hood of Defiance", false)
axe.optionEnablePipe = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Pipe of Insight", false)
axe.optionEnableBlademail = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Blade Mail", false)
axe.optionEnableBkb = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "BKB", false)
axe.optionEnableMjolnir = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Mjolnir", false)
axe.optionEnableLotus = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Lotus Orb", false)
axe.optionEnableShiva = Menu.AddOptionBool({"Hero Specific", "Axe", "Combo"}, "Shiva's Guard", false)

AllHeroes = nil
axe.myHero = nil
enemy1 = nil
Font = Renderer.LoadFont("Tahoma", 22, Enum.FontWeight.BOLD)
flagForCall = false  --костыль
axe.sleepers = {}

function axe.OnUpdate()

	if not Menu.IsEnabled(axe.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	axe.myHero = Heroes.GetLocal()
	if NPC.GetUnitName(axe.myHero) ~= "npc_dota_hero_axe" then return end
	if not Entity.IsAlive(axe.myHero) or NPC.IsStunned(axe.myHero) or NPC.IsSilenced(axe.myHero)  then return end
	if Menu.IsKeyDown(axe.optionKey) then 
		enemy1 = Input.GetWorldCursorPos()
		axe.Combo(axe.myHero, enemy1)
	end
	if  Menu.IsEnabled(axe.blinkRadius) then
		Engine.ExecuteCommand("dota_range_display " .. 1200)
	else
		Engine.ExecuteCommand("dota_range_display " .. 0)
	end
	if not Menu.IsEnabled(axe.optionAutoUltEnable) then return end
	local ulti = NPC.GetAbility(axe.myHero, "axe_culling_blade")
	local mana = Ability.GetManaCost(ulti)
	if not Ability.IsReady(ulti) then return end
	AllHeroes = Heroes.GetAll()
	local lvlUlti = Ability.GetLevel(ulti)
	local damage = 175 + (75*lvlUlti)
	local customRange = Menu.GetValue(axe.customRange)
	local castRange = Ability.GetCastRange(ulti) + customRange
	for _,hero in pairs(AllHeroes) do
		if hero ~= nil and hero ~= 0 and NPCs.Contains(hero) and NPC.IsEntityInRange(axe.myHero, hero,castRange) and not Entity.IsSameTeam(hero,axe.myHero) then
			if Entity.IsAlive(hero) and not Entity.IsDormant(hero) and not NPC.IsIllusion(hero) then 
				if Entity.GetHealth(hero) + NPC.GetHealthRegen(hero) <= damage and not axe.checkProtection(hero) and mana <= NPC.GetMana(axe.myHero) and axe.SleepCheck(0.3, "delay") then
					Ability.CastTarget(ulti, hero)
          if NPC.HasModifier(hero,"modifier_skeleton_king_reincarnation_scepter") then
            axe.Sleep(0.3,"delay")
          end
					break
				end
			end
		end
	end
end


function axe.Combo(myHero,enemy)
	if not enemy then return end
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
    local axePos = Entity.GetAbsOrigin(myHero)
    local blinkPos = Vector(enemy:GetX() - axePos:GetX(),enemy:GetY() - axePos:GetY(),enemy:GetZ() - axePos:GetZ())
    local range = (blinkPos:GetX()^2+blinkPos:GetY()^2+blinkPos:GetZ()^2)^(0.5)
	if range > 1199  then return end
    -- if not NPC.IsEntityInRange(myHero, enemy, callRange) then
    local myMana = NPC.GetMana(myHero)
    if NPC.HasModifier(myHero, "modifier_pugna_nether_ward_aura") then 
    if blink and Menu.IsEnabled(axe.optionEnableBlink) and Ability.IsReady(blink) and Ability.IsReady(call) and Ability.IsCastable(call, myMana) then
        Ability.CastPosition(blink,enemy)
        enemy1 = nil
        flagForCall = true
     -- return true
    end
    if flagForCall then
      Ability.CastNoTarget(call)
      flagForCall = false
      enemy1 = nil
      --return false
    end
    end
    if Blademail and Menu.IsEnabled(axe.optionEnableBlademail) and Ability.IsCastable(Blademail, myMana) then
      	Ability.CastNoTarget(Blademail)
      --	return true
    end
    if bkb and Menu.IsEnabled(axe.optionEnableBkb) and Ability.IsCastable(bkb, myMana) then
      	Ability.CastNoTarget(bkb)
      --	return true
    end
    if lotus and Menu.IsEnabled(axe.optionEnableLotus) and Ability.IsCastable(lotus, myMana) then
      	Ability.CastTarget(lotus, myHero)
      --	return true
    end
    if mjolnir and Menu.IsEnabled(axe.optionEnableMjolnir) and Ability.IsCastable(mjolnir, myMana) then
      	Ability.CastTarget(mjolnir, myHero)
      --	return true
    end
    if pipe and Menu.IsEnabled(axe.optionEnablePipe) and Ability.IsCastable(pipe, myMana) then
      	Ability.CastNoTarget(pipe)
      --	return true
    end
    if crimson and Menu.IsEnabled(axe.optionEnableCrimson) and Ability.IsCastable(crimson, myMana) then
      	Ability.CastNoTarget(crimson)
      	--return true
    end
    if hood and Menu.IsEnabled(axe.optionEnableHood) and Ability.IsCastable(hood, myMana) then
      	Ability.CastNoTarget(hood)
      --	return true
    end
    if shiva and Menu.IsEnabled(axe.optionEnableShiva) and Ability.IsCastable(shiva, myMana) then
      	Ability.CastNoTarget(shiva)
      --	return true
    end

    if blink and Menu.IsEnabled(axe.optionEnableBlink) and Ability.IsReady(blink) and Ability.IsReady(call) and Ability.IsCastable(call, myMana) then
      	Ability.CastPosition(blink,enemy)
      	enemy1 = nil
      	flagForCall = true
     --	return true
    end
    if flagForCall then
  		Ability.CastNoTarget(call)
  		flagForCall = false
  		enemy1 = nil
   		--return false
   	end
   	enemy1 = nil
   	flagForCall = false
    return 
end

function axe.checkProtection(enemy)
	if NPC.IsLinkensProtected(enemy) then return true end
	local spell_shield = NPC.GetAbility(enemy, "antimage_spell_shield")
	if spell_shield and Ability.IsReady(spell_shield) and (NPC.HasModifier(enemy, "modifier_item_ultimate_scepter") or NPC.HasModifier(enemy, "modifier_item_ultimate_scepter_consumed")) then
		return true
	end
	if NPC.GetAbility(enemy,"special_bonus_unique_queen_of_pain") then return true end
	if NPC.HasModifier(enemy,"modifier_dark_willow_shadow_realm_buff") then return true end
  if NPC.HasModifier(enemy,"modifier_skeleton_king_reincarnation_scepter_active") then return true end

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

return axe