-------------------------------------------------------------------------------
-- Context Templates Expanded mod

local UserTemplates = import("/lua/ContextTemplatesExpanded/UserTemplates.lua")

local _AddTemplate = AddTemplate
function AddTemplate(newTemplate)
    _AddTemplate(newTemplate)
    UserTemplates.InvalidateCache()
end

local _RemoveTemplate = RemoveTemplate
function RemoveTemplate(templateID)
    _RemoveTemplate(templateID)
    UserTemplates.InvalidateCache()
end

local _RenameTemplate = RenameTemplate
function RenameTemplate(templateID, name)
    _RenameTemplate(templateID, name)
    UserTemplates.InvalidateCache()
end

local _SetTemplateIcon = SetTemplateIcon
function SetTemplateIcon(templateID, iconPath)
    _SetTemplateIcon(templateID, iconPath)
    UserTemplates.InvalidateCache()
end
