local DisPos = {}

DisPos.font = Renderer.LoadFont("Tahoma", 20, Enum.FontWeight.EXTRABOLD)
DisPos.Enable = Menu.AddOptionBool({ "Hero Specific", "Disruptor" }, "Enable", false)
DisPos.optionKey = Menu.AddKeyOption({ "Hero Specific", "Disruptor", }, "Visible toggle key", Enum.ButtonCode.KEY_T)
DisPos.Mode = Menu.AddOptionBool({ "Hero Specific", "Disruptor" }, "Show trace", false)

local pos = {}
local enabled = false
local switch_time = 0
local time = 4
local curr_hero_is_dis = false

function DisPos.OnGameStart()
	DisPos.Init()
end

function DisPos.OnGameEnd()
	pos = {}
	enabled = false
	switch_time = 0
	curr_hero_is_dis = false
end



function DisPos.DrawCircle(UnitPos, radius)
	local x1, y1 = Renderer.WorldToScreen(UnitPos)
	local x4, y4, x3, y3, visible3
	local dergee = 50
	for angle = 0, 360 / dergee do
		x4 = 0 * math.cos(angle * dergee / 57.3) - radius * math.sin(angle * dergee / 57.3)
		y4 = radius * math.cos(angle * dergee / 57.3) + 0 * math.sin(angle * dergee / 57.3)
		x3,y3 = Renderer.WorldToScreen(UnitPos + Vector(x4,y4,0))
		Renderer.DrawLine(x1,y1,x3,y3)
		x1,y1 = Renderer.WorldToScreen(UnitPos + Vector(x4,y4,0))
	end
end

function DisPos.DrawTrace(Index)
	local last_pos
	for i = 0, time, 0.1 do
		if pos[Index][math.floor(GameRules.GetGameTime() * 10) / 10 - time + i] then
			last_pos = pos[Index][math.floor(GameRules.GetGameTime() * 10) / 10 - time + i]
			break
		end
	end
	if not last_pos then
		return
	end
	local x, y = Renderer.WorldToScreen(last_pos)
	for i = 0.1, time, 0.1 do
		if pos[Index][math.floor(GameRules.GetGameTime() * 10) / 10 - time + i] ~= nil then
			local x1, y1 = Renderer.WorldToScreen(pos[Index][math.floor(GameRules.GetGameTime() * 10) / 10 - time + i])
			Renderer.DrawLine(x, y, x1, y1)
			x, y = x1, y1
		end
	end	
end

function DisPos.Init()
	if Engine.IsInGame() then
		myHero = Heroes.GetLocal()
		heroName = NPC.GetUnitName(myHero)
		if heroName and heroName == "npc_dota_hero_disruptor" then
			curr_hero_is_dis = false
		end
	end
end

DisPos.Init()

function DisPos.OnUpdate()
	if not Menu.IsEnabled(DisPos.Enable) or not Engine.IsInGame() or not curr_hero_is_dis then
		return
	end

	if not myHero then
		return
	end

	if Menu.IsKeyDownOnce(DisPos.optionKey) then
		enabled = not enabled
		switch_time = GameRules.GetGameTime()
	end

	if not Menu.IsEnabled(DisPos.Enable) then
		return
	end
	if GameRules.GetGameTime() - switch_time < 0.5 then
		local x, y = Input.GetCursorPos()
		Renderer.SetDrawColor(255, 255, 255, 255)
		if enabled then
			Renderer.DrawText(DisPos.font, x - 20, y - 20, "on", 0)
		else 
			Renderer.DrawText(DisPos.font, x - 20, y - 20, "off", 0)
		end
	end
	for i = 1, Heroes.Count() do
		local Unit = Heroes.Get(i)
		local UnitPos = Entity.GetAbsOrigin(Unit)
		if Entity.IsHero(Unit)
		and Entity.GetTeamNum(Unit) ~= Entity.GetTeamNum(myHero)
		and not NPC.IsIllusion(Unit)
		then
			if pos[Entity.GetIndex(Unit)] == nil then
				pos[Entity.GetIndex(Unit)] = {}
			end
			if GameRules.GetGameTime() - Hero.GetRespawnTime(Unit) < 0 then
				pos[Entity.GetIndex(Unit)][math.floor(GameRules.GetGameTime() * 10) / 10] = pos[Entity.GetIndex(Unit)][math.floor((GameRules.GetGameTime() - 0.1) * 10) / 10]
			else
				if not Entity.IsDormant(Unit) then
					pos[Entity.GetIndex(Unit)][math.floor(GameRules.GetGameTime() * 10) / 10] = UnitPos
				end
			end
			if enabled and NPC.IsEntityInRange(myHero, Unit, 3200) then
				if Menu.IsEnabled(DisPos.Mode) then
					DisPos.DrawTrace(Entity.GetIndex(Unit))
				end
				local last_pos = pos[Entity.GetIndex(Unit)][math.floor(GameRules.GetGameTime() * 10) / 10 - time]
				if last_pos ~= nil then
					local x, y = Renderer.WorldToScreen(last_pos)
					if DisPos.IsOnScreen(x, y) then
						Renderer.SetDrawColor(255, 255, 255, 255)
						DisPos.DrawCircle(last_pos, 48)
						Renderer.DrawText(DisPos.font, x, y, string.sub(NPC.GetUnitName(Unit), 15), 0)
					end
				end
			end
		end
	end
end

function DisPos.IsOnScreen(x, y)
  if (x<0) or (y<0) then return false; end;
  if (x>Renderer.ScreenWidth) or (y>Renderer.ScreenHeight) then return false; end;
  return true;
end;


return DisPos