# Cobra Weapon Feel Presets

> File: `docs/weapon-feel-presets.md`

This document is for developers who want to **tune how weapons feel** in Cobra without digging through all the code.

Cobra splits "feel" across a few systems:

- **WeaponConfig** – damage, mag size, spread, recoil pattern, fire rate, SFX/VFX.

- **WeaponBase** – interprets WeaponConfig and actually fires the shot.

- **FeelPlayer / RecoilPivot** – camera movement, recoil application, ADS FOV/sensitivity.

- **WeaponRig** – viewmodel sway / idle motion.

- **HUD** – crosshair, hitmarker, stats feedback.

You can mix and match these to create anything from a slow WW2 bolt rifle to a twitchy arena SMG.

The main places to test weapon feel are:

- `scenes/TestRange.tscn`

- `scenes/demo/WW2Bootcamp.tscn` → **Range** area inside the bootcamp scene

---

## 1. WeaponConfig: Field-to-Feel Cheatsheet

`WeaponConfig` lives in `scripts/weapons/weapon_config.gd`. Exact field names can evolve, but this is the intent of the default Cobra config.

### Core combat stats

- **`display_name: String`**  
  Purely UI, but helps sanity. Use short, descriptive names:
  - `"WW2 Bolt Rifle"`, `"Twitch SMG"`, `"Arena Shotgun"` etc.

- **`mag_size: int`**  
  How many shots before needing a reload.
  - Low (4–8): Feels deliberate/punishing, better for high-damage weapons.
  - Medium (20–30): Rifles and SMGs.
  - High (40–60+): Spray/fun weapons.

- **`damage: float`**  
  How much health is removed per hit.
  - For the default test dummies, 100 is a simple baseline.
  - 50–60 damage → 2 body shots to kill.
  - 20–30 damage → 4–5 bullets to kill.

- **`fire_rate: float`** (shots/second)  
  Interval between shots is `1.0 / fire_rate`.
  - 1.0 → 1 shot per second (slow, bolt/DMR).
  - 4–6 → assault rifle feel.
  - 8–12 → SMG / bullet hose.
  - <1 → heavy sniper / big shotgun.

- **`reload_time: float`** (seconds)  
  Longer reloads make mag size & accuracy more meaningful.
  - 1.3–1.8 → snappy.
  - 2.0–2.5 → "normal rifle".
  - 2.8–3.2 → chunky bolt/shotgun.

### Accuracy & spread

- **`hip_spread: float`**  
  Base inaccuracy when firing from the hip.
  - 0.5–1.5 → pretty tight hipfire (more arcade).
  - 2–3 → medium.
  - 4–7 → shotgun / SMG spraying.

- **`ads_spread: float`**  
  Base inaccuracy while aiming down sights.
  - 0.1–0.4 → precision weapons.
  - 0.5–1.5 → normal rifles.
  - 2–3 → "ADS still sloppy" (shotguns, super-cheap SMGs).

- **`spread_increase_per_shot: float`**  
  How quickly the weapon blooms if you keep firing.
  - Very low → tap-friendly, good for DMRs.
  - Medium → controlled bursts feel optimal.
  - High → full auto quickly becomes inaccurate.

- **`spread_decay_rate: float`**  
  How fast spread resets when you stop firing.
  - Low decay → gun stays "hot" longer.
  - High decay → short bursts reset quickly.

### Recoil & kick

Recoil in Cobra is driven by:

- `WeaponConfig.recoil_pattern: Array[Vector2]`
- `RecoilController` on the camera (`scripts/player/recoil_controller.gd`)

Pattern semantics:

- Each `Vector2` is usually `(yaw, pitch)` in **degrees**.
- **`x`** = horizontal (yaw).
- **`y`** = vertical (pitch).
  - Negative pitch kicks the view *up* (our convention).

You'll also see:

