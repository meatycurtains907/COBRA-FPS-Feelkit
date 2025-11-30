# Feel Profiles & Recipes (Tuning Cookbook)

> File: `docs/feel_profiles.md`

A **feel profile** in COBRA is a complete bundle that defines how your game feels: one `PlayerFeelConfig` for movement, look, and FOV; a **family** of `WeaponConfig` presets (Rifle, SMG, Shotgun) for that vibe; and one `CrosshairConfig` for HUD visuals.

COBRA ships with four main feel profiles available in the F1 cycle: **Twitchy CSGO-like** (fast, responsive), **WW2 Heavy Soldier** (grounded, weighty), **Arcade Hero Shooter** (high mobility, forgiving), and **Exploration** (non-combat walking sim style). The **FeelProfileManager** in the demo (at `scripts/demo/feel_profile_manager.gd`) cycles these four profiles when you press F1, swapping the **Rifle** configs for the active weapon. Each profile family also includes SMG and Shotgun configs that you can assign manually to other weapon nodes.

**Note:** The **MagicArcane** profile is a separate, optional configuration used by `MagicShowcase.tscn` for projectile/magic weapon demos. It is **not** part of the F1 cycle. If your game is purely hitscan FPS + melee, you can ignore the MagicArcane presets entirely.

This doc is for developers who want to create their own feel profiles without reverse-engineering all the numbers. It focuses on practical recipes and tweaking strategies.

**Where things live:**

- Player feel configs: `res://config/Feel_*.tres`
- Weapon presets: `res://config/Rifle_*.tres`, `SMG_*.tres`, `Shotgun_*.tres`
- Crosshair configs: `res://config/Crosshair_*.tres`

**Related docs:**

- `docs/weapon-system-overview.md` — System architecture and how weapons work
- `docs/weapon-feel-presets.md` — Field-by-field tuning guide with detailed numbers
- `docs/integration-modes.md` — How to integrate COBRA into your project

---

## 1. What is a Feel Profile?

A feel profile is **PlayerFeelConfig + WeaponConfig family + CrosshairConfig**. These three layers work together:

- **PlayerFeelConfig** decides how the body & camera move (speed, sensitivity, FOV, recoil scaling).
- **WeaponConfig presets** decide how each gun kicks, spreads, reloads, and sounds.
- **CrosshairConfig** decides how the HUD visualizes that feel (size, behavior, colors, hitmarkers).

The **family** part means for each vibe (Twitchy / WW2 / Arcade) you have:

- One `PlayerFeelConfig` (`Feel_Twitchy.tres`, `Feel_WW2.tres`, `Feel_Arcade.tres`)
- Three `WeaponConfig` presets for that vibe (Rifle, SMG, Shotgun)
- One `CrosshairConfig`

**Important note:** In the **demo**, `FeelProfileManager` only swaps the **active weapon's config** (usually a rifle) when you cycle profiles. However, all three presets per family exist and can be assigned to SMG/Shotgun weapons in your own scenes. This gives you a complete feel family even if the switcher only handles one weapon type for simplicity.

---

## 2. Preset Families

COBRA includes four main feel profiles that are available in the F1 cycle in `FeelShowcase.tscn`:

- **Twitchy** — CSGO/Valorant-style snappy profile (fast, responsive, low visual shake)
- **WW2** — Heavy soldier profile (grounded, slower movement and ADS, pronounced rifle kick)
- **Arcade** — Hero-shooter profile (high mobility, generous accuracy, clear HUD feedback)
- **Exploration** — Non-combat / walking sim profile (slower movement, no weapons/crosshair by default)

These four profiles are designed for hitscan weapons (except Exploration, which is for non-combat first-person controllers). Each profile includes a complete family: PlayerFeelConfig + WeaponConfig presets (Rifle, SMG, Shotgun) + CrosshairConfig.

**Separate from the F1 cycle:** The **MagicArcane** profile is an optional configuration used by `MagicShowcase.tscn` for projectile/magic weapon demos. It is **not** part of the F1 profile switcher and is intended for developers who want to experiment with projectile-based weapons. You can completely ignore MagicArcane if your game uses only hitscan weapons.

---

## 3. PlayerFeelConfig: Movement, Look & FOV

`PlayerFeelConfig` is a Resource used by `FeelPlayer` via its `feel_config` export. It lives under `config/` and controls movement speeds, camera sensitivity, FOV transitions, and global recoil/shake scaling.

### 2.1 Movement Fields

- **`move_speed`** — Walk speed (base strafing/running)
- **`sprint_speed`** — Sprint speed
- **`crouch_speed`** — Movement speed while crouched
- **`jump_force`** — Vertical impulse when jumping

