-------------------------------------------------------------------------------
-- Context-template hotkey cycle with stable engineer selection.

local SelectionCompat = import('/mods/contexttemplatesexpanded/modules/selection_compat.lua')
local Units = import('/mods/contexttemplatesexpanded/modules/units.lua')

local M = {}

function M.Create(vanilla)
    local getStep = vanilla.getStep
    local setStep = vanilla.setStep
    local templates = vanilla.templates
    local FilterByUnit = vanilla.FilterByUnit
    local FilterByMouse = vanilla.FilterByMouse
    local SortTemplates = vanilla.SortTemplates
    local FindBuildableBlueprintId = vanilla.FindBuildableBlueprintId
    local ConvertTemplate = vanilla.ConvertTemplate
    local Cachedtemplate = vanilla.Cachedtemplate
    local TableGetn = vanilla.TableGetn
    local TableSetn = vanilla.TableSetn
    local TableEmpty = vanilla.TableEmpty
    local TableHash = vanilla.TableHash
    local TableSort = vanilla.TableSort
    local StringFormat = vanilla.StringFormat

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

        if getStep() == 0 then
            for index = 1, TableGetn(templates) do
                templates[index] = nil
            end

            TableSetn(templates, 0)

            local applies = FilterByUnit(buildableUnits, prefix)
            if not applies then
                FilterByMouse(buildableUnits, prefix)
            end

            TableSort(templates, SortTemplates)
        end

        if TableGetn(templates) == 0 then
            print("No templates available")
            SelectionCompat.EndCycle(entityIds, cycleGeneration)
            return
        end

        local count = TableGetn(templates)
        local index = math.mod(getStep(), count) + 1
        local template = templates[index]

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

        setStep(getStep() + 1)

        SelectionCompat.EndCycle(entityIds, cycleGeneration)

        SPEW("Time taken: " .. GetSystemTimeSeconds() - start)
    end
end

return M
