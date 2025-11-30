# FPS Feel Kit – Roadmap (Godot 4)



## Vision & Tagline



**Tagline:**  

A small, feel-first first-person shooting & melee kit for Godot 4 – easy to drop into any project, easy to tweak, and powerful enough to be your game's long-term weapon foundation.



**Design Pillars:**

1. **Feel-first:** Recoil, sway, ADS, melee weight, and hit feedback matter more than features.

2. **Drop-in friendly:** One scene to use as-is; a clear API to plug into custom players.

3. **Data-driven:** Weapons and melee are mostly numbers + assets in config resources.

4. **Minimal but extensible:** No inventory, AI, or big "game framework." Just player, camera, weapons, HUD.

5. **Well-documented:** README + small docs folder that explain both usage and design.



**Non-Goals (for v0.x):**

- No full inventory/loot system.

- No network/multiplayer.

- No advanced AI or mission logic.

- No fancy editor tools beyond basic inspectors and scenes.



---



## Milestone v0.1 – Core Feel Sandbox (Internal MVP)



**Goal:**  

Have a single test scene with a functional FPS controller, one rifle, one basic melee weapon, and a simple HUD – all wired through clean configs and signals.



### 1. Project Setup



- Create `fps-feel-kit` Godot 4 project.

- Base folder layout:

  - `scenes/` (Player, Weapons, TestRange)

  - `scripts/player/`, `scripts/weapons/`, `scripts/hud/`, `scripts/config/`

  - `art/` (placeholder models)

  - `audio/` (placeholder SFX)

  - `docs/`

- Add basic input map:

  - `move_forward/back/left/right`, `jump`, `sprint`, `fire`, `reload`, `aim`, `melee`.



### 2. Player & Camera (v0.1)



- `FeelPlayer.tscn`:

  - `CharacterBody3D` with:

    - Walk and sprint

    - Jump

  - Exposed properties:

    - `move_speed`, `sprint_speed`, `jump_force`, `mouse_sensitivity`.

- Attach `FeelPlayer.gd`:

  - Handles movement and mouse look.

  - Uses exported vars for easy tuning.

- `Camera3D` child:

  - Hook mouse look (yaw on body, pitch on camera).

  - Setup basic head bob (simple sin wave) with toggles:

    - `bob_amount`, `bob_speed`.



### 3. Weapon Config System



- `WeaponConfig.gd` (Resource):

  - Fields:

    - `display_name`

    - `fire_mode` (enum: SEMI_AUTO, FULL_AUTO, BURST)

    - Core stats: `damage`, `fire_rate`, `mag_size`, `reload_time`

    - Accuracy: `hip_spread`, `ads_spread`, `spread_increase_per_shot`, `spread_decay_rate`

    - Recoil: `recoil_pattern: Array[Vector2]`, `recoil_reset_speed`

    - Assets:

      - `model_scene`, `muzzle_flash_scene`, `impact_effect_scene`

      - `fire_sfx`, `reload_sfx`, `empty_sfx`

- Provide a sample `RifleConfig.tres` in `config/`.



### 4. Weapon Base + Hitscan Rifle



- `WeaponBase.gd`:

  - Signals:

    - `fired`, `hit_confirmed(target)`, `ammo_changed(current, max)`,

      `reload_started`, `reload_finished`

  - Shared logic:

    - Ammo tracking, fire rate gating, reload timer.

    - Spread accumulation/decay.

    - Recoil index progression.

  - Methods:

    - `try_fire()`, `try_reload()`, `set_ads(enabled: bool)`

- `HitscanWeapon.gd` inheriting from `WeaponBase`:

  - At `_do_fire`:

    - Get camera forward direction.

    - Apply spread cone.

    - Raycast from camera into world.

    - If hit:

      - Damage via simple interface (e.g., `apply_damage(damage)` if target has it).

      - Spawn impact VFX.

      - Emit `hit_confirmed`.

- `WeaponRig.tscn`:

  - Node with:

    - `WeaponBase` child (active_weapon).

    - Methods:

      - `fire()`, `reload()`, `set_ads(bool)` delegating to active weapon.



### 5. Basic Melee Weapon (v0.1)



