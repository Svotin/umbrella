local Abuse = {}

local myHero, myPlayer, basher = nil, nil, nil;
local lastIteration, lastBash = 0, 0; 
local time = os.clock;
local update_rate = 0.3;

local MainOption = Menu.AddOptionBool({"Utility", "Abyssal Abuse"}, "Enable", false);
local ToggleKey = Menu.AddKeyOption({"Utility", "Abyssal Abuse"}, "Toggle Key", Enum.ButtonCode.KEY_NONE);
Menu.AddMenuIcon({"Utility", "Abyssal Abuse"}, "panorama/images/items/".."abyssal_blade".."_png.vtex_c");

function Abuse.OnUpdate()
	if (Menu.IsKeyDownOnce(ToggleKey)) then
		Menu.SetEnabled(MainOption, not Menu.IsEnabled(MainOption));
	end;

	if (not Menu.IsEnabled(MainOption)) then
		myHero = nil;
		return;
	end;
	if (not myHero) then
		myHero = Heroes.GetLocal();
		return;
	end;

	if (not myPlayer) then
		myPlayer = Players.GetLocal();
		return;
	end;

	if (Abuse.SleepReady(lastIteration, update_rate)) then
		lastIteration = time();
		Abuse.GetBasher(myHero);
	end;
	if (lastBash > 0 and Abuse.SleepReady(lastBash, .05 + NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING))) then
		local items = 
		{
			subBasher = NPC.GetItem(myHero, "item_basher", true), 
			vanguard = NPC.GetItem(myHero, "item_vanguard", true), 
			recipe = NPC.GetItem(myHero, "item_recipe_abyssal_blade", true),
		}; 
		for name, item in pairs(items) do
			if (item and Item.IsCombineLocked(item)) then
				Abuse.CombineUnlock(item);
			end;
		end;
		lastBash = 0;
	end;
end;

function Abuse.CombineUnlock(item)
	Player.PrepareUnitOrders(myPlayer, Enum.UnitOrder.DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK, 0, Vector(0,0,0), item, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero); -- 32 - CombineUnlock order
end;

function Abuse.Disassemble(item)
	Player.PrepareUnitOrders(myPlayer, Enum.UnitOrder.DOTA_UNIT_ORDER_DISASSEMBLE_ITEM, item, Vector(0,0,0), item, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero);
end;

function Abuse.OnParticleCreate(prt)
	if (not basher or not myHero) then
		return;
	end;
	if (prt.name == "generic_minibash" and prt.entityForModifiers == myHero and (Entity.IsHero(prt.entity) or NPC.GetUnitName(prt.entity) == "npc_dota_roshan")
	 and Abuse.HasFreeSlots(myHero, 2) and not NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_STUNNED)) then
		lastBash = time();
		Abuse.Disassemble(basher);
	end;
end;

function Abuse.GetBasher(hero)
	basher = NPC.GetItem(hero, "item_abyssal_blade");
end;

function Abuse.HasFreeSlots(hero, howMuchNeed)
	local count = 0;
	for i = 0, 8 do
		if (not NPC.GetItemByIndex(hero, i)) then
			count = count + 1;
		end;
	end;
	return howMuchNeed <= count; 
end;

function Abuse.SleepReady(variable, delay)
	if (variable + delay <= time()) then
		return true;
	end;
	return false;
end;

return Abuse;
