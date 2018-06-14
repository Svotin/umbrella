FS = {}
FS.optionEnable = Menu.AddOptionBool({ "Utility","Fail Switch"}, "Enable", false)
FS.optionKey = Menu.AddKeyOption({"Utility","Fail Switch"}, "Force Cast Key", Enum.ButtonCode.KEY_T)

FS.ultiRadius = {enigma_black_hole = 420, 
				magnataur_reverse_polarity = 410, 
				faceless_void_chronosphere = 425, 
				axe_berserkers_call = 300}

function FS.OnUpdate()
	if not Menu.IsEnabled(FS.optionEnable) then return true end
	if not Menu.IsKeyDown(FS.optionKey) then return end

	local myHero = Heroes.GetLocal()
	
	local mousePos = Input.GetWorldCursorPos()

	local myMana = NPC.GetMana(myHero)
	local ulti
	if NPC.GetUnitName(myHero) == "npc_dota_hero_axe" then
		ulti = NPC.GetAbilityByIndex(myHero, 0)
	else
		ulti = NPC.GetAbilityByIndex(myHero, 5)
	end
	if ulti and Ability.IsCastable(ulti, myMana) then
		
		local name = Ability.GetName(ulti)

		if name == "enigma_black_hole" or name == "faceless_void_chronosphere" then
        	Ability.CastPosition(ulti, mousePos)
        elseif name == "magnataur_reverse_polarity" or name == "axe_berserkers_call" then
        	Ability.CastNoTarget(ulti)
        end
    end
end

function FS.OnPrepareUnitOrders(orders)
  if not Menu.IsEnabled(FS.optionEnable) then return true end
  if not orders.ability then return true end

    if not (orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION or orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET) then return true end
    local abilityName = Ability.GetName(orders.ability)
    if not (abilityName == "enigma_black_hole" or abilityName == "magnataur_reverse_polarity" or abilityName == "faceless_void_chronosphere" or abilityName == "axe_berserkers_call") then return true end
	local myHero = Heroes.GetLocal()
	local mousePos = Input.GetWorldCursorPos()
    local enemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
	if not enemy or enemy == 0 then return false end
    if abilityName == "magnataur_reverse_polarity" or abilityName == "axe_berserkers_call" then
    	mousePos =  Entity.GetAbsOrigin(myHero)
    end 

    if NPC.IsPositionInRange(enemy, mousePos, FS.ultiRadius[abilityName], 0) then return true end
    return false

end

return FS