**Tradeoffs:** For grounded, "realistic" soldiers (like WW2), keep `move_speed`/`sprint_speed` modest and `crouch_speed` significantly lower. For arcade heroes, all three can be higher and closer together for fluid mobility.

### 2.2 Look & ADS Fields

- **`mouse_sensitivity`** — Base look sensitivity
- **`ads_sensitivity_multiplier`** — Multiplier applied in ADS (usually < 1.0)

**Tradeoffs:** Twitchy profiles lean toward slightly higher base sensitivity and ADS multipliers closer to 1.0 for snappy aim. Heavy profiles lean lower for precision and deliberate aiming. Lower sensitivity = more precise, less twitchy. ADS multiplier **< 1.0** = slower, more controlled ADS.

### 2.3 FOV & ADS Timing

- **`hip_fov`** — FOV while hip-firing
- **`ads_fov`** — Target FOV while aiming
- **`ads_fov_lerp_speed`** — How quickly FOV transitions between hip & ADS

**Tradeoffs:** 
- Higher `hip_fov` = faster-feeling and more peripheral vision (arcade).
- Smaller `ads_fov` = tighter, more zoomed ADS (WW2 bolt rifles).
- Higher lerp speed = snappier ADS; lower = weightier weapon raise.

### 2.4 Recoil & Shake Scaling

- **`recoil_scale`** — Global multiplier on weapon recoil
- **`shake_scale`** — Multiplier on camera shake intensity

These are "macro knobs" to increase or decrease overall recoil/visual punch without editing every `WeaponConfig`. Use **recoil_scale** to globally buff/nerf recoil without changing per-weapon patterns. Use **shake_scale** to keep recoil visible in the camera without being nauseating.

> For deeper math and per-weapon examples, see `docs/weapon-feel-presets.md`.

---

## 4. WeaponConfig Presets (Rifle / SMG / Shotgun Families)

Each feel family ships with **three weapons**: Rifle, SMG, and Shotgun. For each family you have:

- **Twitchy:** `Rifle_Twitchy.tres`, `SMG_Twitchy.tres`, `Shotgun_Twitchy.tres`
- **WW2:** `Rifle_WW2.tres`, `SMG_WW2.tres`, `Shotgun_WW2.tres`
- **Arcade:** `Rifle_Arcade.tres`, `SMG_Arcade.tres`, `Shotgun_Arcade.tres`

**Key WeaponConfig fields:**

- **Damage & pacing:**
  - `damage`, `fire_rate`, `mag_size`, `reload_time`
- **Accuracy:**
  - `hip_spread`, `ads_spread`, `spread_increase_per_shot`, `spread_decay_rate`
- **Recoil:**
  - `recoil_pattern : Array[Vector2]` (x = yaw, y = pitch)
  - `recoil_reset_speed`
- **Behavior & feedback:**
  - `fire_mode` (SEMI_AUTO / FULL_AUTO / BURST)
  - `fire_sfx`, `reload_sfx`, `empty_sfx`
  - `muzzle_flash_scene`, `impact_effect_scene`

> This doc focuses on how these presets combine into feel profiles. For detailed tuning advice (e.g., how to shape `recoil_pattern`), see `docs/weapon-feel-presets.md`.

---

## 5. CrosshairConfig: Visualizing Spread & State

CrosshairConfig is used by the HUD to drive crosshair visuals and hitmarkers. It maps weapon spread and movement state into visual feedback.

**Key fields:**

- **Colors:**
  - `base_color` — Crosshair line color
  - `hit_color` — Hitmarker color for normal hits
  - `kill_color` — Hitmarker color for kills
- **Size & behavior:**
  - `min_size` — Minimum size at rest
  - `max_size` — Maximum size when fully inaccurate / moving
  - `spread_weight` — Influence of weapon spread on crosshair size
  - `movement_weight` — Influence of movement state on crosshair size
  - `smooth_speed` — How fast it interpolates between sizes
- **Hitmarker:**
  - `show_hitmarker` — Toggle hitmarker on or off
- **Style tag:**
  - `style` — A **free-form string** used as a style hint. Currently the built-in configs use `"cross"` as the default. The current implementation doesn't strongly depend on this value; it's mainly for tooling or categorization if you want it.

**General trends:**

- **Twitchy:** Smaller `min_size`, faster `smooth_speed` for snappy feedback
- **WW2:** Slightly larger sizes, slower `smooth_speed` for weighty feel
- **Arcade:** Brighter colors and more dramatic size delta for juicy feedback

---

## 6. Feel Profile Recipes

Each recipe is a **bundle** of: one PlayerFeelConfig, a **family** of WeaponConfigs for that vibe, and one CrosshairConfig.

**Important note:** The **demo** profile switcher (FeelProfileManager at `scripts/demo/feel_profile_manager.gd`) currently swaps the **active weapon's config** (Rifle) + feel_config + crosshair_config. SMG/Shotgun for each family are still available; they just aren't cycled automatically in the demo.

