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
- **Building context** (hovered unit, build preview, or build order): FAF building-specific defaults plus user templates whose menu icon matches that building (upgrade chains such as T2/T3 shields match); if the icon is `default`, the first building in the template is used instead.
- **Terrain context** (land/water, no building): only FAF defaults (e.g. PD and AA); user templates are not included.
- User templates are sorted alphabetically by name among themselves.

## Test checklist

1. Save two or more user templates with different icons.
2. Select engineers, hover a building that matches one template icon, press the context-template hotkey — matching user templates should appear after FAF defaults, in A–Z order.
3. Change a template icon in the construction menu — cycling should reflect the new filter.
4. Use a template with the default icon — matching should use the first building in build order.
5. Hover empty land with engineers selected — only FAF terrain defaults (PD/AA); user templates should not appear.
6. Hover a T3 shield with a user template icon set to the T2 shield — template should still match via upgrade chain.
