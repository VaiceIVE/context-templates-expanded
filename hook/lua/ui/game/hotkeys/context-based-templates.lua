-------------------------------------------------------------------------------
-- User Context Templates mod

local Prefs = import("/lua/user/prefs.lua")
local StringLower = string.lower

local USER_SORT_BASE = 100000

local _FilterByUnit = FilterTemplatesByUnitContext
local _FilterByMouse = FilterTemplatesByMouseContext

local function BlueprintsMatch(a, b, prefix)
    if not a or not b then
        return false
    end
    if ConvertBlueprintId(a, prefix) == ConvertBlueprintId(b, prefix) then
        return true
    end
    return a:sub(3) == b:sub(3)
end

local function UserTemplateMatchesBuilding(userTemplate, contextBlueprintId, prefix)
    local icon = userTemplate.icon
    if icon and icon ~= 'default' then
        return BlueprintsMatch(icon, contextBlueprintId, prefix)
    end

    local templateData = userTemplate.templateData
    local first = templateData and templateData[3]
    return first and BlueprintsMatch(first[1], contextBlueprintId, prefix)
end

local function GetContextBlueprintId()
    local commandMode = import("/lua/ui/game/commandmode.lua").GetCommandMode()
    local blueprintId = commandMode[2].name

    if not blueprintId then
        local highlightCommand = GetHighlightCommand()
        if highlightCommand and highlightCommand.blueprintId then
            blueprintId = highlightCommand.blueprintId
        end
    end

    if not blueprintId then
        local info = GetRolloverInfo()
        if info.userUnit then
            blueprintId = info.blueprintId
        end
    end

    return blueprintId
end

local function AppendUserTemplates(buildableUnits, prefix, contextBlueprintId)
    local userTemplates = Prefs.GetFromCurrentProfile('build_templates') or {}
    local userIndex = 0

    for _, userTemplate in userTemplates do
        local templateData = userTemplate.templateData
        if templateData and TableGetn(templateData) >= 3 then
            if contextBlueprintId and not UserTemplateMatchesBuilding(userTemplate, contextBlueprintId, prefix) then
                continue
            end

            userIndex = userIndex + 1
            local entry = {
                Name = userTemplate.name or ('Template ' .. userIndex),
                TemplateData = templateData,
                TemplateSortingOrder = USER_SORT_BASE + userIndex,
                IsUserTemplate = true,
            }

            if ValidateTemplate(entry, buildableUnits, prefix) then
                TableInsert(ContextBasedTemplates, entry)
            end
        end
    end
end

FilterTemplatesByUnitContext = function(buildableUnits, prefix)
    local contextBlueprintId = GetContextBlueprintId()
    local applies = false

    if contextBlueprintId then
        applies = _FilterByUnit(buildableUnits, prefix)
    end

    if not applies then
        _FilterByMouse(buildableUnits, prefix)
        contextBlueprintId = nil
    end

    AppendUserTemplates(buildableUnits, prefix, contextBlueprintId)
    return TableGetn(ContextBasedTemplates) > 0
end

FilterTemplatesByMouseContext = function(buildableUnits, prefix)
    -- Mouse filtering is handled by the wrapped FilterTemplatesByUnitContext.
    -- This no-op prevents duplicate filtering when Cycle falls back here.
end

SortTemplates = function(a, b)
    local aUser = a.IsUserTemplate == true
    local bUser = b.IsUserTemplate == true

    if aUser ~= bUser then
        return not aUser
    end

    if aUser and bUser then
        return StringLower(a.Name or '') < StringLower(b.Name or '')
    end

    return (a.TemplateSortingOrder or 0) < (b.TemplateSortingOrder or 0)
end