- `MeleeConfig.gd` (can reuse `WeaponConfig` or a separate resource for clarity):

  - `display_name`

  - `damage`

  - `range`

  - `swing_time`

  - `recovery_time`

  - `hitbox_radius`

  - Assets: `model_scene`, `swing_sfx`, `hit_sfx`, `hit_effect_scene`.

- `MeleeWeapon.gd` (inherits `WeaponBase` or shares a smaller base class):

  - Overrides `try_fire()` to:

    - Start melee swing state.

    - At "impact time" (using a Timer or simple state machine):

      - Sphere/capsule cast in front of camera.

      - Apply damage + spawn hit effects.

    - Respect recovery time before next swing.



### 6. HUD v0.1



- `HUD.tscn`:

  - Simple crosshair (static).

  - Ammo display:

    - Bind to `ammo_changed` signal from active weapon.

  - Hit marker:

    - Subtle sprite that flashes on `hit_confirmed`.

- `HUDController.gd`:

  - Listens to weapon signals.

  - Simple fade-in/out animation for hitmarker.



### 7. Test Range Scene



- `TestRange.tscn`:

  - Flat ground + some walls.

  - A few "dummy" nodes (targets) with simple `Health.gd` that:

    - Receives `apply_damage(amount)`.

    - Changes color or disappears on "death".

  - Instance:

    - `FeelPlayer` at spawn.

    - `HUD` via autoload or child of a central UI node.

- Basic text labels on screen:

  - Movement controls.

  - Fire/reload/aim/melee.



### 8. v0.1 Docs



- `README.md` basic:

  - What this is (feel-first kit).

  - Quickstart:

    - Open project.

    - Run `TestRange`.

  - Minimal explanation of:

    - `FeelPlayer`, `WeaponConfig`, `WeaponBase`, `HUD`.

- `docs/weapon-system-overview.md`:

  - 1–2 pages explaining:

    - Config system.

    - WeaponBase responsibilities.

    - How to make a new weapon (step-by-step).



---



## Milestone v0.2 – Feel & Tuning Pass



**Goal:**  

Improve the "juice" and tunability: recoil, sway, ADS, audio layering, and HUD behavior. Make it feel genuinely satisfying.



### 1. Camera & Recoil Polish



- Create `RecoilController.gd`:

  - Owned by the camera rig.

  - Public method: `apply_recoil(offset: Vector2, scale: float = 1.0)`.

  - Smooth interpolation back to neutral over time using `recoil_reset_speed`.

- Connect:

  - Weapon emits recoil offsets → `RecoilController` applies them.

- ADS FOV:

  - Export `hip_fov` and `ads_fov` on camera.

  - Smooth tween between them on `set_ads()`.

  - Optionally adjust mouse sensitivity while ADS (`ads_sensitivity_multiplier`).



### 2. Weapon Sway & Idle Motion



- Add weapon sway:

  - Based on mouse movement and small idle sin wave.

  - Exported vars on `WeaponRig`:

    - `sway_amount`, `sway_speed`, `idle_sway_amount`, `idle_sway_speed`.

- Separate "viewmodel" child:

  - Weapon model moves/sways independently of camera rotation.



### 3. Audio & VFX Layering



- Fire SFX:

  - Fire sound + optional mechanical/bolt sound layer.

- Reload SFX:

  - Option to trigger multiple sounds (mag out, mag in).

- VFX:

  - Improve muzzle flash (short lifespan, light flash).

  - Add simple screen shake (small, tweakable) for firing.



### 4. HUD Enhancements



- Crosshair:

  - Expand based on:

    - Current spread.

    - Player moving vs idle.

  - Exported tuning:

    - `min_size`, `max_size`, `movement_influence`, `spread_influence`.

- Hitmarker:

  - Two states:

    - Hit (white, small).

    - Kill (red, slightly larger or different SFX).

- Option flags:

  - `show_crosshair`, `show_hitmarker`, `show_ammo`.



### 5. Config Tweaking UX



- Create a few example configs:

  - `RifleConfig`, `SMGConfig`, `ShotgunConfig` (even if same model, just different stats).

- `docs/tuning-guide.md`:

  - "How to tune recoil."

  - "How to make a gun feel snappy vs heavy."

  - Before/after examples with suggested values.



