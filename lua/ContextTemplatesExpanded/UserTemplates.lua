-- Context Templates Expanded: user template cache, indexing, and filter integration.

local import = import
local type = type
local pairs = pairs
local ipairs = ipairs
local TableInsert = table.insert
local TableGetn = table.getn
local TableSort = table.sort
local StringLower = string.lower

local EntityCategoryContains = EntityCategoryContains

local Prefs = import("/lua/user/prefs.lua")
local BuildTemplates = import("/lua/ui/game/build_templates.lua")

local CROSS_TIER_OPTION_KEY = 'cte_cross_tier_matching'

local USER_SORT_BASE = 100000
local MAX_UPGRADE_DEPTH = 16

---@type table?
local deps

local cacheDirty = true
local sortedEntries = {}
local indexByBlueprintKey = {}
local wrapperPool = {}
local ancestorCache = {}
local upgradeChainCache = {}

local function InvalidateCache()
    cacheDirty = true
end

local function CrossTierMatchingEnabled()
    return Prefs.GetOption(CROSS_TIER_OPTION_KEY) == 1
end

local function GetAncestors(blueprintId)
    if not blueprintId then
        return {}
    end

    local cached = ancestorCache[blueprintId]
    if cached then
        return cached
    end

    local chain = {}
    local seen = {}
    local current = blueprintId
    for _ = 1, MAX_UPGRADE_DEPTH do
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

    ancestorCache[blueprintId] = chain
    return chain
end

local function InSameUpgradeChain(blueprintIdA, blueprintIdB)
    if not blueprintIdA or not blueprintIdB then
        return false
    end

    if blueprintIdA == blueprintIdB then
        return true
    end

    local cacheKey = blueprintIdA .. ':' .. blueprintIdB
    local reverseKey = blueprintIdB .. ':' .. blueprintIdA
    if upgradeChainCache[cacheKey] ~= nil then
        return upgradeChainCache[cacheKey]
    end
    if upgradeChainCache[reverseKey] ~= nil then
        return upgradeChainCache[reverseKey]
    end

    local chainA = GetAncestors(blueprintIdA)
    if chainA[blueprintIdB] then
        upgradeChainCache[cacheKey] = true
        return true
    end

    local chainB = GetAncestors(blueprintIdB)
    for id, present in pairs(chainA) do
        if present and chainB[id] then
            upgradeChainCache[cacheKey] = true
            return true
        end
    end

    upgradeChainCache[cacheKey] = false
    return false
end

--- Slot 3 is the building under the cursor; matching must use that, not the tab icon.
local function GetTemplateReferenceBlueprint(userTemplate)
    local templateData = userTemplate.templateData
    local first = templateData and templateData[3]
    return first and first[1]
end

local function BlueprintsMatch(referenceBlueprint, contextBlueprintId, prefix, buildableUnits)
    if not referenceBlueprint or not contextBlueprintId then
        return false
    end

    local ConvertBlueprintId = deps.ConvertBlueprintId
    local FindBuildableBlueprintId = deps.FindBuildableBlueprintId

    local referenceConverted = ConvertBlueprintId(referenceBlueprint, prefix)
    local contextConverted = ConvertBlueprintId(contextBlueprintId, prefix)

    if referenceConverted == contextConverted then
        return true
    end

    if referenceBlueprint:sub(3) == contextBlueprintId:sub(3) then
        return true
    end

    -- Same unit the engineer can start (T3 slot / T1 command mode after downgrade).
    if buildableUnits then
        local referenceBuildable = FindBuildableBlueprintId(referenceBlueprint, buildableUnits, prefix)
        local contextBuildable = FindBuildableBlueprintId(contextBlueprintId, buildableUnits, prefix)
        if referenceBuildable and contextBuildable and referenceBuildable == contextBuildable then
            return true
        end
    end

    if not CrossTierMatchingEnabled() then
        return false
    end

    local referenceBlueprintData = __blueprints[referenceConverted]
    if referenceBlueprintData and referenceBlueprintData.Categories then
        if EntityCategoryContains(referenceBlueprintData.Categories, contextBlueprintId) then
            return true
        end
    end

    local contextBlueprintData = __blueprints[contextConverted]
    if contextBlueprintData and contextBlueprintData.Categories then
        if EntityCategoryContains(contextBlueprintData.Categories, referenceBlueprint) then
            return true
        end
    end

    if InSameUpgradeChain(referenceConverted, contextConverted) then
        return true
    end

    if buildableUnits then
        local referenceBuildable = FindBuildableBlueprintId(referenceBlueprint, buildableUnits, prefix)
        local contextBuildable = FindBuildableBlueprintId(contextBlueprintId, buildableUnits, prefix)

        if referenceBuildable and (referenceBuildable == contextConverted or InSameUpgradeChain(referenceBuildable, contextConverted)) then
            return true
        end

        if contextBuildable and (contextBuildable == referenceConverted or InSameUpgradeChain(contextBuildable, referenceConverted)) then
            return true
        end
    end

    return false
end

--- Same rules as vanilla ValidateTemplate: slot 3 may downgrade, the rest must convert.
local function UserValidateTemplate(entry, buildableUnits, prefix)
    local FindBuildableBlueprintId = deps.FindBuildableBlueprintId
    local ConvertBlueprintId = deps.ConvertBlueprintId
    local templateData = entry.TemplateData
    local first = templateData[3]
    if type(first) ~= 'table' or not FindBuildableBlueprintId(first[1], buildableUnits, prefix) then
        return false
    end

    for index = 4, TableGetn(templateData) do
        local building = templateData[index]
        if type(building) == 'table' then
            local converted = ConvertBlueprintId(building[1], prefix)
            if not converted or not buildableUnits[converted] then
                return false
            end
        end
    end
    return true
