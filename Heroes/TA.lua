TA = {}

TA.option = Menu.AddOptionBool({"Hero Specific", "Templar Assassin"}, "Enable", false)
TA.optionBlink = Menu.AddOptionBool({"Hero Specific", "Templar Assassin","Items"}, "Blink Dagger", false)
TA.HarrasKey = Menu.AddKeyOption({"Hero Specific", "Templar Assassin"}, "Harras Key", Enum.ButtonCode.KEY_C)
TA.comboKey = Menu.AddKeyOption({"Hero Specific", "Templar Assassin"}, "Combo Key", Enum.ButtonCode.KEY_V)
TA.harrasRange = Menu.AddOptionSlider({"Hero Specific", "Templar Assassin"}, "Harras Range", 50, 600, 100)
TA.optionHints =  Menu.AddOptionBool({"Hero Specific", "Templar Assassin"}, "Show Attack Hints", false)

TA.Orchid = Menu.AddOptionBool({"Hero Specific", "Templar Assassin", "Items"}, "Orchid/Bloodthorn", false)
TA.Nullifier = Menu.AddOptionBool({"Hero Specific", "Templar Assassin", "Items"}, "Nullifier", false)
TA.BKB = Menu.AddOptionBool({"Hero Specific", "Templar Assassin", "Items"}, "Black King Bar", false)

--TA.StackKey = Menu.AddKeyOption({"Hero Specific", "Templar Assassin"}, "Stack Key", Enum.ButtonCode.KEY_X)


TA.CampLocation = {
	radiant_ancient_camp_1 = Vector(112, -1897, 384),
	radiant_ancient_camp_2 = Vector(-3014, -76, 384),
	dire_ancient_camp_1 = Vector(-807, 2290, 384.),
	dire_ancient_camp_2 = Vector(3842, -646, 256),
	radiant_small_camp = Vector(2906, -4601, 256),
	dire_small_camp = Vector(-2787, 4544, 256),
	radiant_mid_camp_1 = Vector(360, -4682, 384),
	radiant_mid_camp_2 = Vector(-515, -3315, 256),
	radiant_mid_camp_3 = Vector(-3711, 844, 256),
	dire_mid_camp_1 = Vector(-1881, 4193, 256),
	dire_mid_camp_2 = Vector(-194, 3401, 256),
	dire_mid_camp_3 = Vector(2557, 78, 384),
	radiant_large_camp_1 = Vector(454, -4353, 256),
	radiant_large_camp_2 = Vector(-1753, -4262, 256),
	radiant_large_camp_3 = Vector(-4740, -338, 256),
	dire_large_camp_1 = Vector(4549, -4353, 256),
	dire_large_camp_2 = Vector(1295, 3335, 384),
	dire_large_camp_3 = Vector(4293, 786, 384)
}

local myHero = nil
local enemy = nil

TA.lastTick = 0
TA.itemDelay = 0
TA.lastItemTick = 0	
local flagForMeld = false
local myAttackRange = 0

function TA.OnUpdate()
	if not Menu.IsEnabled(TA.option) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	myHero = Heroes.GetLocal()
	if NPC.GetUnitName(myHero) ~= "npc_dota_hero_templar_assassin" then return end
	if not Entity.IsAlive(myHero) or NPC.IsStunned(myHero) or NPC.IsSilenced(myHero) then return end

	if Menu.IsKeyDown(TA.comboKey) or Menu.IsKeyDown(TA.HarrasKey) then
		enemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
		if enemy and enemy ~= 0 then
		--	Log.Write(NPC.GetUnitName(enemy))
			TA.TACombo(myHero, enemy)
			return
		end
	end
	-- if Menu.IsKeyDown(TA.StackKey) then 
	-- 	local trap = NPC.GetAbility(myHero, "templar_assassin_psionic_trap")
	-- 	local mouse = Input.GetWorldCursorPos()
	-- 	if TA.InNeutralCamp(mouse) then
	-- 		Ability.CastPosition(trap, mouse)
	-- 	end
	--end

end

