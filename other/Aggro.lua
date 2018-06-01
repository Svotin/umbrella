Aggro = {}
Aggro.aggroKey = Menu.AddKeyOption({"Utility",  "Aggro/Deaggro"}, "Aggro Key", Enum.ButtonCode.KEY_8)
Aggro.deaggroKey = Menu.AddKeyOption({"Utility",  "Aggro/Deaggro"}, "Deaggro Key", Enum.ButtonCode.KEY_9)

myhero = nil

function Aggro.OnUpdate()
	if not Engine.IsInGame() or not Heroes.GetLocal() then return end
	myhero = Heroes.GetLocal()
	if Menu.IsKeyDownOnce(Aggro.aggroKey) then
		enemyHero = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
		if enemyHero then
			Player.AttackTarget(Players.GetLocal(), myhero, enemyHero)
			return
		end
	end
	if Menu.IsKeyDownOnce(Aggro.deaggroKey) then
		alliedCreep = Input.GetNearestUnitToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_FRIEND)
		if alliedCreep then
			Player.AttackTarget(Players.GetLocal(), myhero, alliedCreep)
			return			
		end
	end
end


return Aggro