end

local function GetWrapper(index)
    local wrapper = wrapperPool[index]
    if not wrapper then
        wrapper = { IsUserTemplate = true }
        wrapperPool[index] = wrapper
    end
    return wrapper
end

local function AddToIndex(key, entry)
    if not key then
        return
    end

    local bucket = indexByBlueprintKey[key]
    if not bucket then
        bucket = {}
        indexByBlueprintKey[key] = bucket
    end
    bucket[entry] = true
end

local function IndexEntry(entry, referenceBlueprint)
    AddToIndex(referenceBlueprint, entry)
    AddToIndex(referenceBlueprint:sub(3), entry)

    if not CrossTierMatchingEnabled() then
        return
    end

    for blueprintId, present in pairs(GetAncestors(referenceBlueprint)) do
        if present then
            AddToIndex(blueprintId, entry)
            AddToIndex(blueprintId:sub(3), entry)
        end
    end
end

local function CompareEntryNames(a, b)
    return a.SortName < b.SortName
end

local function RebuildCache()
    sortedEntries = {}
    indexByBlueprintKey = {}
    ancestorCache = {}
    upgradeChainCache = {}

    local userTemplates = BuildTemplates.GetTemplates() or {}
    local wrappers = {}
    local wrapperIndex = 0

    for templateIndex, userTemplate in ipairs(userTemplates) do
        local templateData = userTemplate.templateData
        local referenceBlueprint = GetTemplateReferenceBlueprint(userTemplate)
        if templateData and TableGetn(templateData) >= 3 and referenceBlueprint then
            wrapperIndex = wrapperIndex + 1
            local wrapper = GetWrapper(wrapperIndex)
            wrapper.Name = userTemplate.name or ('Template ' .. templateIndex)
            wrapper.SortName = StringLower(wrapper.Name)
            wrapper.TemplateData = templateData
            wrapper.ReferenceBlueprint = referenceBlueprint
            wrapper.TemplateSortingOrder = USER_SORT_BASE + wrapperIndex
            wrappers[wrapperIndex] = wrapper
            IndexEntry(wrapper, referenceBlueprint)
        end
    end

    TableSort(wrappers, CompareEntryNames)

    for order, wrapper in ipairs(wrappers) do
        wrapper.TemplateSortingOrder = USER_SORT_BASE + order
        sortedEntries[order] = wrapper
    end

    cacheDirty = false
end

local function EnsureCache()
    if cacheDirty then
        RebuildCache()
    end
end

local function BuildCandidateSet(contextBlueprintId, prefix)
    local ConvertBlueprintId = deps.ConvertBlueprintId
    local candidates = {}
    local converted = ConvertBlueprintId(contextBlueprintId, prefix)

    local function markCandidates(key)
        local bucket = indexByBlueprintKey[key]
        if bucket then
            for entry, present in pairs(bucket) do
                if present then
                    candidates[entry] = true
                end
            end
        end
    end

    markCandidates(contextBlueprintId)
    markCandidates(contextBlueprintId:sub(3))
    markCandidates(converted)
    markCandidates(converted:sub(3))

    if not CrossTierMatchingEnabled() then
        return candidates
    end

    for blueprintId, present in pairs(GetAncestors(contextBlueprintId)) do
        if present then
            markCandidates(blueprintId)
            markCandidates(blueprintId:sub(3))
        end
    end

    for blueprintId, present in pairs(GetAncestors(converted)) do
        if present then
            markCandidates(blueprintId)
            markCandidates(blueprintId:sub(3))
        end
    end

    return candidates
end

local function ResolveContextBlueprintId()
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
    EnsureCache()

    if TableGetn(sortedEntries) == 0 then
        return
    end

    local candidates = BuildCandidateSet(contextBlueprintId, prefix)
    local ContextBasedTemplates = deps.ContextBasedTemplates
    local TableInsert = deps.TableInsert

    for _, entry in ipairs(sortedEntries) do
        if candidates[entry]
            and BlueprintsMatch(entry.ReferenceBlueprint, contextBlueprintId, prefix, buildableUnits)
            and UserValidateTemplate(entry, buildableUnits, prefix) then
            TableInsert(ContextBasedTemplates, entry)
        end
    end
end

local function FilterTemplatesByUnitContext(buildableUnits, prefix)
    local contextBlueprintId = ResolveContextBlueprintId()

    if contextBlueprintId then
        deps.FilterByUnit(buildableUnits, prefix)
        AppendUserTemplates(buildableUnits, prefix, contextBlueprintId)
    else
        deps.FilterByMouse(buildableUnits, prefix)
    end

    return TableGetn(deps.ContextBasedTemplates) > 0
end

local function FilterTemplatesByMouseContext(buildableUnits, prefix)
    deps.FilterByMouse(buildableUnits, prefix)
end

local function SortTemplates(a, b)
    local aUser = a.IsUserTemplate == true
    local bUser = b.IsUserTemplate == true

    if aUser ~= bUser then
        return not aUser
    end

    if aUser and bUser then
        return a.TemplateSortingOrder < b.TemplateSortingOrder
    end

    return (a.TemplateSortingOrder or 0) < (b.TemplateSortingOrder or 0)
end

local function Install(injectedDeps)
    deps = injectedDeps
    InvalidateCache()
end

return {
    Install = Install,
    InvalidateCache = InvalidateCache,
    FilterTemplatesByUnitContext = FilterTemplatesByUnitContext,
    FilterTemplatesByMouseContext = FilterTemplatesByMouseContext,
    SortTemplates = SortTemplates,
}
