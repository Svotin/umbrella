local ShowLinken =  {}

ShowLinken.option = Menu.AddOptionBool({ "Awareness" }, "Show Linkens", false)
ShowLinken.font = Renderer.LoadFont("Tahoma", 20, Enum.FontWeight.BOLD)

function ShowLinken.OnDraw()
    if not Menu.IsEnabled(ShowLinken.option) then return end

    local myHero = Heroes.GetLocal()

    if not myHero then return end
    local AllHeroes = Heroes.GetAll()
    for i,hero in pairs(AllHeroes) do
        if hero and Entity.IsHero(hero) and Entity.IsAlive(hero) and not Entity.IsSameTeam(myHero, hero) and NPC.IsVisible(hero) and ShowLinken.checkProtection(hero) then
            local pos = Entity.GetAbsOrigin(hero)
            local x, y, visible = Renderer.WorldToScreen(pos)

            if visible and pos then
                Renderer.SetDrawColor(255, 0, 255, 255)
                Renderer.DrawText(ShowLinken.font, x, y, "Linkens", 1)
            end
        end
    end
end

function ShowLinken.checkProtection(enemy)
    if NPC.IsLinkensProtected(enemy) then return true end
    local spell_shield = NPC.GetAbility(enemy, "antimage_spell_shield")
    if spell_shield and Ability.IsReady(spell_shield) and (NPC.HasModifier(enemy, "modifier_item_ultimate_scepter") or NPC.HasModifier(enemy, "modifier_item_ultimate_scepter_consumed")) then
        return true
    end
    if NPC.GetAbility(enemy,"special_bonus_unique_queen_of_pain") then return true end
    return false
end

return ShowLinken
