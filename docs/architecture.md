# Cobra Architecture Overview

> File: `docs/architecture.md`  
> Goal: Help a new dev understand **who talks to who** in Cobra in ~30 seconds, and know where to plug in.

---

## 0. Big Picture

Cobra is a **first-person feel kit** plus a **WW2 bootcamp demo**.

High level pieces:

- **Player stack**
  - `FeelPlayer` (`scenes/FeelPlayer.tscn` + `scripts/player/feel_player.gd`)
  - `RecoilPivot` + `Camera3D`
  - `WeaponRig` (viewmodel sway / ADS) + `WeaponBase` (gun logic)
  - `MeleeWeapon` (close-range hits)
- **HUD**
  - `HUD.tscn` + `scripts/hud/hud.gd`
  - Crosshair, hit/kill markers, ammo, prompts, range stats
- **Targets & damage**
  - `Damageable` (`scripts/weapons/damageable.gd`)
  - Training targets & bootcamp lanes using Damageable
- **Demo levels**
  - `TestRange.tscn` – minimal testbed
  - `demo/WW2Bootcamp.tscn` – armory, movement course, range, scoring
  - Supporting scripts in `scripts/demo/…`

Everything is plain Godot scenes/scripts; no magic plugins.

---

## 1. Scene & Node Overview

### 1.1 FeelPlayer.tscn

**Path:** `scenes/FeelPlayer.tscn`  
**Script:** `scripts/player/feel_player.gd`

Canonical hierarchy (simplified):

- `FeelPlayer` (CharacterBody3D)
  - `RecoilPivot` (Node3D, with `recoil_controller.gd`)
    - `Camera3D`
      - `WeaponRig` (Node3D, with `weapon_rig.gd`)
        - `Weapon` (Node3D, with `weapon_base.gd`)
          - `Muzzle` (Node3D) – spawn point for muzzle flash, ray start
          - (Optional) `RifleModel` / viewmodel mesh
        - (Future) other viewmodel children as needed
      - `MeleeWeapon` (Node3D, with `melee_weapon.gd`)
  - `CollisionShape3D` (capsule for body)

**Responsibilities:**

- `FeelPlayer`:
  - Reads input (movement, jump, sprint, crouch, fire, aim, reload, melee, interact).
  - Handles movement, gravity, crouch transitions.
  - Handles **look** (yaw/pitch) and **ADS FOV/sensitivity**.
  - Talks to `WeaponRig` to set ADS state.
  - Connects to weapon signals (recoil, hit/kill, ammo) and relays them to HUD.

- `RecoilPivot`:
  - Owns the **camera rotation recoil**.
  - Receives `recoil_requested(offset: Vector2)` from weapons.
  - Applies yaw/pitch deltas and optional screen shake.

- `WeaponRig`:
  - Sits under `Camera3D`.
  - Applies **viewmodel sway**, idle bob, and ADS pose offsets.
  - Manages `active_weapon` and exposes `set_ads(is_ads: bool)`.

- `Weapon` (WeaponBase):
  - Pure gameplay logic: firing, spread, recoil signal, raycasts, hit registration.
  - Reads a `WeaponConfig` resource (`config/*.tres`).
  - Emits:
    - `ammo_changed(current, mag_size)`
    - `hit_confirmed(target: Node)`
    - `kill_confirmed(target: Node)`
    - `shot_fired()` (for stats)
    - `recoil_requested(offset: Vector2)` (for camera kick)

- `MeleeWeapon`:
  - Simple sphere- or shape-based overlaps for close hits.
  - Uses the same Damageable interface.

---

### 1.2 HUD.tscn

**Path:** `scenes/HUD.tscn`  
**Script:** `scripts/hud/hud.gd`

Structure (simplified):

- `HUD` (Control root)
  - `AmmoLabel`
  - `ControlsLabel`
  - `PromptLabel`
  - `Crosshair` (Control with child elements)
  - `Hitmarker` (Control or Label)
  - (Optionally) Stats labels, etc.

**Responsibilities:**

- Displays:
  - Ammo count.
  - Controls cheatsheet text.
  - Context prompts (e.g. "Press E to pick up rifle").
  - Crosshair that grows/shrinks based on movement + spread.
  - Hitmarker on hit, kill marker on lethal hits.
  - Range stats ("Targets Hit", "Accuracy", streak, etc.).

