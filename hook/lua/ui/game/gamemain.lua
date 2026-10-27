-------------------------------------------------------------------------------
-- Context Templates Expanded: gamemain hook wiring.

local Guards = import('/mods/contexttemplatesexpanded/modules/selection_guards.lua')
local Selection = import('/lua/ui/game/selection.lua')

local wrapped = Guards.Create({
    setIgnoreSelection = SetIgnoreSelection,
    onSelectionChanged = OnSelectionChanged,
    deselectSelens = DeselectSelens,
    getIgnoreSelection = function()
        return ignoreSelection
    end,
    setIgnoreSelectionFlag = function(ignore)
        ignoreSelection = ignore
    end,
    selectionIsHidden = Selection.IsHidden,
})

SetIgnoreSelection = wrapped.setIgnoreSelection
IsIgnoreSelection = wrapped.isIgnoreSelection
OnSelectionChanged = wrapped.onSelectionChanged
DeselectSelens = wrapped.deselectSelens
