"""Every shaded boss's model and rig (posed.py), by sprite name: build.py and previews use it."""
import realm_shaded, dungeon_shaded_a, dungeon_shaded_b, raid_shaded, angular_shaded

RIGS = {}
for _mod in (realm_shaded, dungeon_shaded_a, dungeon_shaded_b, raid_shaded, angular_shaded):
    for _n, _fn in _mod.MODELS:
        RIGS[_n] = (_fn, getattr(_mod, 'RIG', {}).get(_n, {}))
