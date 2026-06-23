# Context Templates Expanded

UI-only FAF mod that extends the context-based template hotkey cycle with your saved build templates from the construction menu.

## Install

Copy this folder into your FAF mods directory:

```
<FAF install>/gamedata/mods/ContextTemplatesExpanded/
```

Or symlink the dev folder:

```bash
ln -s /home/user/projects/lua/mod "<FAF install>/gamedata/mods/ContextTemplatesExpanded"
```

Enable **Context Templates Expanded** in the lobby mod list. This is a UI-only mod — other players do not need it.

## How it works

The mod hooks FAF’s context-template hotkey (`Cycle`). Behavior depends on what your mouse is pointing at when you press it with engineers selected.

### Terrain context (no building)

When the mouse is over empty land or water and not over a unit, build preview, or build order:

- Only vanilla FAF terrain templates are shown (e.g. point defense, anti-air).
- User templates are **not** included.

This matches unmodded FAF cycling on open terrain.

### Building context

When the mouse is over a unit, a build preview, or an active build order:

1. Vanilla FAF templates for that building are shown first (singleton copy, append presets, etc.).
2. Matching user templates from your profile are appended **after** those defaults.
3. User templates are sorted **alphabetically by name** among themselves.

### Which user templates match a building

A template is included only if its reference building matches the hovered building:

| Priority | Reference building |
|----------|-------------------|
| 1 | Template menu icon (set via **Change Icon** in the construction templates tab) |
| 2 | First building in the template’s build order, if the icon is `default` |

Matching always accounts for:

- Faction conversion (e.g. Aeon template id with UEF engineers)
- Same unit type across factions (blueprint numeric suffix)

**Cross-tier matching** (e.g. T2 shield icon on a hovered T3 shield) is **off by default**. Enable it under **Options → Gameplay → Cross-tier template matching**.

A template is also skipped if the current engineer selection cannot build every building in it (each entry is checked with upgrade/downgrade resolution).

## Ordering summary

1. FAF default templates (by `TemplateSortingOrder`)
2. Matching user templates (A–Z by template name)

## Project layout

```
mod/
├── mod_info.lua
├── lua/ContextTemplatesExpanded/UserTemplates.lua   # cache, indexing, matching
└── hook/
    ├── lua/options/options.lua                        # cross-tier matching toggle
    ├── lua/ui/game/hotkeys/context-based-templates.lua
    └── lua/ui/game/build_templates.lua              # cache invalidation
```

User templates are cached and indexed by reference blueprint (including upgrade chains). The cache refreshes when templates are added, removed, renamed, or given a new icon.

## Test checklist

1. Save two or more user templates with different icons.
2. Select engineers, hover a building that matches one template’s icon, press the context-template hotkey — matching user templates appear after FAF defaults, in A–Z order.
3. Change a template icon in the construction menu — cycling should reflect the new filter immediately.
4. Use a template with the default icon — matching uses the first building in build order.
5. Hover empty land with engineers selected — only FAF terrain defaults (PD/AA); user templates do not appear.
6. Hover a T3 shield with a user template icon set to the T2 shield — no match by default; enable **Cross-tier template matching** in Gameplay options to match via upgrade chain.
7. Use a different faction’s engineers with templates saved in another faction’s blueprint ids — matching and validation should still work.
