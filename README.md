# User Context Templates

UI-only FAF mod that adds your saved build templates to the context-based template hotkey cycle.

## Install

Copy this folder into your FAF mods directory:

```
<FAF install>/gamedata/mods/UserContextTemplates/
```

Or symlink the dev folder:

```bash
ln -s /home/user/projects/lua/mod "<FAF install>/gamedata/mods/UserContextTemplates"
```

Enable **User Context Templates** in the lobby mod list (UI-only; other players do not need it).

## Behavior

- FAF default context templates appear first.
- Your saved build templates appear after them.
- **Building context** (hovered unit, build preview, or build order): only templates whose menu icon matches that building; if the icon is `default`, the first building in the template is used instead.
- **Terrain context** (land/water, no building): all valid user templates are included.
- User templates are sorted alphabetically by name among themselves.

## Test checklist

1. Save two or more user templates with different icons.
2. Select engineers, hover a building that matches one template icon, press the context-template hotkey — matching user templates should appear after FAF defaults, in A–Z order.
3. Change a template icon in the construction menu — cycling should reflect the new filter.
4. Use a template with the default icon — matching should use the first building in build order.
5. Hover empty land with engineers selected — all valid user templates should appear after terrain defaults.
6. Use a different faction’s engineers with templates saved in another faction’s blueprint ids — templates should still validate and convert.