- **`recoil_reset_speed: float` (on WeaponConfig)**  
  > **Note:** This is currently **not wired** into the `RecoilController`.  
  > RecoilController has its own `reset_speed` property that controls how fast recoil decays over time.  
  > `recoil_reset_speed` exists for potential future use / more per-weapon control.

- **`RecoilController.reset_speed: float`**  
  How quickly recoil returns to neutral (per second).

**Rule of thumb:**

- Vertical recoil = how much the gun climbs.
- Horizontal recoil = how "wobbly" it feels left/right.
- Pattern length = how long a spray has personality before repeating.

### Fire mode

- **`fire_mode: int` enum**  
  e.g. `SEMI_AUTO`, `FULL_AUTO`, `BURST`.

Right now this is mostly **descriptive**. Actual fire behavior is still driven by input and how `WeaponBase` is called. You can still set it correctly for documentation / future logic.

### Audio & VFX

- **`fire_sfx`**  
  Biggest "feel" lever after recoil. Louder + sharper transient = more powerful.

- **`reload_sfx` / `empty_sfx`**  
  Reinforces weapon identity (hefty bolt, clacky SMG, chunky shotgun).

- **`muzzle_flash_scene`**  
  Short flash at the muzzle. Bigger/longer flash looks more powerful.

- **`impact_effect_scene`**  
  Spawned at hit location. More debris = more impact.

---

## 2. Tuning Playbook: How To Build a New Weapon

A simple way to approach tuning:

1. **Pick an archetype.**  
   e.g. "tactical rifle", "twitch SMG", "WW2 shotgun".

2. **Decide kill profile.**  
   - "2–3 bullets to kill" vs "4–6 to kill".
   - That sets your **damage** range.

3. **Decide tempo.**
   - Tap-firing? → low fire_rate.
   - Spray? → high fire_rate + more spread growth.

4. **Decide risk.**
   - Low mag + long reload → punishing but rewarding.
   - Big mag + quick reload → forgiving / arcade.

5. **Shape accuracy.**
   - Tight `ads_spread` if you want rewarding aim.
   - High `hip_spread` + high `spread_increase_per_shot` if you want tap/burst mastery.

6. **Dial recoil.**
   - Big vertical with low horizontal = controllable but punchy.
   - More horizontal wobble makes it feel wild, especially for SMGs.

7. **Sell it with feedback.**
   - Bigger sound + flash for harder hitters.
   - Softer sound + shorter flash for sidearms / SMGs.

Test in:

- `scenes/TestRange.tscn` (plain range)

- `scenes/demo/WW2Bootcamp.tscn` → **Range** area (with movement course, scoring, etc.)

Try:

- Tap fire, burst, and mag-dump.

- Hipfire vs ADS at a couple distances.

- Only tweak 1–2 knobs at a time.

---

## 3. Example Presets (Number Ranges)

These are **guidelines**, not strict rules. All numbers are "reasonable starting values" for a 100 HP dummy.

### 3.1 WW2 Bolt Rifle

**Intent:** Heavy, reliable, best at mid-range.  
Config file: `config/RifleConfig.tres`

Suggested ranges:

- `display_name = "WW2 Bolt Rifle"`
- `mag_size = 5`
- `fire_rate = 1.0` (1 shot / sec)
- `reload_time = 2.8`
- `damage = 55–65`
- `hip_spread = 1.5–2.0`
- `ads_spread = 0.15–0.3`
- `spread_increase_per_shot = low` (e.g. 0.05–0.1)
- `spread_decay_rate = medium–high`
- `recoil_pattern`:
  - Mostly vertical, small horizontal.
- SFX/VFX:
  - Loud, sharp rifle crack, chunky reload.

**Feel check:**

- 2 body shots should kill a dummy.
- ADS shots should feel very consistent.
- Hipfire usable but not great at range.

---

### 3.2 WW2 SMG

**Intent:** Close-to-mid-range bullet hose.  
Config file: `config/SMGConfig.tres`

Suggested ranges:

