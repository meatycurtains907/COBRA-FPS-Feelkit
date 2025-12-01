# Runtime logging notes

This file documents intentional runtime warnings and any remaining noisy scripts.

## Shipping scenes (FeelShowcase + MagicShowcase)

- `scripts/player/feel_player.gd`:
  - Warns if required input actions (e.g. `fire`, `block`) are missing via `push_warning`.

- `scripts/demo/feel_profile_manager.gd`:
  - May warn if a profile config is missing or fails to load.
  - Warns if player_path or hud_path are empty or cannot be resolved.
  - Warns if input action `switch_profile` is not defined.

- `scripts/weapons/weapon_base.gd`:
  - Warns if `aim_node` is not assigned or is not a Camera3D.
  - Warns if `WeaponConfig` is null or has invalid values.

- `scripts/weapons/melee_weapon.gd`:
  - Warns if `aim_node_path` or `MeleeConfig` are not assigned.

## Dev-only / noisy scenes

- `scenes/demo/WW2Bootcamp.tscn` and related bootcamp scripts:
  - Contains noisy prints intended for internal testing and is not part of the supported surface.
  - Scripts include: `bootcamp_manager.gd`, `bootcamp_course.gd`, `bootcamp_range.gd`, `ww2_bootcamp.gd`, `armory_weapon_spot.gd`