### 5.1 Twitchy CSGO-like

**Goals:**
- Quick strafing and ADS
- Small, snappy crosshair
- Recoil that is readable but not too screen-shaky

**Use these presets:**

- **Player:** `config/Feel_Twitchy.tres`
- **Weapons (family):**
  - `config/Rifle_Twitchy.tres`
  - `config/SMG_Twitchy.tres`
  - `config/Shotgun_Twitchy.tres`
- **Crosshair:** `config/Crosshair_Twitchy.tres`

**Twitch it up further:**
- Slightly increase `mouse_sensitivity` in `Feel_Twitchy`
- Increase `hip_fov` a bit to amplify sense of speed
- Bring `ads_fov` closer to hip_fov for a less zoomy, more responsive ADS
- Lower `shake_scale` if shake feels noisy
- In `Crosshair_Twitchy`, reduce `min_size`, keep `smooth_speed` relatively high so crosshair reacts quickly to spread/movement

### 5.2 WW2 Heavy Soldier

**Goals:**
- Slower, heavier movement
- Pronounced rifle kick
- ADS feels like raising a heavy weapon

**Use these presets:**

- **Player:** `config/Feel_WW2.tres`
- **Weapons:**
  - `config/Rifle_WW2.tres`
  - `config/SMG_WW2.tres`
  - `config/Shotgun_WW2.tres`
- **Crosshair:** `config/Crosshair_WW2.tres`

**Tune toward more/less heaviness:**
- Decrease `move_speed` and `sprint_speed` for more weight
- Keep `crouch_speed` significantly lower to reward commitment
- Use a slightly smaller `hip_fov` and clearly reduced `ads_fov`
- Increase `recoil_scale` to exaggerate bolt rifle kick
- In WW2 weapon configs:
  - Higher `damage` for rifles with slower `fire_rate`
  - Fairly tight `ads_spread`, but more `spread_increase_per_shot`
- In `Crosshair_WW2`:
  - Increase `min_size`/`max_size` a bit
  - Reduce `smooth_speed` so crosshair "lags" behind state changes

### 5.3 Arcade Hero Shooter

**Goals:**
- Fast movement and jump
- Forgiving recoil/spread
- Clear, satisfying HUD feedback

**Use these presets:**

- **Player:** `config/Feel_Arcade.tres`
- **Weapons:**
  - `config/Rifle_Arcade.tres`
  - `config/SMG_Arcade.tres`
  - `config/Shotgun_Arcade.tres`
- **Crosshair:** `config/Crosshair_Arcade.tres`

**Tune for more arcade punch:**
- Increase `move_speed`, `sprint_speed`, and slightly `jump_force`
- Slightly higher `hip_fov` for speed
- Lower `recoil_scale` and `shake_scale` for smoother aiming
- In Arcade weapon configs:
  - Increase `mag_size`
  - Lower `spread_increase_per_shot`, increase `spread_decay_rate`
- In `Crosshair_Arcade`:
  - Use bright `base_color`, `hit_color`, and `kill_color`
  - Make `max_size` a noticeable step above `min_size` for juicy feedback

### 5.4 Exploration (Non-Combat / Walking Sim)

**Goals:**
- Slower, more contemplative movement
- Softer sprint that doesn't feel like combat rush
- Minimal recoil/shake for calm exploration
- Suitable for narrative games, walking sims, or prototyping first-person controllers

**Use these presets:**
- **Player:** `config/Feel_Exploration.tres`
- **Weapons:** (Optional — Exploration is designed for non-combat, but `SMG_Twitchy.tres` is wired by default if you want to enable weapons)
- **Crosshair:** `config/Crosshair_Twitchy.tres` (typically hidden in demo scenes when Exploration is active)

**Tunable fields in `Feel_Exploration.tres`:**
- `move_speed` — Base walking speed (default: 4.0, slower than combat presets)
- `sprint_speed` — Sprint speed (default: 5.2, a modest step above move_speed for soft sprint)
- `crouch_speed` — Crouched movement (default: 2.5, slower than walk for meaningful crouch)
- `hip_fov` — Field of view (default: 75.0, moderate FOV)
- `recoil_scale` — Recoil multiplier (default: 0.0, no gun kick)
- `shake_scale` — Camera shake multiplier (default: 0.0, no shake)

**Important notes:**
- **Head-bob tuning:** Camera bobbing is controlled by `FeelPlayer` exports (`bob_amount`, `bob_speed`, `bob_reset_speed`), not in `PlayerFeelConfig`. If you want less bob for Exploration, adjust those exports directly on your `FeelPlayer` instance in the scene.
- **Crosshair visibility:** In the demo scenes (`FeelShowcase.tscn`), the HUD crosshair is automatically hidden when the Exploration profile is active (via script logic in `feel_showcase.gd` and `HUD.enable_crosshair`). Developers can override this by calling `HUD.set_crosshair_enabled(true)` or editing their own HUD scene.