- `display_name = "WW2 SMG"`
- `mag_size = 30`
- `fire_rate = 10.0` (0.1s between shots)
- `reload_time = 2.0`
- `damage = 20–25`
- `hip_spread = 3.0–4.0`
- `ads_spread = 1.0–1.5`
- `spread_increase_per_shot = medium–high`
- `spread_decay_rate = medium`
- `recoil_pattern`:
  - More horizontal wobble, smaller vertical per bullet.
- SFX/VFX:
  - Lighter automatic sound, more "rattle" than "boom".

**Feel check:**

- Absolutely shreds at close range.
- Past mid-range, recoil + spread should make spraying inefficient.
- Controlled bursts in ADS should be viable.

---

### 3.3 WW2 Shotgun (Advanced)

**Intent:** Brutal up close, weak at range; "harder" weapon.  
Config file: `config/ShotgunConfig.tres`

Suggested ranges:

- `display_name = "WW2 Shotgun (Advanced)"`
- `mag_size = 6–8`
- `fire_rate = 1.0–1.25`
- `reload_time = 3.0`
- `damage`:
  - If single hitscan: 80–110 (1 shot kill up close, falloff via spread).
- `hip_spread = 5.0–7.0`
- `ads_spread = 2.5–3.5`
- `spread_increase_per_shot = medium–high`
- `spread_decay_rate = medium`
- `recoil_pattern`:
  - One of the strongest kicks; clear "thump".
- SFX/VFX:
  - Deep boom, big muzzle flash, chunky reload.

**Feel check:**

- Inside "shotgun distance" it should feel unfairly strong.
- Past that, spread makes it unreliable quickly.
- Recoil should demand some recovery time between shots.

---

### 3.4 "Twitch Rifle" (CSGO-ish)

**Intent:** Fast-tempo, low TTK rifle for twitchy modes.

Use a duplicate config (e.g. `TwitchRifleConfig.tres`) so you don't break WW2 presets.

Suggested ranges:

- `display_name = "Twitch Rifle"`
- `mag_size = 30`
- `fire_rate = 7–9` (rifle-fast, not SMG-fast)
- `reload_time = 2.0–2.3`
- `damage = 30–35` (3–4 shots to kill)
- `hip_spread = 2.0–2.5`
- `ads_spread = 0.4–0.7`
- `spread_increase_per_shot = medium`
- `spread_decay_rate = high` (short bursts reset quickly)
- `recoil_pattern`:
  - Mostly vertical, consistent pattern so skilled players can compensate.
- SFX/VFX:
  - Snappy but not as heavy as the bolt rifle.

**Feel check:**

- Aiming skill is highly rewarded; accurate ADS fire melts targets fast.
- Hipfire is okay but not great at range.
- Spraying should be viable up close but not at long range.

---

### 3.5 "Fun Arena SMG"

**Intent:** Movement shooter / horde mode SMG, very forgiving.

Config idea (another duplicate SMG config):

- `display_name = "Arena SMG"`
- `mag_size = 40–50`
- `fire_rate = 12–14` (very high)
- `reload_time = 1.5–1.8`
- `damage = 15–20`
- `hip_spread = 2.5–3.0` (not crazy wide; more arcade)
- `ads_spread = 0.8–1.2`
- `spread_increase_per_shot = low–medium`
- `spread_decay_rate = high`
- `recoil_pattern`:
  - Low, mostly aesthetic; meant to be fun/easy.

**Feel check:**

- You can hard-spray and run without being punished much.
- Accuracy still matters at range, but up close it's a mowing machine.

---

## 3.6 Preset Families

Cobra ships with three preset families that showcase different feel archetypes. Each family includes Rifle, SMG, and Shotgun variants:

### Twitchy Presets
**Files:** `Rifle_Twitchy.tres`, `SMG_Twitchy.tres`, `Shotgun_Twitchy.tres`

**Intent:** High skill ceiling, sharp recoil, fast recovery. Designed for competitive/twitch shooter gameplay.

