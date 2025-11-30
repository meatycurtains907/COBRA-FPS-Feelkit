# Weapon System Overview

Cobra's weapon system is data-driven via `WeaponConfig` and `MeleeConfig`, with `WeaponBase` and `MeleeWeapon` handling logic, and `WeaponRig` + `FeelPlayer` connecting them to input.

## High-Level Architecture

### `FeelPlayer` (scene + script)

- Handles movement, jumping, sprinting, and mouse look.
- Holds references to `WeaponRig` and `MeleeWeapon`.
- Translates input actions (`fire`, `reload`, `aim`, `melee`) into method calls on those weapon nodes.

### `WeaponRig`

- Has `active_weapon: WeaponBase`.
- Provides simple methods:
  - `fire()`, `reload()`, `set_ads(bool)`.
- Acts as a thin adapter between player input and the active ranged weapon.

### `WeaponBase`

- Represents a ranged weapon using a `WeaponConfig`.
- Manages ammo, fire rate, spread, recoil pattern, and hitscan raycasts using `aim_node`.
- Uses `aim_node_path: NodePath` to reference the Camera3D (resolved to `aim_node` in `_ready()`).
- Emits signals that HUD or other systems can connect to.

### `MeleeWeapon`

- Uses `MeleeConfig`.
- Handles swing → impact → recovery timing.
- Uses a sphere/shape query (`intersect_shape()`) in front of the camera to apply damage to nearby targets.
- Separate from `WeaponBase` to avoid ammo/fire-rate logic mixing with melee timing.

### HUD (`FeelHUD` + `HUD.tscn`)

- Connects to `WeaponBase`:
  - Listens to `ammo_changed` → updates ammo display.
  - Listens to `hit_confirmed` → shows hitmarker.
- Crosshair is always centered; hitmarker flashes on hits.

### `Damageable`

- Any object with `Damageable` script (`apply_damage(amount: float)`).
- Used by dummies in the test range to verify hits and kills.
- Simple interface: reduce health, print damage logs, `queue_free()` on death.

## WeaponConfig Details

`WeaponConfig` lives in `scripts/weapons/weapon_config.gd` and is used by `WeaponBase`.

### Key Fields

- **`display_name`** – Name shown in UI/logs (if you add that later).

- **`fire_mode`** – Enum: `SEMI_AUTO`, `FULL_AUTO`, `BURST` (currently mainly `FULL_AUTO` used).

- **`damage`** – Damage per shot.

- **`fire_rate`** – Shots per second.

- **`mag_size`** – Bullets per magazine.

- **`reload_time`** – Time in seconds to reload to full.

- **`hip_spread`** / **`ads_spread`** – Base spread (cone angle in degrees) when hip-firing vs aiming down sights.

- **`spread_increase_per_shot`** – How much spread increases with each shot.

- **`spread_decay_rate`** – How quickly spread returns toward zero over time.

- **`recoil_pattern`** – Array of `Vector2` values (x = yaw in degrees, y = pitch in degrees) applied per shot; loops when you reach the end.

- **`recoil_reset_speed`** – How quickly recoil returns to neutral.

- **`model_scene`** – Optional visual model (PackedScene).

- **`muzzle_flash_scene`**, **`impact_effect_scene`** – Optional VFX scenes for firing and impacts.

- **`fire_sfx`**, **`reload_sfx`**, **`empty_sfx`** – Audio streams for weapon sounds.

### Example Structure

```gdscript
extends Resource
class_name WeaponConfig

@export var display_name: String = "Rifle"
@export var damage: float = 25.0
@export var fire_rate: float = 10.0
@export var mag_size: int = 30
@export var hip_spread: float = 2.0
@export var ads_spread: float = 0.5
@export var recoil_pattern: Array[Vector2] = [Vector2(0.0, -1.5), ...]
# ... etc
```

## WeaponBase Behavior & Signals

`WeaponBase` reads data from `config: WeaponConfig` and uses `aim_node` (Camera3D) to:

- Get origin and forward direction.
- Apply spread adjustments (yaw/pitch offsets).
- Perform a hitscan `intersect_ray()` call.

### Ammo Management

