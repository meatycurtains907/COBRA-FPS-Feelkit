# Cobra Integration Modes

> File: `docs/integration-modes.md`

COBRA FPS Feel Kit is designed to be **reusable**: you can either take the whole "feel kit" (player, camera, weapons, HUD) or just the pieces you want.

This doc explains **how to plug COBRA FPS Feel Kit into your own game** with minimal friction.

> **Note:** Projectile / magic weapons are an optional module.  
> You can completely ignore `MagicShowcase.tscn` and the `MagicArcane` presets if your game is purely hitscan FPS + melee.

---

## Two Main Integration Modes

Cobra supports two primary integration paths:

**Mode A: Drop-In FeelPlayer + COBRA HUD**  
Drop in `FeelPlayer.tscn` and `HUD.tscn`, plus the `FeelShowcase.tscn` scene as your starting point. Configure input map and you're shooting. Best for rapid prototyping or if you don't already have a custom player controller.

**Mode B: Integrate WeaponRig into Your Own Character**  
Keep your own movement / character controller, but reuse `WeaponRig`, `WeaponBase`, `WeaponConfig`, and optionally the HUD contract. Best for when you already have a custom FPS controller but want COBRA's weapon feel, recoil, crosshair, etc.

---

## 0. What's in the Box?

**Recommended Starting Point:**
- **FPS Feel Showcase** (`scenes/demo/FeelShowcase.tscn`)  
  - **Primary demo scene.** Core gunfeel, movement presets (Twitchy / WW2 / Arcade / Exploration). No magic required; block is disabled by default here. Great for learning the engine and testing your own configs.

**Key Scenes:**
- `scenes/FeelPlayer.tscn`  
  - First-person character: movement, look, crouch, ADS, recoil, head bob.

- `scenes/HUD.tscn`  
  - Crosshair, hitmarker, ammo, prompts, range stats.

- **Magic & Melee Showcase** (`scenes/demo/MagicShowcase.tscn`) _(optional)_  
  - Projectile/magic weapons, melee combos, block/parry UI, and the new dummy targets.

- **TestRange** (`scenes/TestRange.tscn`)  
  - Simple flat range with targets for sanity-checking weapons and damage.

- `scenes/demo/WW2Bootcamp.tscn` _(optional / experimental)_  
  - Example game-specific bootcamp level: armory, movement course, shooting range, scoring. Not required for integration.

Key scripts:

- `scripts/player/feel_player.gd`  
  - Character controller (movement, camera, ADS, recoil integration).

- `scripts/player/weapon_rig.gd`  
  - Handles active weapon, ADS state, weapon sway, viewmodel.

- `scripts/player/recoil_controller.gd`  
  - Applies recoil & optional shake to camera.

- `scripts/weapons/weapon_base.gd`  
  - Hitscan gun: firing, spread, recoil signal, ammo, damage.

- `scripts/weapons/melee_weapon.gd`  
  - Simple melee swings, using same Damageable system.

- `scripts/weapons/weapon_config.gd`  
  - `Resource` describing weapon feel (damage, spread, recoil, SFX, etc).

- `scripts/hud/hud.gd`  
  - Dynamic crosshair, hitmarker, killmarker, stats.

- `scripts/demo/armory_weapon_spot.gd`  
  - Armory weapon selection in WW2 bootcamp.

- `scripts/demo/ww2_bootcamp.gd`  
  - Wires bootcamp HUD ↔ player/weapon.

---

## 1. Input & Project Requirements

Before integrating Cobra into a different project, make sure your Godot project has these:

### 1.1. Input Actions: Core vs Optional

Cobra expects these actions in your project's Input Map (Project Settings → Input Map). You can bind them however you want (WASD, mouse buttons, controller, etc.), but these names must exist.

**Core (required for basic FPS + melee):**

- `move_forward` / `move_backward` / `move_left` / `move_right`
- `jump`, `sprint`, `crouch`
- `fire`, `reload`, `aim`
- `melee`
- `block` (if using the block/parry system; recommended as part of core melee)

These are the essential inputs needed for a functional FPS with melee combat. Without these, the core feel systems won't work.

**Optional (safe to remove or remap):**

- `interact` (for armory spots / picking configs)
- `switch_profile` (feel profile manager: Twitchy/WW2/Arcade)
- `toggle_debug_overlay` (debug overlay toggle)
- `reset_bootcamp`, `skip_bootcamp` (bootcamp / range utilities)
- Any magic-specific actions you add for your own game

