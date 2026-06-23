-------------------------------------------------------------------------------
-- Context Templates Expanded mod

do
    local BuildTemplates = import("/lua/ui/game/build_templates.lua")
    local CommandMode = import("/lua/ui/game/commandmode.lua")
    local UIUtil = import("/lua/ui/uiutil.lua")
    local StringLower = string.lower
    local StringLen = string.len

    local USER_SORT_BASE = 100000

    local _FilterByUnit = FilterTemplatesByUnitContext
    local _FilterByMouse = FilterTemplatesByMouseContext
    local _SortTemplates = SortTemplates

    local function IsBlueprintId(blueprintId)
        return type(blueprintId) == 'string'
            and StringLen(blueprintId) >= 6
            and __blueprints[blueprintId] ~= nil
    end

    --- Same blueprint resolution order as vanilla FilterTemplatesByUnitContext.
    local function GetUnitContextBlueprintId()
        local commandMode = CommandMode.GetCommandMode()
        local blueprintId = commandMode[2] and commandMode[2].name

        if not blueprintId then
            local highlightCommand = GetHighlightCommand()
            if highlightCommand and highlightCommand.blueprintId then
                blueprintId = highlightCommand.blueprintId
            end
        end

        if not blueprintId then
            local info = GetRolloverInfo()
            if info.userUnit and info.blueprintId then
                blueprintId = info.blueprintId
            end
        end

        if IsBlueprintId(blueprintId) then
            return blueprintId
        end

        return nil
    end

    --- Icon building must match hovered building (faction conversion or same unit suffix).
    local function BlueprintsMatch(referenceBlueprintId, contextBlueprintId, prefix)
        if not IsBlueprintId(referenceBlueprintId) or not IsBlueprintId(contextBlueprintId) then
            return false
        end

        local referenceConverted = ConvertBlueprintId(referenceBlueprintId, prefix)
        local contextConverted = ConvertBlueprintId(contextBlueprintId, prefix)

        if referenceConverted == contextConverted then
            return true
        end

        return referenceBlueprintId:sub(3) == contextBlueprintId:sub(3)
    end

    --- Same reference building as the construction templates tab (icon, then first valid icon in queue, then first entry).
    local function GetTemplateReferenceBlueprint(userTemplate)
        local icon = userTemplate.icon
        if icon and icon ~= 'default' and IsBlueprintId(icon) then
            return icon
        end

        local templateData = userTemplate.templateData
        if not templateData then
            return nil
        end

        for index = 3, TableGetn(templateData) do
            local entry = templateData[index]
            if type(entry) == 'table' then
                local blueprintId = entry[1]
                if IsBlueprintId(blueprintId)
                    and UIUtil.UIFile('/icons/units/' .. blueprintId .. '_icon.dds', true) then
                    return blueprintId
                end
            end
        end

        local first = templateData[3]
        local blueprintId = first and first[1]
        if IsBlueprintId(blueprintId) then
            return blueprintId
        end

        return nil
    end

    local function UserTemplateMatchesBuilding(userTemplate, contextBlueprintId, prefix)
        local referenceBlueprint = GetTemplateReferenceBlueprint(userTemplate)
        return referenceBlueprint
            and BlueprintsMatch(referenceBlueprint, contextBlueprintId, prefix)
    end

    local function UserValidateTemplate(template, buildableUnits, prefix)
        local templateData = template.TemplateData
        for index = 3, TableGetn(templateData) do
            local entry = templateData[index]
            if type(entry) == 'table' and not FindBuildableBlueprintId(entry[1], buildableUnits, prefix) then
                return false
            end
        end
        return true
    end

    local function CopyTemplateData(templateData)
        local copy = { templateData[1], templateData[2] }
        for index = 3, TableGetn(templateData) do
            local entry = templateData[index]
            if type(entry) == 'table' then
                copy[index] = { entry[1], entry[2], entry[3], entry[4] }
            end
        end
        return copy
    end

    local function TemplateFingerprint(templateData)
        local parts = {}
        local count = 0
        for index = 3, TableGetn(templateData) do
            local entry = templateData[index]
            if type(entry) == 'table' then
                count = count + 1
                parts[count] = string.format(
                    '%s:%d:%g:%g',
                    entry[1],
                    entry[2],
                    entry[3],
                    entry[4]
                )
            end
        end
        return table.concat(parts, ';')
    end

    local function AppendUserTemplates(buildableUnits, prefix, contextBlueprintId)
        if not contextBlueprintId then
            return
        end

        local userTemplates = BuildTemplates.GetTemplates() or {}
        local userIndex = 0
        local seen = {}

        for index = 1, TableGetn(userTemplates) do
            local userTemplate = userTemplates[index]
            local templateData = userTemplate and userTemplate.templateData
            if templateData and TableGetn(templateData) >= 3 then
                local fingerprint = TemplateFingerprint(templateData)
                if fingerprint ~= '' and not seen[fingerprint] then
                    seen[fingerprint] = true

                    if UserTemplateMatchesBuilding(userTemplate, contextBlueprintId, prefix) then
                        userIndex = userIndex + 1
                        local entry = {
                            Name = userTemplate.name or ('Template ' .. userIndex),
                            TemplateData = CopyTemplateData(templateData),
                            TemplateSortingOrder = USER_SORT_BASE + userIndex,
                            IsUserTemplate = true,
                        }

                        if UserValidateTemplate(entry, buildableUnits, prefix) then
                            TableInsert(ContextBasedTemplates, entry)
                        end
                    end
                end
            end
        end
    end

    function FilterTemplatesByUnitContext(buildableUnits, prefix)
        local contextBlueprintId = GetUnitContextBlueprintId()

        if contextBlueprintId then
            _FilterByUnit(buildableUnits, prefix)
            AppendUserTemplates(buildableUnits, prefix, contextBlueprintId)
        else
            _FilterByMouse(buildableUnits, prefix)
        end

        return TableGetn(ContextBasedTemplates) > 0
    end

    function FilterTemplatesByMouseContext(buildableUnits, prefix)
        -- Mouse filtering is handled by the wrapped FilterTemplatesByUnitContext.
        -- This no-op prevents duplicate filtering when Cycle falls back here.
    end

    function SortTemplates(a, b)
        local aUser = a.IsUserTemplate == true
        local bUser = b.IsUserTemplate == true

        if aUser ~= bUser then
            return not aUser
        end

        if aUser and bUser then
            return StringLower(a.Name or '') < StringLower(b.Name or '')
        end

        return _SortTemplates(a, b)
    end
