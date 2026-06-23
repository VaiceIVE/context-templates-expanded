-------------------------------------------------------------------------------
-- Context Templates Expanded: block stray SelectUnits during template cycling.

local SelectionCompat = import('/mods/contexttemplatesexpanded/modules/selection_compat.lua')

function SetSelectionHidden(hidden)
    hidden_select = hidden == true
end

local _SelectUnits = SelectUnits

function SelectUnits(units)
    SelectionCompat.WrapSelectUnits(_SelectUnits, units)
end