These actions are only needed if you use features that require them. You can safely ignore or delete optional actions if your game doesn't use those features.

### 1.2. World scale & gravity

Cobra assumes a fairly standard "1 unit ≈ 1 meter":

- Player height ~2 units.
- Camera height ~1.6 units.
- Gravity / move speed tuned around that scale.

If your game uses wildly different units, you may need to adjust:

- `move_speed`, `sprint_speed`, `crouch_speed` in `feel_player.gd`.
- Collider shape height in `FeelPlayer.tscn`.

---

## 2. Integration Mode A — Drop-In FeelPlayer

**Best for:** rapid prototyping, or if you don't already have a custom player controller.

You use Cobra's **entire stack**:

- `FeelPlayer.tscn` as your player.
- `HUD.tscn` as your HUD.
- Cobra's weapons via `WeaponConfig`s and Armory.

### 2.1. Easiest path: use the demo scenes

For a quick "does this feel good" test:

1. Open `scenes/demo/FeelShowcase.tscn`  
   - This is the **recommended starting point**. It contains FeelPlayer + HUD + training targets + feel profile manager (Twitchy/WW2/Arcade).

2. Set it as your **Main Scene**:
   - Project Settings → Run → Main Scene → select the scene.

3. Run the project:
   - You should be able to:
     - Move (WASD), jump, crouch, sprint.
     - Aim (`aim` action), fire, reload, melee.
     - Switch feel profiles with `switch_profile` action.
     - Hit training targets and see hitmarkers/kill markers.
     - See crosshair, ammo, and range stats in the HUD.

Alternatively, you can open `scenes/TestRange.tscn` for a minimal reference scene with fewer moving parts.

This doesn't touch your game yet — it's just a sandbox to validate the feel.

---

### 2.2. Use FeelPlayer + HUD in your own level

If you have your own level/scene:

1. **Add the player:**

   - Open your level scene (e.g. `MyLevel.tscn`).
   - Instance `scenes/FeelPlayer.tscn` as a child of the root (or a dedicated "Actors" node).
   - Position it where you want the player to spawn (e.g. `(0, 1, 0)` above the ground).

2. **Add the HUD:**

   - Instance `scenes/HUD.tscn` as a child of the root.
   - Make sure there's only one HUD (don't double-instance it).

3. **Connect HUD ↔ player weapon:**

   - The demo `WW2Bootcamp` uses a tiny script (`scripts/demo/ww2_bootcamp.gd`) to connect HUD to the player's current weapon.
   - You can copy that pattern:
     - Find the `FeelPlayer` instance.
     - Get its `weapon_rig.active_weapon`.
     - Call `hud.connect_weapon(active_weapon)`.

   Example structure (pseudo-steps, not exact code):

   - In your level script:
     - On `_ready()`:
       - Get `FeelPlayer` node.
       - Get its `weapon_rig` and `active_weapon`.
       - Get HUD.
       - Call `hud.connect_weapon(active_weapon)`.

4. **Check input & movement:**

   - Ensure all actions (move, fire, aim, etc.) exist in Input Map.
   - Adjust `feel_player.gd` exported properties if needed:
     - Speed, gravity, FOVs, head bob intensity.

At this point your level uses Cobra like a **full plug-in player**. You can focus on flows, layouts, AI, etc., and only later decide if you need a custom controller.

---

## 2.5. Non-Combat / Exploration Mode

COBRA can be used as a general first-person controller for non-combat games (walking sims, narrative experiences, puzzle games, etc.) without focusing on shooting mechanics.

**Minimal steps for a controller-only setup:**

1. Instance `FeelPlayer` and `HUD` in your scene as usual (see Mode A above).

2. Activate the **Exploration** profile:
   - In the demo, press **F1** to cycle profiles until you reach Exploration.
   - Or programmatically select it via `FeelProfileManager` in your own scene.

3. Optionally hide or remove weapon meshes/configs if your game has no combat.

4. Tune movement using `config/Feel_Exploration.tres`:
   - Adjust `move_speed`, `sprint_speed`, `crouch_speed` for your desired pace.
   - Modify `hip_fov` to match your visual style.
   - Set `recoil_scale` and `shake_scale` to `0.0` for no gun kick (already set in Exploration preset).