---



## Milestone v0.3 – Melee & Fantasy-Ready



**Goal:**  

Make melee feel good and flexible enough for swords/axes/magic wands. Support more than just "one basic swing."



### 1. Melee System Expansion



- Combo support:

  - Allow `MeleeWeapon` to have multiple swing profiles (light/light/heavy).

  - Config fields:

    - `combo_sequence` as an array of "swing data":

      - `damage`, `range`, `swing_time`, `recovery_time`, `animation_name`.

- Blocking/parrying (optional but nice):

  - Simple `block` state:

    - Reduces incoming damage if block key held during window.

  - Signals/hook for when a block/parry happens.



### 2. Animation Hooks



- Define clear hooks for animation:

  - `on_melee_swing_start()`

  - `on_melee_impact()`

  - `on_melee_recover()`

- Document how other devs can:

  - Plug in their own animations (sword swings, spells).

  - Use AnimationPlayer/AnimationTree to drive weapon model.



### 3. Fantasy-Flavor Support (without hardcoding)



- Ensure configs aren't gun-specific:

  - Fields like `projectile_scene` (optional) to support magic bolts or arrows later.

  - Generic naming like `primary_attack`, `alt_attack` instead of "fire" where possible.

- Example:

  - A "Magic Staff" config using hitscan or projectile.

  - A "Longsword" config using melee combo.



### 4. Test Scene Upgrade



- Add:

  - A few close-range dummies for melee testing.

  - Slight verticality (stairs, platforms) to check camera/movement robustness.

- Visual cues:

  - Materials or decals to clearly show impacts (bullet vs slash).



---



## Milestone v0.4 – Community Release & Integration Experience



**Goal:**  

Make it trivial for other devs to understand, integrate, and extend. Polish docs, repo, and examples.



### 1. Integration Paths (Clear API)



- Document **two main usage modes**:



  **A) Use `FeelPlayer` as-is**

  - Steps:

    - Instance `FeelPlayer.tscn` into their level.

    - Hook their spawn logic if needed.

    - Swap weapon configs to their own assets.



  **B) Use only weapons with their own player**

  - Steps:

    - Instance `WeaponRig` as a child of their camera.

    - Connect their inputs:

      - `weapon_rig.fire()`, `weapon_rig.reload()`, `weapon_rig.set_ads()`, `weapon_rig.melee()`.

    - Subscribe to `ammo_changed`, `hit_confirmed` to drive *their* HUD.



### 2. Repo & Docs Polish



- `README.md`:

  - Project description + GIF demos.

  - "Who this is for."

  - Quickstart steps.

  - Integration paths section.

- `docs/`:

  - `design-pillars.md` – philosophy & non-goals.

  - `weapon-system-overview.md` – detailed.

  - `tuning-guide.md` – practical sliders-to-feel guidance.

  - `melee-system.md` – how to configure combos and swings.

- Add simple diagrams:

  - Weapon flow: Input → WeaponRig → WeaponBase → Recoil/HUD.



### 3. Example Content



- Finalize:

  - 2–3 ranged weapons:

    - E.g., Rifle, SMG, "Magic Staff".

  - 2 melee weapons:

    - E.g., Sword, Hammer/Axe.

- Make a short "feel showcase" scene:

  - Rotating dummies.

  - Moving targets (simple KinematicBody3D paths).

  - A small "shooting gallery" loop.



### 4. Packaging & Release



- Ensure license:

  - MIT (or other permissive license) in `LICENSE`.

- Tag `v0.4.0` release on GitHub.

- Optional:

  - Submit to Godot Asset Library as "FPS Feel Kit".

  - Add a small "Credits / How to Support" section in README.



---



## Future Ideas (Post v0.4, Only If Fun)



- Optional "advanced" branch or v0.5+:

  - Basic inventory/weapon switching system.

  - Stamina system for melee.

  - More complex recoil patterns (time-based curves).

  - Editor helpers (inspector tools for previewing recoil/spread).

- Community feedback:

  - Add issues/templates:

    - Feature requests.

    - Bug reports.

    - "Showcase" links for games using the kit.



---