function TA.TACombo(myHero, enemy)

	if not Menu.IsEnabled(TA.option) then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	local refraction = NPC.GetAbilityByIndex(myHero, 0)
	local meld = NPC.GetAbilityByIndex(myHero, 1)
	local psionicTrap = NPC.GetAbility(myHero, "templar_assassin_psionic_trap")
	local trap = NPC.GetAbility(myHero, "templar_assassin_trap")

	local blink = NPC.GetItem(myHero, "item_blink", true)
	local nullifier = NPC.GetItem(myHero, "item_nullifier", true)
	local orchid = NPC.GetItem(myHero, "item_orchid", true)
	if not orchid then
		orchid = NPC.GetItem(myHero, "item_bloodthorn", true)
	end
	local bkb = NPC.GetItem(myHero, "item_black_king_bar", true)

	local psiBlades = NPC.GetAbility(myHero, "templar_assassin_psi_blades")

	local myMana = NPC.GetMana(myHero)
	local psiBladesLvl = Ability.GetLevel(psiBlades)
	myAttackRange = myAttackRange + (psiBladesLvl*60)

	local refractionModifier = NPC.GetModifier(myHero, "modifier_templar_assassin_refraction_damage")
	local meldModifier = NPC.GetModifier(myHero, "modifier_templar_assassin_meld")
	if Menu.IsKeyDown(TA.HarrasKey) then
		if TA.TApsiBladesSpill(myHero, enemy, myAttackRange) ~= nil then
			local spillNPC = TA.TApsiBladesSpill(myHero, enemy, myAttackRange)

			Player.AttackTarget(Players.GetLocal(), myHero, spillNPC, false)
			return
		else
			if TA.TApsiBladesSpillBestPos(myHero, enemy, myAttackRange, Menu.GetValue(TA.harrasRange)):__tostring() ~= Vector(0,0,0):__tostring() then
				local movePos = TA.TApsiBladesSpillBestPos(myHero, enemy, myAttackRange, Menu.GetValue(TA.harrasRange))
				if math.abs(movePos:GetX())<7300 and math.abs(movePos:GetY())<7100 and movePos:GetZ()<500 then
					NPC.MoveTo(myHero, movePos, false, false)
					return
				end
			end
		end
	end	
	if Menu.IsKeyDown(TA.comboKey) and Entity.GetHealth(enemy) > 0  then
		if NPC.IsEntityInRange(myHero, enemy, (1200 + myAttackRange/2)) then
			if refraction and Ability.IsCastable(refraction, myMana) then
				Ability.CastNoTarget(refraction)
			end
			if psionicTrap and Ability.IsCastable(psionicTrap, myMana) then
				Ability.CastPosition(psionicTrap, TA.castPrediction(myHero, enemy, Ability.GetCastPoint(psionicTrap) + 0.25 + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)))
				TA.lastTick = os.clock()
				return
			end
			if TA.SleepReady(0.3) and trap and Ability.IsReady(trap) and Ability.SecondsSinceLastUse(psionicTrap) > 0 and Ability.SecondsSinceLastUse(psionicTrap) < 1 then
				Ability.CastNoTarget(trap)
				TA.lastTick = os.clock()
				return
			end
		end
		if not NPC.IsEntityInRange(myHero, enemy, myAttackRange) then
			if TA.SleepReady(0.3) then
				if TA.SleepReady(0.1) and blink and Ability.IsReady(blink) and Menu.IsEnabled(TA.optionBlink) and NPC.IsEntityInRange(myHero, enemy, (1150 + myAttackRange/2)) then
					Ability.CastPosition(blink, (Entity.GetAbsOrigin(enemy) + (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Normalized():Scaled(myAttackRange/2)))
					return
				end
			end
		else
			if bkb and Ability.IsReady(bkb) and Menu.IsEnabled(TA.BKB) then
				Ability.CastNoTarget(bkb)
			end
			if nullifier and Ability.IsCastable(nullifier, myMana) and Menu.IsEnabled(TA.Nullifier) then
				Ability.CastTarget(nullifier,enemy)
			end
			if orchid and Ability.IsCastable(orchid,myMana) and Menu.IsEnabled(TA.Orchid) then
				Ability.CastTarget(orchid,enemy)
			end
			if TA.SleepReady(0.3) and meld and Ability.IsCastable(meld, myMana) then
				TA.noItemCastFor(0.1)
				Ability.CastNoTarget(meld)
				TA.lastTick = os.clock()
				return
			end
			if TA.SleepReady(0.1) and NPC.HasModifier(myHero, "modifier_templar_assassin_meld") then
				Player.AttackTarget(Players.GetLocal(), myHero, enemy, false)
				TA.lastTick = os.clock()
				return
			end
		end
	Player.AttackTarget(Players.GetLocal(), myHero, enemy, false)
	return
	end
end

function TA.isEnemyInSpillRange(myHero, spillNPC, enemy, spillRange)

	if not spillNPC then return false end
	if not enemy then return false end

	if Entity.IsSameTeam(myHero, spillNPC) then
		if Entity.GetHealth(spillNPC) > 0.5 * Entity.GetMaxHealth(spillNPC) then
			return false 
		end
	end

	if NPC.IsRunning(spillNPC) then return false end

	local enemyPos = TA.castPrediction(myHero, enemy, 0.75 + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2))
		enemyPos:SetZ(0)

	local spillNPCpos = Entity.GetAbsOrigin(spillNPC)
		spillNPCpos:SetZ(0)

	local myPos = 	Entity.GetAbsOrigin(myHero)
		myPos:SetZ(0)

	if (spillNPCpos - enemyPos):Length2D() > spillRange then
		return false
	end

	local vecmyHeroTospillNPC = spillNPCpos - myPos
	local vecspillNPCToEnemy = enemyPos - spillNPCpos

	local searchPoint = spillNPCpos + vecmyHeroTospillNPC:Normalized():Scaled(vecspillNPCToEnemy:Length2D())

	if math.floor((enemyPos - searchPoint):Length2D()) <= 37 then
		return true
	end

	return false

