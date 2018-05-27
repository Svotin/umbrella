local axe = {}

axe.optionEnable = Menu.AddOptionBool({"Hero Specific", "Axe"}, "AutoUlt", false)
axe.customRange = Menu.AddOptionSlider({"Hero Specific", "Axe"}, "customRange", 120, 300, 120)
axe.myHero = nil


function axe.OnUpdate()
	if not Menu.IsEnabled(axe.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	axe.myHero = Heroes.GetLocal()
	if NPC.GetUnitName(axe.myHero) ~= "npc_dota_hero_axe" then return end
	if not Entity.IsAlive(axe.myHero) or NPC.IsStunned(axe.myHero) or NPC.IsSilenced(axe.myHero)  then return end
	local ulti = NPC.GetAbility(axe.myHero, "axe_culling_blade")
	if not Ability.IsReady(ulti) then return end
	local AllHeroes = Heroes.GetAll()
	local lvlUlti = Ability.GetLevel(ulti)
	local damage = 175 + (75*lvlUlti)
	local mana = Ability.GetManaCost(ulti)
	local customRange = Menu.GetValue(axe.customRange)
	local castRange = Ability.GetCastRange(ulti) + customRange
	for _,hero in pairs(AllHeroes) do
		if hero ~= nil and hero ~= 0 and NPCs.Contains(hero) and NPC.IsEntityInRange(axe.myHero, hero,castRange) and not Entity.IsSameTeam(hero,axe.myHero) then
			if Entity.IsAlive(hero) and not Entity.IsDormant(hero) and not NPC.IsIllusion(hero) then 
				if Entity.GetHealth(hero) <= damage and mana <= NPC.GetMana(axe.myHero) then
					Ability.CastTarget(ulti, hero)
				end
			end
		end
	end
end

return axe