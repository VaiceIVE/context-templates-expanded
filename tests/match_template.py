"""Self-check for user-template match, validate, copy, and hook wiring.

Keep algorithms in sync with modules/user_templates.lua.
Run: python3 tests/match_template.py
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def convert_id(blueprint_id, prefix):
    return prefix + blueprint_id[2:]


# Converted-id upgrade edges (same as blueprint General.UpgradesFrom / FromBase).
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


def is_blueprint_id(blueprint_id):
    return isinstance(blueprint_id, str) and len(blueprint_id) >= 6


def blueprints_match(reference, context, prefix, buildable):
    if not is_blueprint_id(reference) or not is_blueprint_id(context):
        return False
    if convert_id(reference, prefix) == convert_id(context, prefix):
        return True
    if reference[2:] == context[2:]:
        return True
    left = find_buildable(reference, buildable, prefix)
    right = find_buildable(context, buildable, prefix)
    return left is not None and left == right


def matches_building(user_template, context, prefix, buildable):
    data = user_template.get("templateData") or []
    first = data[2] if len(data) > 2 else None
    return blueprints_match(first and first[0], context, prefix, buildable)


def validate_template(template_data, buildable, prefix):
    first = template_data[2]
    if not isinstance(first, list) or not find_buildable(first[0], buildable, prefix):
        return False
    for entry in template_data[3:]:
        if isinstance(entry, list):
            converted = convert_id(entry[0], prefix)
            if converted not in buildable:
                return False
    return True


def copy_template_data(template_data):
    copy = [template_data[0], template_data[1]]
    for entry in template_data[2:]:
        if isinstance(entry, list):
            copy.append([entry[0], entry[1], entry[2], entry[3]])
    return copy


T1 = {"ueb1103", "ueb1106", "ueb1101"}
T3_ENGIE = T1 | {"ueb1302", "ueb1106", "ueb1101"}

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

assert matches_building(storage_first, "ueb1106", "ue", T1), "slot 3 storage matches hovered storage"
assert not matches_building(storage_first, "ueb1103", "ue", T1), "icon mex is ignored"
assert matches_building(mex_first, "ueb1103", "ue", T1)
assert not matches_building(mex_first, "ueb1106", "ue", T1)
assert not matches_building({"templateData": [6, 6]}, "ueb1103", "ue", T1)

# After T1 engineer downgrades a T3 mex ghost, command mode is T1 mex.
assert matches_building(t3_mex_first, "ueb1103", "ue", T1), "T3 slot matches downgraded T1 context"
assert matches_building(t3_mex_first, "ueb1302", "ue", T1), "T3 slot still matches hovered T3"

assert validate_template(mex_first["templateData"], T1, "ue")
assert validate_template(t3_mex_first["templateData"], T1, "ue"), "slot 3 may downgrade"
assert not validate_template(t3_then_t3_pgen["templateData"], T1, "ue"), (
    "later entries must be directly buildable, not downgraded"
)
assert not validate_template(storage_first["templateData"], {"ueb1103"}, "ue")

copied = copy_template_data(storage_first["templateData"])
assert [entry[0] for entry in copied[2:]] == ["uab1106", "uab1103"], "build order is unchanged"
assert copied[2][2:] == [0, 0] and copied[3][2:] == [2, 0]
assert copied[2] is not storage_first["templateData"][2]

user_templates = (ROOT / "modules/user_templates.lua").read_text()
assert "filterByMouse = filterByMouse" in user_templates, "vanilla mouse filter is passed through"
assert "This no-op prevents duplicate" not in user_templates

guards = (ROOT / "modules/selection_guards.lua").read_text()
assert "commandModeSetIgnoreSelection" not in guards, "CommandMode.SetIgnoreSelection stays vanilla"

gamemain = (ROOT / "hook/lua/ui/game/gamemain.lua").read_text()
assert "CommandMode.SetIgnoreSelection" not in gamemain

compat = (ROOT / "modules/selection_compat.lua").read_text()
apply = compat.split("function ApplyTemplateCommand", 1)[1].split("function EndCycle", 1)[0]
assert "SetIgnoreSelection(true)" in apply and "StartCommandMode" in apply
assert "SetUiSuppress(true)" not in apply, "GameMain ignore is not reset mid-apply"

print("match_template: ok")