end

function TA.TApsiBladesSpillBestPos(myHero, enemy, myAttackRange, searchRange)

	if not myHero then return Vector(0,0,0) end
	if not enemy then return Vector(0,0,0) end

	local myMana = NPC.GetMana(myHero)
	local psiBlades = NPC.GetAbility(myHero, "templar_assassin_psi_blades")
		if not psiBlades then return Vector(0,0,0) end
		if Ability.GetLevel(psiBlades) < 1 then return Vector(0,0,0) end

	local spillRange = Ability.GetLevelSpecialValueFor(psiBlades, "attack_spill_range")

	local enemyPos = TA.castPrediction(myHero, enemy, 0.75 + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2))

	local npcs = Entity.GetUnitsInRadius(myHero, myAttackRange+searchRange, Enum.TeamType.TEAM_BOTH)
		if not npcs or #npcs<1 then return Vector(0,0,0) end

		local spillPos = Vector()
		local minRange = 99999
			
		for _, targetNPC in ipairs(npcs) do
			if targetNPC then
				if Entity.IsNPC(targetNPC) and not Entity.IsDormant(targetNPC) and (NPC.IsCreep(targetNPC) or NPC.IsLaneCreep(targetNPC) or NPC.IsNeutral(targetNPC)) and Entity.IsAlive(targetNPC) and not NPC.IsRunning(targetNPC) and not NPC.IsWaitingToSpawn(targetNPC)then
					local myDisToNPC = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(targetNPC)):Length()
					local myDisToEnemy = (Entity.GetAbsOrigin(myHero) - enemyPos):Length()
					local disEnemyToNPC = (enemyPos - Entity.GetAbsOrigin(targetNPC)):Length()
					if disEnemyToNPC < spillRange - 50 and myDisToNPC < myDisToEnemy then
						if ((Entity.IsSameTeam(myHero, targetNPC) and Entity.GetHealth(targetNPC) < 0.5 * Entity.GetMaxHealth(targetNPC)) or not Entity.IsSameTeam(myHero, targetNPC)) then
							local vecEnemyTospillNPC = Entity.GetAbsOrigin(targetNPC) - enemyPos
							local adjustedNPCPos = Entity.GetAbsOrigin(targetNPC) + vecEnemyTospillNPC:Normalized():Scaled(100)
							local searchPos = adjustedNPCPos + vecEnemyTospillNPC:Normalized():Scaled(myAttackRange - 105)
							local closestPoint = TA.GetClosestPoint(adjustedNPCPos, searchPos, Entity.GetAbsOrigin(myHero), true)
							local myDisToClostestPoint = (Entity.GetAbsOrigin(myHero) - closestPoint):Length()
							if myDisToClostestPoint < searchRange then
								if myDisToClostestPoint < minRange then
									spillPos = closestPoint
									minRange = myDisToClostestPoint
								end
							end
						end
					end
				end
			end
		end

		if spillPos:__tostring() ~= Vector():__tostring() and minRange > 25  then
			return spillPos
			
		end

	return Vector(0,0,0)

end