- Receives:
  - Weapon signals (`ammo_changed`, `hit_confirmed`, `kill_confirmed`, `shot_fired`).
  - Bootcamp range signals (reset / scoring).

- Public API:
  - `connect_weapon(weapon: WeaponBase)`
  - `set_prompt(text: String)`
  - `clear_prompt()`
  - (Internal helpers for hitmarkers & stats.)

---

### 1.3 Damage & Targets

**Damageable**

- Script: `scripts/weapons/damageable.gd`
- Typically on static/kinematic bodies (targets, dummy props).

Responsibilities:

- Has `max_health` and `current_health`.
- `apply_damage(amount: float, killer: Node = null)`:
  - Subtracts health.
  - When <= 0:
    - Emits `died(killer: Node)` signal.
    - `queue_free()` by default.
- WeaponBase and MeleeWeapon call `apply_damage(...)`.
- On death, `WeaponBase` emits `kill_confirmed(target)` for HUD & scoring.

**Training targets**

- A `TrainingTarget` scene (under shooting lanes) combines:
  - A Damageable body.
  - Visual feedback (SFX, VFX) on death.
  - Optional respawn hook used by bootcamp range logic.

---

### 1.4 TestRange.tscn

**Path:** `scenes/TestRange.tscn`  
**Script:** `scripts/test_range.gd`

Purpose:

- Minimal setup to exercise the core feel:
  - Floor + a few `Dummy` targets.
  - A `FeelPlayer` instance.
  - A `HUD` instance.
- Script wires:
  - HUD ↔ weapon.
  - Optionally any simple test hooks.

Use this scene when tuning core weapon feel without bootcamp complexity.

---

### 1.5 WW2Bootcamp.tscn

**Path:** `scenes/demo/WW2Bootcamp.tscn`  
**Script:** `scripts/demo/ww2_bootcamp.gd`

High-level layout:

- `WW2Bootcamp` (root node)
  - `Armory`
    - `WeaponRacks`
    - `WeaponSpots`
      - `RifleSpot` (bolt rifle config)
      - `SMGSpot`
      - `ShotgunSpot`
  - `Yard`
    - `MovementCourse` (walk/jump/crouch stations)
    - `Range` (shooting lanes + targets)
  - `FeelPlayer` (spawned in armory or near entrance)
  - `HUD`

Supporting demo scripts (under `scripts/demo/`):

- `armory_weapon_spot.gd`
  - Area3D triggers around weapon tables/racks.
  - When player enters and presses `interact`:
    - Swaps weapon's `config` to a specific `WeaponConfig`.
    - Resets ammo appropriately.
    - Updates on-screen label.

- `bootcamp_course.gd` (movement course)
  - Three progression stations:
    - **Walk**: simple trigger to step through.
    - **Jump**: obstacle to jump over.
    - **Crouch**: low tunnel that requires crouching.
  - Uses Areas to detect player and update HUD prompts.
  - Optionally controls gates between sections.

- `bootcamp_range.gd` (shooting lanes & scoring)
  - Tracks training targets in the range.
  - Hooks into `Damageable.died` / `WeaponBase.kill_confirmed`.
  - Maintains spawn transforms for targets and respawns them.
  - Exposes "reset range" behavior (clear stats + respawn targets).
  - HUD shows:
    - Targets hit.
    - Shots fired.
    - Accuracy.
    - Best streak (optional).

Bootcamp is both:

- A **player tutorial + feel showcase** for a WW2 game idea.
- A **reference integration** showing how to hook Cobra systems together.

---

## 2. Data Flow & Signals (Who Talks to Who)

### 2.1 Input → Player → Weapon → World

1. **Input Map**  
   - Actions: `move_*`, `jump`, `crouch`, `sprint`, `fire`, `reload`, `aim`, `melee`, `interact`.

2. **FeelPlayer (feel_player.gd)**
   - Reads input every physics frame.
   - Updates:
     - Movement velocity.
     - Yaw & pitch.
     - ADS state (`weapon_rig.set_ads()`).
     - Crouch height & camera height.

3. **WeaponRig (weapon_rig.gd)**
   - Receives ADS state, movement from player.
   - Applies sway and idle motion to the viewmodel.
   - Exposes `active_weapon` to the rest of the system.