5. If desired, tweak `FeelPlayer`'s `bob_amount`, `bob_speed`, and `bob_reset_speed` exports directly in your scene for more or less camera motion during movement.

**Note:** In the demo scenes (`FeelShowcase.tscn`), the crosshair is automatically hidden when the Exploration profile is active. You can re-enable it by calling `HUD.set_crosshair_enabled(true)` or editing the `enable_crosshair` flag in your HUD scene if needed.

**Best for:** walking sims, narrative games, puzzle games, or prototyping first-person controllers without combat mechanics.

---

## 2.6. FPS vs Magic/Melee Scene Split

COBRA provides two distinct demo scenes for different game types:

- **FPS Feel Showcase** (`scenes/demo/FeelShowcase.tscn`):
  - **Best for:** Pure FPS games, exploration-style games, or prototyping first-person controllers.
  - **Features:** Core gunfeel, movement presets (Twitchy / WW2 / Arcade / Exploration), hitscan weapons, feel profile cycling.
  - **Block feature:** Disabled by default (`enable_block = false`).
  - **Exploration profile:** Hides crosshair, gun model, and disables firing for non-combat / walking sim prototypes.

- **Magic & Melee Showcase** (`scenes/demo/MagicShowcase.tscn`):
  - **Best for:** Fantasy games, spell-slinging projects, or games with melee combos and block/parry mechanics.
  - **Features:** Projectile/magic weapons, melee combos (Light1 → Light2 → Heavy), block/parry UI, dummy targets with hit feedback.
  - **Block feature:** Enabled by default (`enable_block = true`).
  - **Magic cast UI:** HUD pulse on projectile fire (scoped to this scene only).

**Choosing Your Starting Point:**

- **FPS-only or exploration games:** Copy patterns from `FeelShowcase.tscn` and ignore `MagicShowcase` completely.
- **Fantasy/spell/melee projects:** Start from `MagicShowcase.tscn` and choose whether to enable/disable guns using `enable_fire` on `FeelPlayer`.
- **Mixed games:** Use `FeelShowcase` as base, then selectively enable features from `MagicShowcase` as needed.

**Feature Gating:**

- `enable_block` / `show_block_hint` / magic cast HUD pulse are wired **only** in `MagicShowcase`.
- `Exploration` profile in FeelShowcase hides crosshair, gun model, and firing for "walking sim" or exploration prototypes.
- You can mix and match features by copying the relevant code patterns between scenes.

---

## 3. Integration Mode B — Use Cobra Weapons in Your Own Player

**Best for:** when you already have a custom FPS controller but want Cobra's **weapon feel**, recoil, crosshair, etc.

You'll keep your own player movement, but drop in:

- `WeaponRig` (viewmodel + ADS),
- `WeaponBase` + `WeaponConfig`s (gun logic),
- `RecoilController` (camera recoil),
- Optionally `HUD` (crosshair, hitmarkers, stats).

### 3.1. Attach WeaponRig & WeaponBase to your camera

Assuming your player has a `Camera3D` already:

1. Under your camera, add a `Node3D` called `WeaponRig`:
   - Attach `scripts/player/weapon_rig.gd`.

2. Under `WeaponRig`, add a `Node3D` called `Weapon`:
   - Attach `scripts/weapons/weapon_base.gd`.
   - Set **config** in the inspector to one of:
     - `config/RifleConfig.tres`
     - `config/SMGConfig.tres`
     - `config/ShotgunConfig.tres`
     - …or a custom config you create.

3. Set the weapon's **aim node path**:
   - In `Weapon` (WeaponBase), set `aim_node_path` to your camera node (relative path).
   - In Cobra's default `FeelPlayer`, this is usually `"../.."` from the Weapon node.