end

-- Keep engineer selection stable while cycling when selection-filter mods rewrite it.
do
    local SelectionCompat = import('/mods/contexttemplatesexpanded/modules/selection_compat.lua')

    local function SnapshotEntityIds(selection)
        if not selection or TableEmpty(selection) then
            return nil
        end

        local ids = {}
        local count = 0
        for _, unit in selection do
            count = count + 1
            ids[count] = unit:GetEntityId()
        end
        ids.count = count
        return ids
    end

    local function ResolvePrefix(selectedUnits)
        local prefix = selectedUnits[1]:GetBlueprint().BlueprintId:sub(1, 2)
        local faction = selectedUnits[1]:GetBlueprint().FactionCategory

        if faction == "UEF" then
            return 'ue'
        elseif faction == "AEON" then
            return 'ua'
        elseif faction == "CYBRAN" then
            return 'ur'
        elseif faction == "SERAPHIM" then
            return 'xs'
        elseif faction == "NOMADS" then
            return 'xn'
        end

        return prefix
    end

    Cycle = function()
        local start = GetSystemTimeSeconds()

        local selectedUnits = GetSelectedUnits()
        if not selectedUnits or TableEmpty(selectedUnits) then
            return
        end

        local entityIds = SnapshotEntityIds(selectedUnits)
        local _, _, buildableCategories = GetUnitCommandData(selectedUnits)
        local buildableUnits = TableHash(EntityCategoryGetUnitList(buildableCategories))

        if TableEmpty(buildableUnits) then
            print("No templates available")
            return
        end

        local prefix = ResolvePrefix(selectedUnits)

        SelectionCompat.BeginCycle(entityIds)

        if ContextBasedTemplateStep == 0 then
            for index = 1, TableGetn(ContextBasedTemplates) do
                ContextBasedTemplates[index] = nil
            end

            TableSetn(ContextBasedTemplates, 0)

            local applies = FilterTemplatesByUnitContext(buildableUnits, prefix)
            if not applies then
                FilterTemplatesByMouseContext(buildableUnits, prefix)
            end
        end

        if TableGetn(ContextBasedTemplates) == 0 then
            print("No templates available")
            SelectionCompat.EndCycle(entityIds)
            return
        end

        TableSort(ContextBasedTemplates, SortTemplates)

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

        SelectionCompat.EndCycle(entityIds)

        SPEW("Time taken: " .. GetSystemTimeSeconds() - start)
    end
end
