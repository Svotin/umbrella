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
			return
		end
	end
	if Menu.IsKeyDownOnce(Aggro.deaggroKey) then
		alliedCreep = Input.GetNearestUnitToCursor(Entity.GetTeamNum(Aggro.myhero), Enum.TeamType.TEAM_FRIEND)
		if alliedCreep then
			Player.AttackTarget(Players.GetLocal(), Aggro.myhero, alliedCreep)
			return			
		end
	end
end


return Aggro