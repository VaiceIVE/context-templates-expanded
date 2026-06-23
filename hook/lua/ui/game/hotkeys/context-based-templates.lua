-------------------------------------------------------------------------------
-- User Context Templates mod

local Prefs = import("/lua/user/prefs.lua")
local StringLower = string.lower

local USER_SORT_BASE = 100000

local _FilterByUnit = FilterTemplatesByUnitContext
local _FilterByMouse = FilterTemplatesByMouseContext

local function InSameUpgradeChain(blueprintIdA, blueprintIdB)
    if not blueprintIdA or not blueprintIdB then
        return false
    end

    if blueprintIdA == blueprintIdB then
        return true
    end

    local function ancestors(blueprintId)
        local chain = {}
        local seen = {}
        local current = blueprintId
        for _ = 1, 16 do
            if not current or seen[current] then
                break
            end
            seen[current] = true
            chain[current] = true
            local blueprint = __blueprints[current]
            if not blueprint or not blueprint.General then
                break
            end
            current = blueprint.General.UpgradesFrom or blueprint.General.UpgradesFromBase
        end
        return chain
    end

    local chainA = ancestors(blueprintIdA)
    if chainA[blueprintIdB] then
        return true
    end

    local chainB = ancestors(blueprintIdB)
    for id, present in pairs(chainA) do
        if present and chainB[id] then
            return true
        end
    end

    return false
end

local function BlueprintsMatch(a, b, prefix, buildableUnits)
    if not a or not b then
        return false
    end

    local aConverted = ConvertBlueprintId(a, prefix)
    local bConverted = ConvertBlueprintId(b, prefix)

    if aConverted == bConverted then
        return true
    end

    if a:sub(3) == b:sub(3) then
        return true
    end

    if InSameUpgradeChain(aConverted, bConverted) then
        return true
    end

    if buildableUnits then
        local aBuildable = FindBuildableBlueprintId(a, buildableUnits, prefix)
        local bBuildable = FindBuildableBlueprintId(b, buildableUnits, prefix)

        if aBuildable and bBuildable and aBuildable == bBuildable then
            return true
        end

        if aBuildable and (aBuildable == bConverted or InSameUpgradeChain(aBuildable, bConverted)) then
            return true
        end

        if bBuildable and (bBuildable == aConverted or InSameUpgradeChain(bBuildable, aConverted)) then
            return true
        end
    end

    return false
end

local function GetTemplateReferenceBlueprint(userTemplate)
    local icon = userTemplate.icon
    if icon and icon ~= 'default' then
        return icon
    end

    local templateData = userTemplate.templateData
    local first = templateData and templateData[3]
    return first and first[1]
end

local function UserTemplateMatchesBuilding(userTemplate, contextBlueprintId, prefix, buildableUnits)
    local referenceBlueprint = GetTemplateReferenceBlueprint(userTemplate)
    return referenceBlueprint and BlueprintsMatch(referenceBlueprint, contextBlueprintId, prefix, buildableUnits)
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
            if not UserTemplateMatchesBuilding(userTemplate, contextBlueprintId, prefix, buildableUnits) then
                continue
            end

            userIndex = userIndex + 1
            local entry = {
                Name = userTemplate.name or ('Template ' .. userIndex),
                TemplateData = templateData,
                TemplateSortingOrder = USER_SORT_BASE + userIndex,
                IsUserTemplate = true,
            }

            if UserValidateTemplate(entry, buildableUnits, prefix) then
                TableInsert(ContextBasedTemplates, entry)
            end
        end
    end
end

FilterTemplatesByUnitContext = function(buildableUnits, prefix)
    local contextBlueprintId = GetContextBlueprintId()

    if contextBlueprintId then
        _FilterByUnit(buildableUnits, prefix)
        AppendUserTemplates(buildableUnits, prefix, contextBlueprintId)
    else
        _FilterByMouse(buildableUnits, prefix)
    end

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
