-------------------------------------------------------------------------------
-- User build-template matching and context-template list extension.

local BuildTemplates = import("/lua/ui/game/build_templates.lua")
local CommandMode = import("/lua/ui/game/commandmode.lua")
local UIUtil = import("/lua/ui/uiutil.lua")

local StringLower = string.lower
local StringLen = string.len

local USER_SORT_BASE = 100000

local unitIconExistsCache = {}
local templateReferenceCache = {}

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

local function UnitIconExists(blueprintId)
    local cached = unitIconExistsCache[blueprintId]
    if cached ~= nil then
        return cached
    end

    local exists = UIUtil.UIFile('/icons/units/' .. blueprintId .. '_icon.dds', true) ~= nil
    unitIconExistsCache[blueprintId] = exists
    return exists
end

--- Same reference building as the construction templates tab (icon, then first valid icon in queue, then first entry).
local function GetTemplateReferenceBlueprint(userTemplate)
    local cached = templateReferenceCache[userTemplate]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end

    local icon = userTemplate.icon
    if icon and icon ~= 'default' and IsBlueprintId(icon) then
        templateReferenceCache[userTemplate] = icon
        return icon
    end

    local templateData = userTemplate.templateData
    if not templateData then
        templateReferenceCache[userTemplate] = false
        return nil
    end

    for index = 3, TableGetn(templateData) do
        local entry = templateData[index]
        if type(entry) == 'table' then
            local blueprintId = entry[1]
            if IsBlueprintId(blueprintId) and UnitIconExists(blueprintId) then
                templateReferenceCache[userTemplate] = blueprintId
                return blueprintId
            end
        end
    end

    local first = templateData[3]
    local blueprintId = first and first[1]
    if IsBlueprintId(blueprintId) then
        templateReferenceCache[userTemplate] = blueprintId
        return blueprintId
    end

    templateReferenceCache[userTemplate] = false
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

    templateReferenceCache = {}

    local userTemplates = BuildTemplates.GetTemplates() or {}
    local userIndex = 0
    local seen = {}

    for index = 1, TableGetn(userTemplates) do
        local userTemplate = userTemplates[index]
        local templateData = userTemplate and userTemplate.templateData
        if templateData and TableGetn(templateData) >= 3
            and UserTemplateMatchesBuilding(userTemplate, contextBlueprintId, prefix) then
            local fingerprint = TemplateFingerprint(templateData)
            if fingerprint ~= '' and not seen[fingerprint] then
                seen[fingerprint] = true

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

local M = {}

function M.Create(vanilla)
    local filterByUnit = vanilla.filterByUnit
    local filterByMouse = vanilla.filterByMouse
    local sortTemplates = vanilla.sortTemplates

    return {
        filterByUnit = function(buildableUnits, prefix)
            local contextBlueprintId = GetUnitContextBlueprintId()

            if contextBlueprintId then
                filterByUnit(buildableUnits, prefix)
                AppendUserTemplates(buildableUnits, prefix, contextBlueprintId)
            else
                filterByMouse(buildableUnits, prefix)
            end

            return TableGetn(ContextBasedTemplates) > 0
        end,

        filterByMouse = function(buildableUnits, prefix)
            -- Mouse filtering is handled by the wrapped filterByUnit.
            -- This no-op prevents duplicate filtering when Cycle falls back here.
        end,

        sort = function(a, b)
            local aUser = a.IsUserTemplate == true
            local bUser = b.IsUserTemplate == true

            if aUser ~= bUser then
                return not aUser
            end

            if aUser and bUser then
                return StringLower(a.Name or '') < StringLower(b.Name or '')
            end

            return sortTemplates(a, b)
        end,
    }
end

return M
