local Utility = require("scripts/Utility")
local morph = {}

morph.optionEnable = Menu.AddOptionBool({"Hero Specific", "Morph"}, "Enable", false)
morph.AutoShift = Menu.AddOptionBool({"Hero Specific", "Morph"}, "AutoShift", false)
morph.myHero = nil

morph.DangerSkills = {
	{"npc_dota_hero_axe", "axe_berserkers_call", 300},
	{"npc_dota_hero_tidehunter", "tidehunter_ravage", 1250},
	{"npc_dota_hero_enigma", "enigma_black_hole", 720},
	{"npc_dota_hero_magnataur", "magnataur_reverse_polarity", 430},
	{"npc_dota_hero_legion_commander", "legion_commander_duel", 150},
	{"npc_dota_hero_beastmaster", "beastmaster_primal_roar", 600},
	{"npc_dota_hero_faceless_void", "faceless_void_chronosphere", 1100},
	{"npc_dota_hero_batrider", "batrider_flaming_lasso", 170},
	{"npc_dota_hero_slardar", "slardar_slithereen_crush", 355},
	{"npc_dota_hero_centaur", "centaur_hoof_stomp", 345},
	{"npc_dota_hero_sven", "sven_storm_bolt", 600},
	{"npc_dota_hero_bane", "bane_fiends_grip", 625},
	{"npc_dota_hero_pudge", "pudge_dismember", 160},
	{"npc_dota_hero_doom_bringer", "doom_bringer_doom", 550},
	{"npc_dota_hero_disruptor", "disruptor_static_storm", 1450}
}


function morph.OnUpdate()
	if not Menu.IsEnabled(morph.AutoShift) or not Menu.IsEnabled(morph.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	morph.myHero = Heroes.GetLocal()
	if NPC.GetUnitName(morph.myHero) ~= "npc_dota_hero_morphling" then return end
	local shift = NPC.GetAbilityByIndex(morph.myHero, 4)
	local FHeroes = Heroes.GetAll()
	for _,v in pairs(FHeroes) do
		if v and Entity.IsHero(v) and Entity.IsAlive(v) and not Entity.IsSameTeam(morph.myHero, v) and not Entity.IsDormant(v) and not NPC.IsIllusion(v) then
			for i,k in pairs(morph.DangerSkills) do
				if NPC.GetUnitName(v) == k[1] then
					local p1 = NPC.GetAbility(v, k[2])
					if p1 ~= (nil or 0) and Ability.IsInAbilityPhase(p1) then								 
						local p2 = Ability.GetCastPoint(p1)
						if NPC.IsEntityInRange(morph.myHero, v, k[3]) then
							if not Ability.GetToggleState(shift) then
								Ability.Toggle(shift)
										return
							end
						end
					end
				end
			end		
		end
	end
end


return morph