function TA.TApsiBladesSpill(myHero, enemy, myAttackRange)

	if not myHero then return end
	if not enemy then return end

	local myMana = NPC.GetMana(myHero)
	local psiBlades = NPC.GetAbility(myHero, "templar_assassin_psi_blades")
		if not psiBlades then return end
		if Ability.GetLevel(psiBlades) < 1 then return end

	local spillRange = Ability.GetLevelSpecialValueFor(psiBlades, "attack_spill_range")

	local npcs = Entity.GetUnitsInRadius(myHero, myAttackRange, Enum.TeamType.TEAM_BOTH)
		if npcs == nil or #npcs < 1 then return end

		local spillNPC
			
		for _, targetNPC in pairs(npcs) do
			if targetNPC then
				if Entity.IsNPC(targetNPC) and not Entity.IsDormant(targetNPC) and (NPC.IsCreep(targetNPC) or NPC.IsLaneCreep(targetNPC) or NPC.IsNeutral(targetNPC)) and Entity.IsAlive(targetNPC) and not NPC.IsWaitingToSpawn(targetNPC) then
					if TA.isEnemyInSpillRange(myHero, targetNPC, enemy, spillRange) == true then
						spillNPC = targetNPC
					end
				end
			end
		end

		if spillNPC then
			return spillNPC
		end
	return
end

function TA.SleepReady(sleep)
	if (os.clock() - TA.lastTick) >= sleep then
		return true
	end
	return false
end

function TA.OnDraw()
    if not Menu.IsEnabled(TA.optionHints) then return end

    local myHero = Heroes.GetLocal()

    if not myHero or not Entity.IsAlive(myHero) then return end
    if NPC.GetUnitName(myHero) ~= "npc_dota_hero_templar_assassin" then return end
    local target = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
	if target and target ~= 0 then
		Renderer.SetDrawColor(90, 255, 100)
		if TA.TApsiBladesSpill(myHero, target, myAttackRange) ~= nil then
			local spillNPC = TA.TApsiBladesSpill(myHero, target, myAttackRange)
			local spill_npc_pos = Entity.GetAbsOrigin(spillNPC)

		    local target_pos = Entity.GetAbsOrigin(target)
                
            local dir = spill_npc_pos - target_pos

            dir:SetZ(0)
            dir:Normalize()
            dir:Scale(200)
            local x1, y1, v = Renderer.WorldToScreen(spill_npc_pos)
            local x2, y2 = Renderer.WorldToScreen(spill_npc_pos + dir)
            if v  then
            Renderer.DrawLine(x1, y1, x2, y2)
            end
		end
	end
end

function TA.GetClosestPoint(A,  B,  P, segmentClamp)
	
	A:SetZ(0)
	B:SetZ(0)
	P:SetZ(0)

	local Ax = A:GetX()
	local Ay = A:GetY()
	local Bx = B:GetX()
	local By = B:GetY()
	local Px = P:GetX()
	local Py = P:GetY()

	local AP = P - A
	local AB = B - A

	local APx = AP:GetX()
	local APy = AP:GetY()

	local ABx = AB:GetX()
	local ABy = AB:GetY()

	local ab2 = ABx*ABx + ABy*ABy
	local ap_ab = APx*ABx + APy*ABy

	local t = ap_ab / ab2
 
	if (segmentClamp or true) then
		if (t < 0.0) then
			t = 0.0
		elseif (t > 1.0) then
			t = 1.0
		end
	end
 
	local Closest = Vector(Ax + ABx*t, Ay + ABy * t, 0)
 
	return Closest
end

function TA.noItemCastFor(sec)
	TA.itemDelay = sec
	TA.lastItemTick = os.clock()
end

function TA.castPrediction(myHero, enemy, adjustmentVariable)

  if not myHero then return end
  if not enemy then return end

  local enemyRotation = Entity.GetRotation(enemy):GetVectors()
  enemyRotation:SetZ(0)
  local enemyOrigin = Entity.GetAbsOrigin(enemy)
  enemyOrigin:SetZ(0)

  if enemyRotation and enemyOrigin then
    if not NPC.IsRunning(enemy) then
      return enemyOrigin
    else return enemyOrigin:__add(enemyRotation:Normalized():Scaled(NPC.GetMoveSpeed(enemy) * adjustmentVariable))
    end
  end
end

function TA.InNeutralCamp(pos)
	local range = 150
	for name, location in pairs(TA.CampLocation) do
		local dis = location:__sub(pos):Length()
		if dis <= range then return true end
	end
	return false
end

return TA