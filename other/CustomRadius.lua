local radius = {}

radius.optionEnable = Menu.AddOptionBool({"Utility", "Custom Radius"}, "Enable1", false)
radius.customRadius = Menu.AddOptionSlider({"Utility", "Custom Radius"}, "Radius1", 0, 3000, 1500)


function radius.OnUpdate()
	if not Engine.IsInGame() or not Heroes.GetLocal() then return end
	if  Menu.IsEnabled(radius.optionEnable) then
		Engine.ExecuteCommand("dota_range_display " .. Menu.GetValue(radius.customRadius))
	else
		Engine.ExecuteCommand("dota_range_display " .. 0)
	end
end

return radius