**Reference:** All movement/FOV tuning for this preset is controlled via `config/Feel_Exploration.tres`.

**Tune for different exploration feels:**
- Increase `move_speed`/`sprint_speed` slightly for faster-paced exploration
- Adjust `hip_fov` to match your game's visual style (lower = more focused, higher = more peripheral vision)
- Modify `FeelPlayer`'s `bob_amount` directly in your scene to reduce or increase camera motion

### 6.4 MagicArcane (Optional — Projectile/Magic)

**Goals:**
- Tuned for visible projectile weapons
- Slightly slower fire rate to track projectile motion
- Magic-themed visual identity

**Use these presets:**
- **Player:** `config/Feel_MagicArcane.tres`
- **Weapons:**
  - `config/Rifle_MagicArcane.tres`
  - (Optional: SMG/Shotgun variants can be created if needed)
- **Crosshair:** `config/Crosshair_MagicArcane.tres`

**Important:** The **MagicArcane** family is **optional** and primarily used in `MagicShowcase.tscn` for demonstrating projectile weapons. If your game uses only hitscan weapons, you can ignore these presets entirely.

**Tune for more magic feel:**
- In `Feel_MagicArcane`:
  - Slightly higher `hip_fov` (82°) for dramatic camera feel
  - Moderate `recoil_scale` and `shake_scale` for visible impact
- In MagicArcane weapon configs:
  - Lower `fire_rate` (~1.5 shots/sec) so projectiles are easy to track visually
  - Standard damage and spread values work well with projectile travel time
- In `Crosshair_MagicArcane`:
  - Slightly larger crosshair sizes
  - Cooler color palette (light blue/cyan) for magic theme

---

## 7. Making Your Own Feel Profile (Step-by-Step)

Here's a concrete step-by-step guide for creating a custom feel profile:

1. **Pick a base family.**  
   Choose which shipped profile is closest to what you want (Twitchy, WW2, Arcade, or MagicArcane if working with projectiles).

2. **Duplicate the PlayerFeelConfig.**  
   - In Godot, duplicate e.g. `config/Feel_Twitchy.tres` → `config/Feel_MyGame.tres`
   - Tweak: `move_speed`, `sprint_speed`, `crouch_speed`, `jump_force`, FOVs, recoil/shake until movement/ADS feels right

3. **Duplicate the weapon family.**  
   - Duplicate all three for that family:
     - `config/Rifle_Twitchy.tres` → `config/Rifle_MyGame.tres`
     - `config/SMG_Twitchy.tres` → `config/SMG_MyGame.tres`
     - `config/Shotgun_Twitchy.tres` → `config/Shotgun_MyGame.tres`
   - Adjust per weapon:
     - `damage`, `fire_rate`, `mag_size`, `reload_time`
     - Spread & recoil to match your desired power fantasy

4. **Duplicate the CrosshairConfig.**  
   - Duplicate `config/Crosshair_Twitchy.tres` → `config/Crosshair_MyGame.tres`
   - Tweak `min_size`, `max_size`, `spread_weight`, `movement_weight`, `smooth_speed`, and colors
   - Optionally set `style = "cross"` or any tag you like; it's a free-form string and not heavily used by the engine yet

5. **Wire it into a scene.**  
   - In your scene with `FeelPlayer`:
     - Set `feel_config` to `Feel_MyGame.tres`
   - Set your weapon's `config` to one of `Rifle_MyGame.tres`, `SMG_MyGame.tres`, or `Shotgun_MyGame.tres`
   - Set HUD's `crosshair_config` to `Crosshair_MyGame.tres`

6. **(Optional) Add it to the in-game profile switcher.**  
   - Open `scripts/demo/feel_profile_manager.gd`
   - Add a new entry to the `_profiles` array with:
     - `"name": "MyGame"`
     - `"feel": preload("res://config/Feel_MyGame.tres")`
     - `"weapon": preload("res://config/Rifle_MyGame.tres")` (demo swaps the rifle)
     - `"crosshair": preload("res://config/Crosshair_MyGame.tres")`
   - Note: the built-in switcher swaps the **active weapon's config** (rifle). You can still assign your SMG/Shotgun presets on other weapon nodes

7. **Iterate one layer at a time.**  
   - First lock in **PlayerFeelConfig** (movement + camera/FOV)
   - Then tune **WeaponConfig** recoil and spread
   - Finally, adjust **CrosshairConfig** so the HUD matches what the gun is doing

---