- **Twitch Rifle:** Faster fire rate, tighter ADS spread, sharper recoil pattern, quick spread decay
- **Twitch SMG:** High RPM, very tight ADS, aggressive but controllable hipfire, fast recovery
- **Twitch Shotgun:** Quick follow-up shots, narrower spread cone, strong vertical kick with fast reset

**Use case:** TestRange defaults to `Rifle_Twitchy.tres` for immediate "twitchy rifle lab" feel.

### WW2 Presets
**Files:** `Rifle_WW2.tres`, `SMG_WW2.tres`, `Shotgun_WW2.tres`

**Intent:** Grounded, "historical" pacing. Authentic WW2 weapon feel with deliberate, weighty handling.

- **WW2 Bolt Rifle:** Slow fire rate (1.0), small mag (5), high damage, tight ADS, noticeable recoil
- **WW2 SMG:** Fast fire rate (10.0), moderate damage, wide spread, horizontal recoil wobble
- **WW2 Trench Shotgun:** Slow fire rate, high close-range damage, very wide spread, strong vertical kick

**Use case:** WW2Bootcamp Armory uses these presets exclusively to maintain thematic consistency.

### Arcade Presets
**Files:** `Rifle_Arcade.tres`, `SMG_Arcade.tres`, `Shotgun_Arcade.tres`

**Intent:** Forgiving, fun, power fantasy. Easy to use with generous stats and low recoil.

- **Arcade Rifle:** Larger mag, low recoil, forgiving hipfire, very fast spread decay
- **Arcade SMG:** Big magazines (40), mild recoil, generous spread, very tight ADS
- **Arcade Shotgun:** Larger mag, slightly higher damage, forgiving spread, fast recovery

**Use case:** Great for horde modes, casual gameplay, or when you want players to feel powerful.

### Original Configs
**Files:** `RifleConfig.tres`, `SMGConfig.tres`, `ShotgunConfig.tres`

These remain as reference WW2 baselines and for backwards compatibility. They match the WW2 preset tuning but use generic display names.

---

## 3.7 WW2 Bootcamp Profile vs Twitchy Profile (Quick Notes)

The WW2 and Twitchy profiles represent two distinct feel archetypes in Cobra. Here's a quick comparison to understand their design intent:

### PlayerFeelConfig Differences

**WW2 Profile:**
- Lower move/sprint speed (4.3 / 6.8 vs default 5.0 / 8.0)
- Slightly narrower hip FOV (73.0 vs 75.0) for a more "tunnel vision" feel
- Slower ADS zoom (8.0 lerp speed vs 10.0+) and lower ADS sensitivity multiplier (0.65 vs 0.7+)
- Higher recoil_scale (1.25) and shake_scale (1.35) for heavier weapon feedback
- Feels more "gear-laden" and committed to each action

**Twitchy Profile:**
- Faster movement speeds for quick repositioning
- Wider FOV for better spatial awareness
- Snappier ADS zoom and higher sensitivity for quick target acquisition
- Lower recoil/shake scales for more "esportsy" precision feel
- Designed for high-skill competitive gameplay

### Weapon Preset Differences

**Rifle_WW2:**
- Slower rate of fire (0.9 shots/sec vs Twitchy ~7-9)
- Heavier recoil (notable upward kick: -4.5 to -5.0 pitch)
- Tighter ADS spread (0.6) but wider hip spread (3.5) - rewards careful aiming
- High damage (65) for 2-3 shot kills
- Small mag (5) encourages deliberate shots

**Rifle_Twitchy:**
- Faster fire rate for sustained combat
- Sharper but more predictable recoil pattern
- Tighter ADS spread with better hipfire for mobility
- Lower damage but faster TTK through rapid accurate fire

**SMG_WW2:**
- High rate of fire (9.5) but wilder hip spread (4.5)
- Noticeable horizontal recoil wobble for close-range chaos
- Controllable but not laser-accurate at mid-range (1.2 ADS spread)
- Fast spread decay (7.0) allows burst control

