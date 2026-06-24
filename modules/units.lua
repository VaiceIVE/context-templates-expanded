-------------------------------------------------------------------------------
-- Unit selection helpers for context-template cycling.

local M = {}

function M.SnapshotEntityIds(selection)
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

function M.ResolvePrefix(selectedUnits)
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

return M