4. Optionally add a viewmodel:
   - Instance a weapon model scene (e.g. Cobra's `RifleModel.tscn` if provided) as a child of `Weapon`.
   - 1st-person view tuning happens on `WeaponRig` — it handles sway/idle.

### 3.2. Add recoil to your camera

To get camera kick:

1. Insert a `RecoilPivot` Node3D between your **character body** and **Camera3D**:

   Instead of:
   - `PlayerRoot` → `Camera3D`

   use:
   - `PlayerRoot` → `RecoilPivot` → `Camera3D` → `WeaponRig` → `Weapon`

2. Attach `scripts/player/recoil_controller.gd` to `RecoilPivot`.

3. Ensure your **WeaponBase** connects to `recoil_requested` → `RecoilPivot.apply_recoil(...)`:

   - You can either:
     - Copy the connection logic from `feel_player.gd`, or
     - Manually connect in your player script:
       - After weapon is ready, connect its `recoil_requested` signal to the recoil controller.

Now the weapon's `recoil_pattern` and fire events will make your camera kick and optionally shake.

### 3.3. Hook your input into WeaponRig / WeaponBase

Cobra's default player handles input (fire, aim, reload, melee) inside `feel_player.gd`. If you're writing your own player:

- You can:
  - Call the weapon's public methods when your inputs fire, or
  - Reuse/paraphrase the patterns from `feel_player.gd`.

Typical structure for your player script:

- On `_unhandled_input(event)` or `_process`:
  - If `fire` pressed/held → tell `WeaponRig` / `WeaponBase` to fire.
  - If `reload` pressed → call the weapon's reload method.
  - If `aim` pressed/held → call `weapon_rig.set_ads(true/false)` so spread/FOV adjust.

Since function names can change over time, the safest pattern is:

- Open `feel_player.gd` and see:
  - How it calls into `weapon_rig` and `active_weapon`.
  - Reuse that code inside your own player script, but keep your movement logic.

---

## 4. Enemies & Damageable Integration

Any enemy or target can participate in the hit/kill pipeline by using the `Damageable` script. This is how `TrainingTarget` works in the range — when shot, they take damage, emit signals, and the HUD shows hitmarkers and kill markers.

### 4.1. Damageable Contract

**Script:** `scripts/weapons/damageable.gd`

**Core elements:**

- **Signal:**
  - `died(killer: Node)` — emitted when health drops to 0 or below.

- **Method:**
  - `func apply_damage(amount: float, killer: Node = null) -> bool`  
    Subtracts health. Returns `true` if this call killed the target, `false` if still alive.  
    On death:
    - Emits `died(killer)` signal.
    - If `killer` has a `kill_confirmed` signal, automatically emits `killer.kill_confirmed(self)`.
    - Calls `queue_free()` to remove the target.

- **Properties:**
  - `@export var max_health: float = 100.0` — initial health pool.

### 4.2. Signal Pipeline

Here's how the damage/hit/kill pipeline works:

1. **WeaponBase raycast hits something with Damageable:**
   - `WeaponBase._perform_shot()` performs a raycast from the camera.
   - If the raycast hits a collider that has an `apply_damage()` method:
     - Calls `collider.apply_damage(config.damage, self)` (passes the weapon as `killer`).

2. **Damageable processes damage:**
   - `Damageable.apply_damage()` subtracts health.
   - If health <= 0:
     - Emits `died(killer)` signal.
     - If `killer` (WeaponBase) has a `kill_confirmed` signal, emits `killer.kill_confirmed(self)`.
     - Calls `queue_free()`.
     - Returns `true` (killed).
   - Otherwise returns `false` (alive).

3. **WeaponBase reacts to result:**
   - If `apply_damage()` returns `false` → WeaponBase emits `hit_confirmed(collider)`.
   - If it returns `true` → Damageable already emitted `kill_confirmed` on the weapon, so WeaponBase doesn't emit `hit_confirmed`.

4. **HUD receives signals:**
   - HUD listens to `hit_confirmed` → shows regular hitmarker.
   - HUD listens to `kill_confirmed` → shows kill marker & updates stats.

**Signal chain:**
```
WeaponBase._perform_shot()
  → collider.apply_damage(damage, self)
    → Damageable.apply_damage()
      → if health <= 0:
        → emit died(killer)
        → killer.emit_signal("kill_confirmed", self)  [if killer has signal]
        → queue_free()
        → return true
  → if returned false: WeaponBase.emit_signal("hit_confirmed", collider)
  → if returned true: kill_confirmed already emitted, skip hit_confirmed
```

### 4.3. Example: Custom Enemy with Damageable

Here's a simple example of an enemy scene using Damageable:

```gdscript
# Example: Enemy scene using Damageable
extends CharacterBody3D

@onready var damageable: Damageable = $Damageable

func _ready() -> void:
    damageable.died.connect(_on_died)

func _on_died(killer: Node) -> void:
    # Play death animation, spawn VFX, drop loot, etc.
    print("Enemy died, killed by: ", killer.name)
    # Damageable already calls queue_free(), but you can add cleanup here
```

**Scene structure:**
- Root: `CharacterBody3D` (your enemy controller).
- Child: `Damageable` node (attach `scripts/weapons/damageable.gd`).
- Connect to `died` signal for custom death behavior.

Cobra's `TrainingTarget` (`scenes/TrainingTarget.tscn`) uses this exact pattern — it extends `Damageable` and connects to the `died` signal to spawn SFX/VFX on death.

### 4.4. Example: Game Manager Hook

Here's how to hook a custom game manager into the kill pipeline:

```gdscript
# Example: GameManager that tracks kills
extends Node

var kills: int = 0

func register_weapon(weapon: WeaponBase) -> void:
    if not weapon.kill_confirmed.is_connected(_on_kill_confirmed):
        weapon.kill_confirmed.connect(_on_kill_confirmed)

func _on_kill_confirmed(target: Node) -> void:
    kills += 1
    print("Total kills: ", kills)
    # Update UI, spawn effects, check win condition, etc.
```

In Mode A, the HUD already tracks kills for range stats. In Mode B or custom setups, you can wire any manager you want to react to `kill_confirmed` signals.

---

## 5. HUD Integration — Mode A vs Mode B

### 5.1. Mode A: Using COBRA HUD

If you're using Mode A (Drop-In FeelPlayer), you get Cobra's full HUD for free.

**Setup:**

1. Instance `scenes/HUD.tscn` at the root of your scene.
2. Make sure there's only one HUD (don't double-instance it).
3. In your level script, on `_ready()`:
   - Get the `FeelPlayer` node.
   - Get its `weapon_rig.active_weapon`.
   - Call `hud.connect_weapon(active_weapon)`.

