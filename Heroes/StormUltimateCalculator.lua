local StormUltCalculator = {}

StormUltCalculator.optionEnable = Menu.AddOptionBool({"Hero Specific", "Storm Spirit"}, "Enable",false)
StormUltCalculator.optionIcon = Menu.AddOptionIcon({ "Hero Specific","Storm Spirit"}, "panorama/images/heroes/icons/npc_dota_hero_storm_spirit_png.vtex_c")
StormUltCalculator.drawPlace = Menu.AddOptionCombo({"Hero Specific", "Storm Spirit"}, "Drawing Type", {"Static", "Depending on cursor"}, 0)
StormUltCalculator.optionDrawingX = Menu.AddOptionSlider({"Hero Specific", "Storm Spirit"},"X coord", 1, 100, 1)
StormUltCalculator.optionDrawingY = Menu.AddOptionSlider({"Hero Specific", "Storm Spirit"},"Y coord", 1, 100, 1)
StormUltCalculator.fontItem = Renderer.LoadFont("Arial", 18, Enum.FontWeight.EXTRABOLD)


local w, h = 0
local x = 0
local y = 0
local outsizeWidth = 0
local insizeWidth = 0
local loss_mana = 0
local time_ultimate_to_point = 0
local damage = 0

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
---------------------------------------------------------------------------------------------------------------------------
	if Menu.GetValue(StormUltCalculator.drawPlace) == 0 then
		if Input.IsKeyDown(Enum.ButtonCode.KEY_RIGHT) and Menu.GetValue(StormUltCalculator.optionDrawingX) < 100 then
			Menu.SetValue(StormUltCalculator.optionDrawingX, (Menu.GetValue(StormUltCalculator.optionDrawingX)+1))
		elseif Input.IsKeyDown(Enum.ButtonCode.KEY_LEFT) and Menu.GetValue(StormUltCalculator.optionDrawingX) > 1 then
			Menu.SetValue(StormUltCalculator.optionDrawingX, (Menu.GetValue(StormUltCalculator.optionDrawingX)-1))
		elseif Input.IsKeyDown(Enum.ButtonCode.KEY_UP) and Menu.GetValue(StormUltCalculator.optionDrawingY) > 1 then
			Menu.SetValue(StormUltCalculator.optionDrawingY, (Menu.GetValue(StormUltCalculator.optionDrawingY)-1))
		elseif Input.IsKeyDown(Enum.ButtonCode.KEY_DOWN) and Menu.GetValue(StormUltCalculator.optionDrawingY) < 100 then
			Menu.SetValue(StormUltCalculator.optionDrawingY, (Menu.GetValue(StormUltCalculator.optionDrawingY)+1))
		end
	end
---------------------------------------------------------------------------------------------------------------------------
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
	Log.Write(Menu.GetValue(StormUltCalculator.drawPlace))
	if Menu.GetValue(StormUltCalculator.drawPlace) == 0 then
		w, h = Renderer.GetScreenSize()
		x = Menu.GetValue(StormUltCalculator.optionDrawingX) / 100
		y = Menu.GetValue(StormUltCalculator.optionDrawingY) / 100
	else
		w, h = Input.GetCursorPos()
		x = 1
		y = 1
		w = w - 80
	end
	outsizeWidth = 140
	insizeWidth = 131
	local manaStartUltimatePerc = Ability.GetLevelSpecialValueForFloat(ultimate, "ball_lightning_initial_mana_percentage")
	local manaStartUltimateConst = Ability.GetLevelSpecialValueForFloat(ultimate, "ball_lightning_initial_mana_base")
	local arcaneRune = NPC.HasModifier(myHero,"modifier_rune_arcane") 
	local kaya = NPC.GetItem(myHero, "item_kaya", true)
	local speedUltimate = Ability.GetLevelSpecialValueForFloat(ultimate, "ball_lightning_move_speed")
	local manaForUnits = NPC.GetMaxMana(myHero) * 0.007 + 12
	local manaStartUltimate = manaStartUltimateConst + (manaStartUltimatePerc / 100) * NPC.GetMaxMana(myHero)
	time_ultimate_to_point = math.ceil((ultimate_pos:Length() / speedUltimate * 100)) / 100
	loss_mana = NPC.GetMana(myHero) - (ultimate_pos:Length() / 100) * manaForUnits - manaStartUltimate + regen*time_ultimate_to_point
	if kaya then loss_mana = loss_mana*0.9 end
	if arcaneRune then loss_mana = loss_mana * 0.7 end
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