**SMG_Twitchy:**
- Even higher RPM with tighter spread control
- More vertical climb, less horizontal wobble
- Better mid-range accuracy for mobile combat

**Shotgun_WW2:**
- Devastating at close range (85 damage, 7.0 hip spread)
- Heavy vertical kick (-6.5 to -7.0 pitch)
- Almost no mid-range utility (4.0 ADS spread still wide)
- Clear close-range monster identity

**Shotgun_Twitchy:**
- Faster follow-up shots
- Narrower spread for better range utility
- Strong but more manageable recoil

### Crosshair Differences

**Crosshair_WW2:**
- Bigger base size (10.0 min, 26.0 max)
- Less snappy movement (10.0 smooth speed vs Twitchy ~12-15)
- More "military training range" feel with slower settle
- Muted colors (khaki base) for authenticity

**Crosshair_Twitchy:**
- Smaller, more responsive crosshair
- Faster smooth speed for quick feedback
- More reactive to spread/movement changes
- Brighter colors for high-visibility gameplay

**Design Intent:**
- WW2 = Deliberate, weighty, authentic "soldier" feel
- Twitchy = Responsive, precise, competitive "esports" feel

---

## 4. Crosshair & HUD Interaction

The HUD's dynamic crosshair reads **current spread and movement** to scale its size:

- Uses `get_spread_ratio()` from the weapon.
- Uses `_get_movement_factor()` based on movement/sprint input.
- Scales between `crosshair_min_size` and `crosshair_max_size`.
- Blends spread vs movement using:
  - `crosshair_spread_weight`
  - `crosshair_move_weight`

If a weapon feels:

- **Too accurate visually**:
  - Increase `hip_spread` / `ads_spread` **or**
  - Increase `crosshair_spread_weight` or `crosshair_max_size`.

- **Too inaccurate visually** but gameplay feels right:
  - Reduce crosshair scaling first (weights/max size) before messing with spread.

When you add a new preset, fire at a wall and compare:

- Where bullets land.
- How the crosshair animates (idle, walking, ADS, firing).

Adjust either **spread** or **HUD weights** so players aren't misled.

---

## 5. Where To Tune What (Quick Map)

- **Raw power & pacing**
  - `WeaponConfig`: `damage`, `fire_rate`, `mag_size`, `reload_time`.

- **Aim skill vs spray**
  - `WeaponConfig`: `hip_spread`, `ads_spread`, `spread_increase_per_shot`, `spread_decay_rate`.

- **Visual kick**
  - `WeaponConfig`: `recoil_pattern`.
  - `RecoilController`: `reset_speed`, max recoil, shake options.

- **Snappiness / weight of movement**
  - `FeelPlayer`: `move_speed`, `sprint_speed`, `crouch_speed`, head bob settings.

- **ADS feel**
  - `FeelPlayer`: `hip_fov`, `ads_fov`, `ads_fov_lerp_speed`, `ads_sensitivity_multiplier`.
  - `WeaponConfig`: ADS spread values.

- **Juice / feedback**
  - `WeaponConfig`: SFX + VFX fields.
  - `HUD`: hitmarkers, kill markers, range stats.

---

## 6. Workflow Suggestions

For other developers (or future you):

1. **Duplicate an existing config** that's close to what you want.

2. Rename it (e.g. `SciFiRifleConfig.tres`) and adjust the fields using the ranges above.

3. Hook it into:
   - An **ArmoryWeaponSpot** (for interactive swapping), or
   - Directly assign it to the Weapon in `scenes/FeelPlayer.tscn` for a default loadout.

4. Test in both:
   - `TestRange.tscn` (plain),
   - `WW2Bootcamp.tscn` → Range area (with movement & scoring).

5. If it doesn't feel right:
   - Start with **fire_rate + damage**.
   - Then **spread**.
   - Then **recoil**.
   - Save SFX/VFX tweaks for last.

Once you like the result, treat that config as a **preset template** for that archetype and branch new weapons off it.

---

