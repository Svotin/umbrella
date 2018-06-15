Aggro = {}
Aggro.aggroKey = Menu.AddKeyOption({"Utility",  "Aggro/Deaggro"}, "Aggro Key", Enum.ButtonCode.KEY_8)
Aggro.deaggroKey = Menu.AddKeyOption({"Utility",  "Aggro/Deaggro"}, "Deaggro Key", Enum.ButtonCode.KEY_9)

Aggro.myhero = nil

function Aggro.OnUpdate()
	if not Engine.IsInGame() or not Heroes.GetLocal() then return end
	Aggro.myhero = Heroes.GetLocal()
	if not Aggro.myhero or not Entity.IsEntity(Aggro.myhero) then return end
	if Menu.IsKeyDownOnce(Aggro.aggroKey) then
		enemyHero = Input.GetNearestHeroToCursor(Entity.GetTeamNum(Aggro.myhero), Enum.TeamType.TEAM_ENEMY)
		if enemyHero then
			Player.AttackTarget(Players.GetLocal(), Aggro.myhero, enemyHero)
			Player.PrepareUnitOrders(Players.GetLocal(), 10, nil, Vector(), nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_CURRENT_UNIT_ONLY, nil)
			return
		end
	end
	if Menu.IsKeyDownOnce(Aggro.deaggroKey) then
		local npcs = NPCs.GetAll()
		for _,npc in pairs(npcs) do
			if Entity.IsSameTeam(npc, Aggro.myhero) and (NPC.IsHero(npc) or NPC.IsLaneCreep(npc)) and Entity.IsAlive(npc) and not NPC.IsWaitingToSpawn(npc) and npc~=Aggro.myhero then
				if NPC.IsLaneCreep(npc) and Entity.GetMaxHealth(npc)/Entity.GetHealth(npc)>=2 then return end
 				local alliedCreep = npc
				if alliedCreep then
					Player.AttackTarget(Players.GetLocal(), Aggro.myhero, alliedCreep)
					Player.PrepareUnitOrders(Players.GetLocal(), 10, nil, Vector(), nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_CURRENT_UNIT_ONLY, nil)
					return			
				end
			end
		end
	end
end


return Aggro