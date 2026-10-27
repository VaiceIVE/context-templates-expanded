"""Self-check for slot-3 matching and merge wiring.

Keep algorithms in sync with lua/ContextTemplatesExpanded/UserTemplates.lua.
Run: python3 tests/match_template.py
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def convert_id(blueprint_id, prefix):
    return prefix + blueprint_id[2:]


UPGRADES_FROM = {
    "ueb1302": "ueb1202",
    "ueb1202": "ueb1103",
    "uab1302": "uab1202",
    "uab1202": "uab1103",
}
UPGRADES_FROM_BASE = {
    "ueb1302": "ueb1103",
    "uab1302": "uab1103",
}


def find_buildable(blueprint_id, buildable, prefix):
    converted = convert_id(blueprint_id, prefix)
    if converted in buildable:
        return converted
    from_id = UPGRADES_FROM.get(converted)
    if from_id and from_id in buildable:
        return from_id
    base_id = UPGRADES_FROM_BASE.get(converted)
    if base_id and base_id in buildable:
        return base_id
    return None


def reference_blueprint(user_template):
    data = user_template.get("templateData") or []
    first = data[2] if len(data) > 2 else None
    return first[0] if first else None


def blueprints_match(reference, context, prefix, buildable, cross_tier=False):
    if not reference or not context:
        return False
    if convert_id(reference, prefix) == convert_id(context, prefix):
        return True
    if reference[2:] == context[2:]:
        return True
    left = find_buildable(reference, buildable, prefix)
    right = find_buildable(context, buildable, prefix)
    if left and right and left == right:
        return True
    if not cross_tier:
        return False
    return False


def matches_building(user_template, context, prefix, buildable, cross_tier=False):
    return blueprints_match(reference_blueprint(user_template), context, prefix, buildable, cross_tier)


def validate_template(template_data, buildable, prefix):
    first = template_data[2]
    if not isinstance(first, list) or not find_buildable(first[0], buildable, prefix):
        return False
    for entry in template_data[3:]:
        if isinstance(entry, list) and convert_id(entry[0], prefix) not in buildable:
            return False
    return True


T1 = {"ueb1103", "ueb1106", "ueb1101"}

storage_first = {
    "icon": "uab1103",
    "templateData": [6, 6, ["uab1106", 1, 0, 0], ["uab1103", 2, 2, 0]],
}
mex_first = {
    "icon": "uab1106",
    "templateData": [6, 6, ["uab1103", 1, 0, 0], ["uab1106", 2, 2, 0]],
}
t3_mex_first = {
    "icon": "uab1106",
    "templateData": [6, 6, ["uab1302", 1, 0, 0], ["uab1106", 2, 2, 0]],
}
t3_then_t3_pgen = {
    "templateData": [6, 6, ["uab1302", 1, 0, 0], ["uab1301", 2, 2, 0]],
}

assert reference_blueprint(storage_first) == "uab1106"
assert matches_building(storage_first, "ueb1106", "ue", T1)
assert not matches_building(storage_first, "ueb1103", "ue", T1), "tab icon is ignored"
assert matches_building(mex_first, "ueb1103", "ue", T1)
assert matches_building(t3_mex_first, "ueb1103", "ue", T1), "T3 slot matches downgraded T1 context"
assert matches_building(t3_mex_first, "ueb1302", "ue", T1)

assert validate_template(t3_mex_first["templateData"], T1, "ue")
assert not validate_template(t3_then_t3_pgen["templateData"], T1, "ue")

user_templates = (ROOT / "lua/ContextTemplatesExpanded/UserTemplates.lua").read_text()
assert "templateData[3]" in user_templates
assert "userTemplate.icon" not in user_templates
assert "deps.FilterByMouse" in user_templates

hook = (ROOT / "hook/lua/ui/game/hotkeys/context-based-templates.lua").read_text()
assert "UserTemplates.Install" in hook
assert "CycleMod.Create" in hook
assert "getStep" in hook

print("match_template: ok")
