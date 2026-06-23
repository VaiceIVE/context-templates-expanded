-------------------------------------------------------------------------------
-- Context Templates Expanded: outermost selection guards for template cycling.

do
    local SelectionCompat = import('/mods/contexttemplatesexpanded/modules/selection_compat.lua')
    local CommandMode = import('/lua/ui/game/commandmode.lua')

    local _SetIgnoreSelection = SetIgnoreSelection
    local _CommandModeSetIgnoreSelection = CommandMode.SetIgnoreSelection
    local _OnSelectionChanged = OnSelectionChanged
    local _DeselectSelens = DeselectSelens

    local function IsSelectionBlocked()
        return ignoreSelection
            or SelectionCompat.IsSuppressed()
            or import('/lua/ui/game/selection.lua').IsHidden()
    end

    function SetIgnoreSelection(ignore)
        ignoreSelection = ignore == true
        _SetIgnoreSelection(ignore)
    end

    function CommandMode.SetIgnoreSelection(ignore)
        ignoreSelection = ignore == true
        _CommandModeSetIgnoreSelection(ignore)
    end

    function IsIgnoreSelection()
        return ignoreSelection or SelectionCompat.IsSuppressed()
    end

    function OnSelectionChanged(oldSelection, newSelection, added, removed)
        if IsSelectionBlocked() then
            return
        end

        local ok, commonSelect = pcall(import, '/mods/common/select.lua')
        if ok and commonSelect.IsHidden and commonSelect.IsHidden() then
            return
        end

        _OnSelectionChanged(oldSelection, newSelection, added, removed)
    end

    function DeselectSelens(selection)
        if IsSelectionBlocked() then
            return selection, false
        end

        local ok, commonSelect = pcall(import, '/mods/common/select.lua')
        if ok and commonSelect.IsHidden and commonSelect.IsHidden() then
            return selection, false
        end

        return _DeselectSelens(selection)
    end
end
