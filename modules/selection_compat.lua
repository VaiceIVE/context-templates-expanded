-------------------------------------------------------------------------------
-- Selection suppression for context-template cycling.

local suppressed = false
local allowSelect = false

local function TryImportAseMain()
    local ok, main = pcall(import, '/mods/ASE/modules/Main.lua')
    if ok and main then
        return main
    end
end

local function TryImportCommonSelect()
    local ok, select = pcall(import, '/mods/common/select.lua')
    if ok and select then
        return select
    end
end

local function UnitsFromEntityIds(entityIds)
    if not entityIds or entityIds.count == 0 then
        return nil
    end

    local units = {}
    local count = 0
    for index = 1, entityIds.count do
        local unit = GetUnitById(entityIds[index])
        if unit and not IsDestroyed(unit) then
            count = count + 1
            units[count] = unit
        end
    end

    if count == 0 then
        return nil
    end

    return units
end

local function SetUiSuppress(active)
    local GameMain = import('/lua/ui/game/gamemain.lua')
    local Selection = import('/lua/ui/game/selection.lua')
    GameMain.SetIgnoreSelection(active)
    Selection.SetSelectionHidden(active)
end

function IsSuppressed()
    return suppressed
end

function IsAllowSelect()
    return allowSelect
end

function WrapSelectUnits(selectUnits, units)
    if suppressed and not allowSelect then
        return
    end
    selectUnits(units)
end

function BeginCycle(entityIds)
    suppressed = true
    allowSelect = false

    local aseMain = TryImportAseMain()
    if aseMain and aseMain.SetIgnored then
        aseMain.SetIgnored(true)
    end

    SetUiSuppress(true)
end

function ApplyTemplateCommand(buildableBlueprintId, convertedTemplate, templateEntryCount, entityIds)
    local commonSelect = TryImportCommonSelect()
    local commandMode = import('/lua/ui/game/commandmode.lua')

    commandMode.StartCommandMode('build', { name = buildableBlueprintId })

    if templateEntryCount > 3 then
        if commonSelect and commonSelect.Hidden then
            commonSelect.Hidden(function()
                SetActiveBuildTemplate(convertedTemplate)
            end)
        else
            SetActiveBuildTemplate(convertedTemplate)
        end
    else
        ClearBuildTemplates()
    end

    local units = UnitsFromEntityIds(entityIds)
    if units then
        allowSelect = true
        SelectUnits(units)
        allowSelect = false
    end
end

function EndCycle(entityIds)
    ForkThread(function()
        local units = UnitsFromEntityIds(entityIds)
        if units then
            allowSelect = true
            SelectUnits(units)
            allowSelect = false
        end

        WaitFrames(3)

        suppressed = false
        allowSelect = false
        SetUiSuppress(false)

        local aseMain = TryImportAseMain()
        if aseMain and aseMain.SetIgnored then
            aseMain.SetIgnored(false)
        end
    end)
end
