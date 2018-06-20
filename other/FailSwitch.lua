FS = {}
FS.optionEnable = Menu.AddOptionBool({ "Utility","Fail Switch"}, "Enable", false)
FS.optionKey = Menu.AddKeyOption({"Utility","Fail Switch"}, "Force Cast Key", Enum.ButtonCode.KEY_T)

FS.abilityRadius = {
						-- HERO NAME            ABILITY NAME     RADIUS  ABILITY INDEX     NOTARGET
					{"npc_dota_hero_tidehunter", "tidehunter_ravage", 1250,      5, 	    true},
					{"npc_dota_hero_enigma","enigma_black_hole", 420, 5, false}, 
					{"npc_dota_hero_faceless_void","faceless_void_chronosphere", 425, 5, false},
					{"npc_dota_hero_axe","axe_berserkers_call", 300, 0, true},
					{"npc_dota_hero_magnataur", "magnataur_reverse_polarity", 410, 5 ,true},
					{"npc_dota_hero_slardar", "slardar_slithereen_crush", 355, 0, true},
					{"npc_dota_hero_centaur", "centaur_hoof_stomp", 345, 0, true},
					{"npc_dota_hero_disruptor","disruptor_static_storm",450, 5, false},
					{"npc_dota_hero_treant", "treant_overgrowth", 800, 5, true} 
				}
FS.stopAnimation = false

function FS.OnPrepareUnitOrders(orders)
 	if not Menu.IsEnabled(FS.optionEnable) then return true end
  	if not orders.ability then return true end
	if not (orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION or orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET) then return true end
	local abilityName = Ability.GetName(orders.ability)
	for _,h in pairs(FS.abilityRadius) do
		if abilityName == h[2] then
			local myHero = Heroes.GetLocal()
			local mousePos = Input.GetWorldCursorPos()
	    	local enemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
			if not enemy or enemy == 0 then 
				FS.stopAnimation = true
				return false 
			end
			if h[5] then
				mousePos = Entity.GetAbsOrigin(myHero)
			end
			if NPC.IsPositionInRange(enemy, mousePos, h[3], 0) then 
				return true 
			else 
				FS.stopAnimation = true
				return false
			end	
		end
	end
	return true
end


function FS.OnUpdate()
	if not Engine.IsInGame() or not Heroes.GetLocal() then return end
	if not Menu.IsEnabled(FS.optionEnable) then return end
	local myHero = Heroes.GetLocal()
	if Menu.IsKeyDown(FS.optionKey) then 
		local mousePos = Input.GetWorldCursorPos()
		local myMana = NPC.GetMana(myHero)
		local ability

		for _,h in pairs(FS.abilityRadius) do
			if NPC.GetUnitName(myHero) == h[1] then
				ability = NPC.GetAbilityByIndex(myHero, h[4])
				if ability and Ability.IsCastable(ability, myMana) then
					if h[5] then
						Ability.CastNoTarget(ability)

						return
					else
						Ability.CastPosition(ability, mousePos)
						return
					end
				end
			end
		end
	end
	if FS.stopAnimation then
		Player.HoldPosition(Players.GetLocal(), myHero)
		FS.stopAnimation = not FS.stopAnimation
	end
	return
end

return FS
