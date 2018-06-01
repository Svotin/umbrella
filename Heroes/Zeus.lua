Zeus = {}

Zeus.optionEnable = Menu.AddOptionBool({"Hero Specific", "Zeus"}, "Cancel TP's", false)

myHero = nil

tp_index = nil
tp_position = nil
flag = false

function Zeus.OnUpdate()
	if not Menu.IsEnabled(Zeus.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	myHero = Heroes.GetLocal()
	if NPC.GetUnitName(myHero) ~= "npc_dota_hero_zuus" then return end
	local FHeroes = Heroes.GetAll()
	local nimbus = NPC.GetAbility(myHero, "zuus_cloud")

	if Menu.IsEnabled(Zeus.optionEnable) and nimbus then
		if not Entity.IsAlive(myHero) or NPC.IsStunned(myHero) or NPC.IsSilenced(myHero) then  Zeus.ZeroingVars() return end
		if tp_position ~= nil then
			local AllHeroes = Heroes.GetAll()
			for i,hero in pairs( AllHeroes ) do
				if hero and Entity.IsHero(hero) and Entity.IsAlive(hero) and Entity.IsSameTeam(myHero, hero)  then
					heroPos = Entity.GetAbsOrigin(hero) 
					substruct = heroPos:__sub(tp_position)
					result = math.abs (substruct:GetX() + substruct:GetY()+substruct:GetZ())
					if result < 2 then 
						Zeus.ZeroingVars()
						return 
					end
				end
			end
			if Ability.IsReady(nimbus) and Ability.GetManaCost(nimbus)<=NPC.GetMana(myHero) then
				Ability.CastPosition(nimbus, tp_position)
				Zeus.ZeroingVars()
				return
			end
		end
	end
end


function Zeus.OnParticleCreate(particle)
	if particle.name == "teleport_start" then 
		tp_index = particle.index
	end
end


function Zeus.OnParticleUpdate( particle )
	if particle.controlPoint ~= 0 then return end
	if tp_index == particle.index then 
		if tp_position ~= nil or flag == true then return end
		tp_position = particle.position
		flag = true
	end
end

function Zeus.ZeroingVars()
	tp_index = nil
	tp_position = nil
	flag = false
end

return Zeus