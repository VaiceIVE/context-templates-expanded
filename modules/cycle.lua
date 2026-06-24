-------------------------------------------------------------------------------
-- Context-template hotkey cycle with stable engineer selection.

local SelectionCompat = import('/mods/contexttemplatesexpanded/modules/selection_compat.lua')
local Units = import('/mods/contexttemplatesexpanded/modules/units.lua')

local M = {}

function M.Create()
    return function()
        local start = GetSystemTimeSeconds()

        local selectedUnits = GetSelectedUnits()
        if not selectedUnits or TableEmpty(selectedUnits) then
            return
        end

        local entityIds = Units.SnapshotEntityIds(selectedUnits)
        local _, _, buildableCategories = GetUnitCommandData(selectedUnits)
        local buildableUnits = TableHash(EntityCategoryGetUnitList(buildableCategories))

        if TableEmpty(buildableUnits) then
            print("No templates available")
            return
        end

        local prefix = Units.ResolvePrefix(selectedUnits)

        local cycleGeneration = SelectionCompat.BeginCycle(entityIds)

        if ContextBasedTemplateStep == 0 then
            for index = 1, TableGetn(ContextBasedTemplates) do
                ContextBasedTemplates[index] = nil
            end

            TableSetn(ContextBasedTemplates, 0)

            local applies = FilterTemplatesByUnitContext(buildableUnits, prefix)
            if not applies then
                FilterTemplatesByMouseContext(buildableUnits, prefix)
            end

            TableSort(ContextBasedTemplates, SortTemplates)
        end

        if TableGetn(ContextBasedTemplates) == 0 then
            print("No templates available")
            SelectionCompat.EndCycle(entityIds, cycleGeneration)
            return
        end

        local count = TableGetn(ContextBasedTemplates)
        local index = math.mod(ContextBasedTemplateStep, count) + 1
        local template = ContextBasedTemplates[index]

        if template then
            local buildableBlueprintId = FindBuildableBlueprintId(
                template.TemplateData[3][1],
                buildableUnits,
                prefix
            ) --[[@as string]]

            SelectionCompat.ApplyTemplateCommand(
                buildableBlueprintId,
                ConvertTemplate(template, buildableUnits, prefix, Cachedtemplate),
                TableGetn(template.TemplateData),
                entityIds
            )

            print(StringFormat("(%d/%d) %s", index, count, tostring(template.Name)))
        end

        ContextBasedTemplateStep = ContextBasedTemplateStep + 1

        SelectionCompat.EndCycle(entityIds, cycleGeneration)

        SPEW("Time taken: " .. GetSystemTimeSeconds() - start)
    end
end

return M
