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

A template is included only if its **first building** (slot 3, the one under the cursor when placed) matches the hovered building. The construction-tab icon is ignored. Build order and layout are copied as saved.

Matching accounts for:

- Faction conversion (e.g. Aeon template id with UEF engineers)
- Same unit type across factions (blueprint numeric suffix)
- Upgrade/downgrade to the same buildable unit (e.g. T3 mex ghost after a T1 engineer downgrades command mode to T1 mex)

A template is skipped unless slot 3 can be built or downgraded and every later building is directly buildable after faction conversion (same rules as vanilla `ValidateTemplate`).

If you hover a building and nothing matches, cycling falls back to vanilla terrain templates (PD/AA), same as unmodded FAF.

## Ordering summary

1. FAF default templates (by `TemplateSortingOrder`)
2. Matching user templates (A–Z by template name)

## Known mod conflicts

Context-based templates are known to conflict with **UI Party**. UI Party can shrink active build templates down to a single unit, which makes cycled templates look random or incomplete. If you see wrong units in a template, try disabling UI Party (this is [documented by the FAF developers](https://forum.faforever.com/topic/6422/developers-iteration-iii-of-2023)).

**Selection Deprioritizer**, **ASE**, and **UI Party** each hook selection differently. This mod:

- Wraps `SetActiveBuildTemplate` in Common Mod Tools `select.Hidden()` (same pattern other UI mods use)
- Sets `ASE.SetIgnored(true)` during template apply so ASE cannot fork a rewritten selection
- Guards `OnSelectionChanged` / `DeselectSelens` last in the hook chain (`mod_info.after` includes Common Mod Tools, Selection Deprioritizer, ASE, and UI Party)
- Restores engineer selection by entity id after each cycle step

**Requires Common Mod Tools.** Place this mod below ASE / Selection Deprioritizer / UI Party in the lobby list if you reorder mods manually.

## Test checklist

1. Save two or more user templates whose first buildings are different types.
2. Select engineers, hover a building that matches one template’s first building, press the context-template hotkey — matching user templates appear after FAF defaults, in A–Z order.
3. Change a template’s first building (re-save) — cycling should reflect the new filter. Changing only the construction-tab icon should not.
4. Hover empty land with engineers selected — only FAF terrain defaults (PD/AA); user templates do not appear.
5. Hover a building that has no matching templates (and no singleton) — terrain defaults appear, same as unmodded FAF.
6. Use a different faction’s engineers with templates saved in another faction’s blueprint ids — matching and validation should still work.
7. T1 engineers, hover a T3 mex, cycle a T3-first user template that only adds T1 buildings — set still matches after command mode downgrades to T1 mex.

## Duplicate templates in the cycle

The cycle reads the same profile data as the construction templates tab (`build_templates`). If you see the same template name many times in a row, your profile usually contains duplicate saved entries (often from old templates that were re-saved or imported).

**To align the cycle with what you see in the UI:**

1. Open the construction menu **Templates** tab with engineers selected.
2. Delete duplicate entries you no longer want (right-click → remove).
3. Start a new game or reload UI if the tab still looks stale.

This mod also skips duplicate template *content* during cycling (same buildings and layout), so identical copies only appear once even if they remain in the profile.
