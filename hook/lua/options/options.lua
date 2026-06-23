-------------------------------------------------------------------------------
-- Context Templates Expanded mod

local UserTemplates = import("/lua/ContextTemplatesExpanded/UserTemplates.lua")

local function InvalidateUserTemplateCache()
    UserTemplates.InvalidateCache()
end

for index, item in ipairs(options.gameplay.items) do
    if item.key == 'gui_visible_template_names' then
        table.insert(options.gameplay.items, index + 1, {
            title = ' Context Templates Expanded',
            type = 'header',
            default = '',
            key = '',
        })
        table.insert(options.gameplay.items, index + 2, {
            title = ' Cross-tier template matching',
            tip = 'Allow user templates to match buildings across upgrade tiers (e.g. T2 shield icon on a T3 shield).',
            key = 'cte_cross_tier_matching',
            type = 'toggle',
            default = 0,
            set = function(key, value, startup)
                InvalidateUserTemplateCache()
            end,
            custom = {
                states = {
                    { text = ' Off', key = 0 },
                    { text = ' On', key = 1 },
                },
            },
        })
        break
    end
end