**That's it!** HUD automatically wires:
- `ammo_changed` → updates ammo display.
- `hit_confirmed` → shows regular hitmarker.
- `kill_confirmed` → shows kill marker & updates stats.
- `shot_fired` → tracks shots for accuracy stats.

HUD handles all signal connections and disconnections internally. You just call `connect_weapon()` once and you're done.

### 5.2. Mode B: Building a Custom HUD

If you're using Mode B (custom player) or want your own HUD implementation, you need to handle the weapon contract yourself.

**HUD Contract:**

Your weapon (or weapon controller) should:

- Emit **signals**:
  - `ammo_changed(current_in_mag: int, mag_size: int)` — when ammo changes (fire, reload, swap).
  - `hit_confirmed(target: Node)` — called when a shot hits something (non-lethal).
  - `kill_confirmed(target: Node)` — when a Damageable target dies (lethal).
  - Optionally `shot_fired()` — for stats tracking.
- Implement:
  - `func get_spread_ratio() -> float`  
    Returns a value around [0, 1] representing how "spread out" the weapon currently is (Cobra's WeaponBase already does this).

**Minimal Custom HUD Example:**

```gdscript
# Example: Minimal custom HUD contract
extends Control

var _connected_weapon: WeaponBase = null

@onready var ammo_label: Label = $AmmoLabel
@onready var crosshair: Control = $Crosshair
@onready var hitmarker: Control = $Hitmarker

func connect_weapon(weapon: WeaponBase) -> void:
    # Disconnect previous weapon if exists
    if _connected_weapon:
        if _connected_weapon.ammo_changed.is_connected(_on_ammo_changed):
            _connected_weapon.ammo_changed.disconnect(_on_ammo_changed)
        if _connected_weapon.hit_confirmed.is_connected(_on_hit_confirmed):
            _connected_weapon.hit_confirmed.disconnect(_on_hit_confirmed)
        if _connected_weapon.has_signal("kill_confirmed") and _connected_weapon.kill_confirmed.is_connected(_on_kill_confirmed):
            _connected_weapon.kill_confirmed.disconnect(_on_kill_confirmed)
    
    _connected_weapon = weapon
    
    if _connected_weapon:
        # Connect signals
        _connected_weapon.ammo_changed.connect(_on_ammo_changed)
        _connected_weapon.hit_confirmed.connect(_on_hit_confirmed)
        if _connected_weapon.has_signal("kill_confirmed"):
            _connected_weapon.kill_confirmed.connect(_on_kill_confirmed)
        
        # Initialize display
        _on_ammo_changed(_connected_weapon.get_current_ammo(), _connected_weapon.config.mag_size)

func _on_ammo_changed(current: int, max_ammo: int) -> void:
    if ammo_label:
        ammo_label.text = "%d / %d" % [current, max_ammo]

func _on_hit_confirmed(target: Node) -> void:
    # Show regular hitmarker
    if hitmarker:
        hitmarker.show()
        # Hide after delay...

func _on_kill_confirmed(target: Node) -> void:
    # Show kill marker
    if hitmarker:
        hitmarker.modulate = Color.RED
        hitmarker.show()
        # Hide after delay...
```

You can:

- Reuse `WeaponBase` directly (it already implements this contract), or
- Have your own weapon script that proxies these signals & methods in the same shape.

---

## 6. Mixing Modes (Hybrid Setup)

You don't have to pick one mode forever. Some common hybrids:

### Hybrid 1 — Your movement, Cobra camera & weapons

- Keep your own `CharacterBody3D` for movement.
- Use Cobra's:
  - `RecoilPivot` + `Camera3D`.
  - `WeaponRig` + `WeaponBase` + `WeaponConfig`.
  - `HUD`.

This gives you:

- Full control over movement and game rules.
- Shared Cobra weapon feel, recoil, and HUD across multiple projects.

### Hybrid 2 — Cobra player for prototyping, custom later

- Early on:
  - Use `FeelPlayer.tscn` + `HUD.tscn` + `FeelShowcase.tscn` to tune weapons and level ideas.
- Later:
  - Swap in your own player controller, but keep:
    - `WeaponRig`, `WeaponBase`, `WeaponConfig`.
    - `RecoilController`.
    - `HUD`.

That way your future game can still consume Cobra configs and demo scenes as a **test harness**, even if the shipped controller is custom.

---

## 7. Checklist for "Cobra Is Working" in Your Game

When everything's wired correctly, you should be able to:

- **Move the camera**:
  - Mouse/controller look works as usual.
  - Recoil kicks the camera when you fire.
  - ADS tightens FOV and slows sensitivity.

- **Fire a weapon**:
  - Ammo decreases and HUD updates.
  - Crosshair expands when moving/firing.
  - Muzzle flash & sound play on fire.
  - Hitmarker appears on hits, kill marker on kills.
  - Damageable targets (like TrainingTarget) react and can be destroyed.

- **Swap weapons** (if using weapon selection/armory features):
  - `interact` on a weapon spot:
    - Weapon config changes.
    - Ammo resets to full mag of the new config.
    - HUD still works without changes.

If you can do all of that in your own level or game, Cobra is fully integrated.

---

## 8. Example Scenes Reference

**Primary Demo Scene:**
- `scenes/demo/FeelShowcase.tscn`  
  **Recommended starting point.** Contains FeelPlayer + HUD + training targets + feel profile manager (Twitchy/WW2/Arcade). Run this scene to see everything working together. Great for learning the engine and testing your own configs.

**Minimal Reference:**
- `scenes/TestRange.tscn`  
  Simple test environment with fewer moving parts. Useful as a minimal reference for basic integration.

**Optional:**
- `scenes/demo/MagicShowcase.tscn`  
  Demo scene for projectile/magic weapons. Shows how to use `projectile_scene` with `WeaponBase` to fire visible projectiles. Safe to ignore if you only need hitscan weapons.

**Optional / Experimental:**
- `scenes/demo/WW2Bootcamp.tscn`  
  Example game-specific bootcamp level with armory, movement course, shooting range, and scoring. This is an experimental demo scene and not required for integration. Use it as a reference for game-specific features only.

---

## 9. If You Get Stuck

If integration feels confusing, a good debugging workflow is:

1. Open `scenes/demo/FeelShowcase.tscn` (or `scenes/TestRange.tscn` for a simpler reference).
2. Compare its structure to your scene:
   - Where `FeelPlayer`, `RecoilPivot`, `Camera3D`, `WeaponRig`, `Weapon` and `HUD` live.
3. Open:
   - `scripts/player/feel_player.gd` for input patterns.
   - `scripts/demo/feel_showcase.gd` for HUD ↔ weapon wiring (in FeelShowcase).
   - `scripts/test_range.gd` for HUD ↔ weapon wiring (in TestRange).
4. Mirror those patterns step-by-step in your own scene.

Cobra is meant to be **modular, not magical**: everything is regular Godot scenes & scripts glued together in a clear way, so you can copy, delete, or rewrite any layer you don't like while keeping the rest.

