-------------------------------------------------------------------------------
-- Context Templates Expanded: hook wiring for context-based template cycling.

local UserTemplates = import("/lua/ContextTemplatesExpanded/UserTemplates.lua")
local CycleMod = import('/mods/contexttemplatesexpanded/modules/cycle.lua')

UserTemplates.Install({
    ConvertBlueprintId = ConvertBlueprintId,
    FindBuildableBlueprintId = FindBuildableBlueprintId,
    TableInsert = TableInsert,
    TableGetn = TableGetn,
    type = type,
    ContextBasedTemplates = ContextBasedTemplates,
    FilterByUnit = FilterTemplatesByUnitContext,
    FilterByMouse = FilterTemplatesByMouseContext,
})

FilterTemplatesByUnitContext = UserTemplates.FilterTemplatesByUnitContext
FilterTemplatesByMouseContext = UserTemplates.FilterTemplatesByMouseContext
SortTemplates = UserTemplates.SortTemplates

Cycle = CycleMod.Create({
    getStep = function()
        return ContextBasedTemplateStep
    end,
    setStep = function(step)
        ContextBasedTemplateStep = step
    end,
    templates = ContextBasedTemplates,
    FilterByUnit = FilterTemplatesByUnitContext,
    FilterByMouse = FilterTemplatesByMouseContext,
    SortTemplates = SortTemplates,
    FindBuildableBlueprintId = FindBuildableBlueprintId,
    ConvertTemplate = ConvertTemplate,
    Cachedtemplate = Cachedtemplate,
    TableGetn = TableGetn,
    TableSetn = TableSetn,
    TableEmpty = TableEmpty,
    TableHash = TableHash,
    TableSort = TableSort,
    StringFormat = StringFormat,
})
