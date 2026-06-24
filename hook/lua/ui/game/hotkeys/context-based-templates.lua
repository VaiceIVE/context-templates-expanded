-------------------------------------------------------------------------------
-- Context Templates Expanded: hook wiring for context-based template cycling.

local UserTemplates = import('/mods/contexttemplatesexpanded/modules/user_templates.lua')
local CycleMod = import('/mods/contexttemplatesexpanded/modules/cycle.lua')

local filters = UserTemplates.Create({
    filterByUnit = FilterTemplatesByUnitContext,
    filterByMouse = FilterTemplatesByMouseContext,
    sortTemplates = SortTemplates,
})

FilterTemplatesByUnitContext = filters.filterByUnit
FilterTemplatesByMouseContext = filters.filterByMouse
SortTemplates = filters.sort

Cycle = CycleMod.Create()