4. **WeaponBase (weapon_base.gd)**
   - When fired:
     - Uses `WeaponConfig` for damage, spread, fire rate, recoil pattern, SFX/VFX.
     - Casts a ray from the camera (`aim_node`).
     - If hit:
       - Calls `apply_damage()` on a Damageable.
       - Emits `hit_confirmed(target)` and potentially `kill_confirmed(target)` when target dies.
     - Emits `ammo_changed`, `shot_fired`, `recoil_requested`.

5. **Damageable (damageable.gd)**
   - Applies damage.
   - When health <= 0:
     - Emits `died(killer)` and `queue_free()`.

6. **World / Demo Systems**
   - Training targets & bootcamp range listen to `died` and manage respawn & scoring.

---

### 2.2 Weapon & Recoil → Camera & HUD

- **RecoilController (recoil_controller.gd)**  
  - Connected to `WeaponBase.recoil_requested(offset: Vector2)`.
  - Smoothly interpolates a **recoil target** → applies incremental yaw/pitch to `RecoilPivot`.
  - Optional camera shake based on config toggles.

- **HUD (hud.gd)**  
  - Connected via `connect_weapon(weapon)` to:
    - `ammo_changed` → updates ammo text.
    - `hit_confirmed` → plays hitmarker.
    - `kill_confirmed` → plays stronger kill marker + stats.
    - `shot_fired` → increments shots & recalculates accuracy.
  - Uses `weapon.get_spread_ratio()` + movement factor → dynamic crosshair scaling.

- **Bootcamp Scripts (demo)**
  - `bootcamp_range.gd` can also listen for deaths/stats and tell HUD about range-specific goals or resets.

---

## 3. Extensibility Points

This is where you plug your own stuff in.

### 3.1 New weapons

- Add a new `WeaponConfig` resource in `config/`:
  - Duplicate an existing config (Rifle/SMG/Shotgun).
  - Tune using `docs/weapon-feel-presets.md` as a guide.
- Hook it up:
  - Assign as the Weapon's default config in `FeelPlayer.tscn`, or
  - Attach it to a new `ArmoryWeaponSpot` in WW2Bootcamp.

No code changes required if you just tweak configs.

---

### 3.2 New player controller

If you don't want `FeelPlayer`:

- Keep **WeaponRig**, **WeaponBase**, **RecoilController**, and HUD.
- Replace:
  - `FeelPlayer` with your own CharacterBody3D.
  - Copy or adapt:
    - ADS handling (`set_ads` on WeaponRig).
    - Recoil signal wiring.
    - Fire/Reload/Aim input mapping.
- Use `docs/integration-modes.md` for detailed patterns.

---

### 3.3 New HUD or UI

If you only like the weapon feel but want your own UI:

- Either:
  - Change visuals in `HUD.tscn` but keep `hud.gd`, or
  - Write your own HUD script that listens for:
    - `ammo_changed`, `hit_confirmed`, `kill_confirmed`, `shot_fired`,
    - and optionally calls `weapon.get_spread_ratio()`.

All weapon systems are built around **signals + a small public API**, so swapping the HUD layer is straightforward.

---

### 3.4 New demo levels

To build a new demo/test scene:

1. Start from `TestRange.tscn` or `WW2Bootcamp.tscn`.
2. Copy/strip down the structure you need.
3. Reuse:
   - `FeelPlayer` + `HUD`.
   - Scripts from `scripts/demo/` as templates for:
     - Weapon selection.
     - Movement tutorials.
     - Scoring & resetting.

You can treat `WW2Bootcamp` as a "kitchen sink example" of integrating multiple systems.

---

## 4. Quick Mental Model

If you're brand new to this repo, remember:

- **FeelPlayer** = "full package" player controller.
- **RecoilPivot + Camera3D** = where recoil lives.
- **WeaponRig** = viewmodel & ADS layer.
- **WeaponBase + WeaponConfig** = real gun logic & feel.
- **Damageable** = anything that can be shot and die.
- **HUD** = visual feedback & stats.
- **TestRange / WW2Bootcamp** = reference scenes showing how to wire it all together.

From here, jump into the code in this order:

1. `scripts/weapons/weapon_config.gd`
2. `scripts/weapons/weapon_base.gd`
3. `scripts/player/recoil_controller.gd`
4. `scripts/player/weapon_rig.gd`
5. `scripts/player/feel_player.gd`
6. `scripts/hud/hud.gd`
7. `scripts/demo/*.gd` for integration examples.

That's the backbone of Cobra.