- `_current_ammo` starts at `config.mag_size`.
- **`try_fire()`**:
  - Checks fire rate lockout.
  - Checks reload state.
  - Checks ammo.
  - If valid, reduces ammo, triggers recoil + spread, and runs `_perform_shot()`.
- **`try_reload()`**:
  - Starts a timer for `reload_time`.
  - Refills mag when timer completes.

### Signals

- **`fired`** – Emitted when a shot is fired (after ammo is decremented).

- **`hit_confirmed(target)`** – Emitted when a raycast hits something; `target` is the collider Node or null.

- **`ammo_changed(current_in_mag, mag_size)`** – Emitted whenever ammo changes.

- **`reload_started`** / **`reload_finished`** – Emitted around reload timers.

- **`recoil_requested(offset: Vector2)`** – Emitted per shot so something (like a RecoilController) can adjust camera view.

### Public Methods

- **`try_fire()`** – Attempts to fire if allowed by fire rate, ammo, and reload state.

- **`try_reload()`** – Starts reload if not already reloading and ammo is not full.

- **`set_ads(enabled: bool)`** – Sets aim down sights state (affects spread calculation).

- **`get_current_ammo() -> int`** – Returns current ammo in magazine.

### Aim Node

`WeaponBase` uses `aim_node_path: NodePath` (set in the editor) which is resolved to `aim_node: Node3D` in `_ready()`. This should point to the Camera3D node to get the shooting origin and direction.

## WeaponRig + FeelPlayer Interaction

Here's how input flows from player input to weapon behavior:

1. Player presses LMB (`fire` action).
2. `FeelPlayer` sees `Input.is_action_pressed("fire")` in `_handle_actions()`.
3. `FeelPlayer` calls `weapon_rig.fire()`.
4. `WeaponRig.fire()` calls `active_weapon.try_fire()` on `WeaponBase`.
5. `WeaponBase`:
   - Handles ammo, spread, recoil, hitscan.
   - Emits signals.
6. `FeelHUD` has connected to `WeaponBase` via `connect_weapon()` and:
   - Updates ammo label on `ammo_changed`.
   - Flashes hitmarker on `hit_confirmed`.

**Melee:** `MeleeWeapon` is separate and called directly from `FeelPlayer` when the `melee` action is pressed:
- `FeelPlayer._handle_actions()` → `melee_weapon.try_melee()`.
- `MeleeWeapon` handles its own swing timing and sphere query.

## How to Create a New Gun from RifleConfig

Follow these steps to create a custom weapon:

1. **Duplicate the config:**
   - In the `config/` folder, duplicate `RifleConfig.tres` and rename to `MyNewGunConfig.tres`.

2. **Configure your weapon:**
   - Open `MyNewGunConfig.tres` in the inspector.
   - Adjust:
     - `display_name` – e.g., "SMG", "Shotgun"
     - `damage` – e.g., 15.0 for SMG, 50.0 for shotgun
     - `fire_rate` – e.g., 15.0 for SMG, 2.0 for shotgun
     - `mag_size` – e.g., 30 for SMG, 8 for shotgun
     - `reload_time` – e.g., 1.5 for SMG, 3.0 for shotgun
     - `hip_spread` / `ads_spread` – larger for SMG, smaller for sniper
     - `recoil_pattern` – customize the pattern array
     - `recoil_reset_speed` – how quickly recoil returns
     - Assign different SFX/VFX if desired.

3. **Assign to weapon:**
   - Open `scenes/FeelPlayer.tscn`.
   - Select the `Weapon` node (with `WeaponBase` script).
   - In the Inspector, change its `config` property from `RifleConfig.tres` to `MyNewGunConfig.tres`.

4. **Test:**
   - Run `TestRange.tscn` and test the new gun.
   - Adjust values in the config until it feels right.

5. **(Optional) Future:**
   - You can create multiple weapons and switch by changing `WeaponRig.active_weapon`.
   - Or create a weapon switching system that instantiates different weapons.

### Notes

- For now, `FeelPlayer` is the easiest way to test weapons. Future docs will cover using Cobra's weapon system with a completely different player controller.
- All weapons share the same `WeaponBase` logic; only the config data changes.
- Melee weapons use `MeleeConfig` and `MeleeWeapon` separately; follow a similar pattern to create new melee weapons.




