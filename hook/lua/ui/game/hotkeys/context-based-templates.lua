-------------------------------------------------------------------------------
-- Context Templates Expanded mod

local UserTemplates = import("/lua/ContextTemplatesExpanded/UserTemplates.lua")

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
