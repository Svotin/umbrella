local StormUltCalculator = {}

StormUltCalculator.optionEnable = Menu.AddOptionBool({"Hero Specific", "Storm Spirit"}, "Enable",false)
StormUltCalculator.optionDrawingX = Menu.AddOptionSlider({"Hero Specific", "Storm Spirit", "Drawing"},"X coord", 1, 100, 1)
StormUltCalculator.optionDrawingY = Menu.AddOptionSlider({"Hero Specific", "Storm Spirit", "Drawing"},"Y coord", 1, 100, 1)
StormUltCalculator.fontItem = Renderer.LoadFont("Arial", 18, Enum.FontWeight.EXTRABOLD)


w, h = 0
x = 0
y = 0
outsizeWidth = 0
insizeWidth = 0
loss_mana = 0
time_ultimate_to_point = 0
damage = 0

function StormUltCalculator.OnGameStart()
	StormUltCalculator.Zeroing()
end
function StormUltCalculator.OnGameStart()
	StormUltCalculator.Zeroing()
end

function StormUltCalculator.OnUpdate()
	if not Menu.IsEnabled(StormUltCalculator.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	local myHero = Heroes.GetLocal()
	if NPC.GetUnitName(myHero) ~= "npc_dota_hero_storm_spirit" then return end
	local myMana = NPC.GetMana(myHero)
	StormUltCalculator.calc(myHero,myMana)
	return
end



function StormUltCalculator.calc(myHero, myMana)
	local ultimate = NPC.GetAbilityByIndex(myHero, 5)
	if not ultimate or ultimate == 0 then return 0 end
	local my_pos = Entity.GetAbsOrigin(myHero)
	local mouse_pos = Input.GetWorldCursorPos()
	local ultimate_pos =  mouse_pos - my_pos
	local regen = NPC.GetManaRegen(myHero)
	w, h = Renderer.GetScreenSize()
	x = Menu.GetValue(StormUltCalculator.optionDrawingX) / 100
	y = Menu.GetValue(StormUltCalculator.optionDrawingY) / 100
	outsizeWidth = 140
	insizeWidth = 131
	local manaStartUltimatePerc = Ability.GetLevelSpecialValueForFloat(ultimate, "ball_lightning_initial_mana_percentage")
	local manaStartUltimateConst = Ability.GetLevelSpecialValueForFloat(ultimate, "ball_lightning_initial_mana_base")
	local speedUltimate = Ability.GetLevelSpecialValueForFloat(ultimate, "ball_lightning_move_speed")
	local manaForUnits = NPC.GetMaxMana(myHero) * 0.007 + 12
	local manaStartUltimate = manaStartUltimateConst + (manaStartUltimatePerc / 100) * NPC.GetMaxMana(myHero)
	time_ultimate_to_point = math.ceil((ultimate_pos:Length() / speedUltimate * 100)) / 100
	loss_mana = NPC.GetMana(myHero) - (ultimate_pos:Length() / 100) * manaForUnits - manaStartUltimate + regen*time_ultimate_to_point
	damage = (math.floor((ultimate_pos:Length() / 100))-1) * (4+(Ability.GetLevel(ultimate)*4))
	if damage < 0 then damage = 0 end
	return
end

function StormUltCalculator.OnDraw()
	if not Menu.IsEnabled(StormUltCalculator.optionEnable) or not Engine.IsInGame() or not Heroes.GetLocal() then return end
	if NPC.GetUnitName(Heroes.GetLocal()) ~= "npc_dota_hero_storm_spirit" then return end
	if not x or x == 0 then return end
	Renderer.SetDrawColor(0, 0, 0, 170 )
	Renderer.DrawFilledRect(math.ceil(w*x-outsizeWidth/2), math.ceil(h*y), outsizeWidth, 54)	
	Renderer.SetDrawColor(57, 57, 57, 170)
	Renderer.DrawFilledRect(math.ceil(w*x-insizeWidth/2), math.ceil(h*y+3), insizeWidth, 48)
	Renderer.SetDrawColor(255, 255, 255, 255)
	if loss_mana < 0 then
		Renderer.SetDrawColor(255, 11, 11, 255)
	end
	StormUltCalculator.DrawTextCentered(StormUltCalculator.fontItem, math.ceil(w*x), math.ceil(h*y+10),"Mana: " .. math.ceil(loss_mana), 255)
	Renderer.SetDrawColor(255, 255, 255, 255)
	StormUltCalculator.DrawTextCentered(StormUltCalculator.fontItem, math.ceil(w*x), math.ceil(h*y+25),"Time: " .. time_ultimate_to_point, 255)
	StormUltCalculator.DrawTextCentered(StormUltCalculator.fontItem, math.ceil(w*x), math.ceil(h*y+40),"Damage: " .. math.ceil(damage), 255)	
end

function StormUltCalculator.DrawTextCentered(p1, p2, p3, p4, p5)
	local wide, tall = Renderer.GetTextSize(p1, p4)
	return Renderer.DrawText(p1, p2 - wide/2 , p3 - tall/2, p4)
end

function StormUltCalculator.Zeroing()
	w, h = 0
	x = 0
	y = 0
	outsizeWidth = 0
	insizeWidth = 0
	loss_mana = 0
	time_ultimate_to_point = 0
	damage = 0
end

return StormUltCalculator