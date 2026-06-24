-------------------------------------------------------------------------------
-- Selection guards for template cycling (gamemain hook wiring).

local SelectionCompat = import('/mods/contexttemplatesexpanded/modules/selection_compat.lua')

local commonSelect

local function TryImportCommonSelect()
    if commonSelect ~= nil then
        return commonSelect
    end

    local ok, select = pcall(import, '/mods/common/select.lua')
    if ok and select then
        commonSelect = select
        return select
    end

    commonSelect = false
    return nil
end

local function IsCommonSelectHidden()
    local select = TryImportCommonSelect()
    return select and select.IsHidden and select.IsHidden()
end

local M = {}

function M.Create(gamemain)
    local setIgnoreSelection = gamemain.setIgnoreSelection
    local commandModeSetIgnoreSelection = gamemain.commandModeSetIgnoreSelection
    local onSelectionChanged = gamemain.onSelectionChanged
    local deselectSelens = gamemain.deselectSelens
    local selectionIsHidden = gamemain.selectionIsHidden

    local function IsSelectionBlocked()
        return gamemain.getIgnoreSelection()
            or SelectionCompat.IsSuppressed()
            or selectionIsHidden()
    end

    return {
        setIgnoreSelection = function(ignore)
            gamemain.setIgnoreSelectionFlag(ignore == true)
            setIgnoreSelection(ignore)
        end,

        commandModeSetIgnoreSelection = function(ignore)
            gamemain.setIgnoreSelectionFlag(ignore == true)
            commandModeSetIgnoreSelection(ignore)
        end,

        isIgnoreSelection = function()
            return gamemain.getIgnoreSelection() or SelectionCompat.IsSuppressed()
        end,

        onSelectionChanged = function(oldSelection, newSelection, added, removed)
            if IsSelectionBlocked() then
                return
            end

            if IsCommonSelectHidden() then
                return
            end

            onSelectionChanged(oldSelection, newSelection, added, removed)
        end,

        deselectSelens = function(selection)
            if IsSelectionBlocked() then
                return selection, false
            end

            if IsCommonSelectHidden() then
                return selection, false
            end

            return deselectSelens(selection)
        end,
    }
end

return M
