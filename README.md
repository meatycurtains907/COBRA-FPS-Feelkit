# COBRA FPS Feel Kit

**Engine:** COBRA FPS Feel Kit  
**Current version:** v0.4.0 (experimental, API may change)  
**Engine target:** Godot 4.5.x  

---

## What is COBRA?

COBRA is a first-person feel kit for Godot 4: movement, recoil, ADS, sway, crosshair, and presets. It's not a full game—it's an engine slice and demo that you can drop into your own projects or use as a reference for building FPS mechanics.

COBRA provides a reusable FPS controller, weapon system, HUD, and feel presets (Twitchy / WW2 / Arcade) that you can customize or integrate into your own character controllers.

COBRA also includes an **Exploration** feel preset with slower movement and softer sprint, designed for non-combat first-person games (walking sims, narrative experiences, puzzle games, etc.). You can use FeelPlayer + this preset purely as a first-person controller even if you never enable shooting. All tuning for this preset lives in `config/Feel_Exploration.tres`, plus the bob exports on FeelPlayer if you want to adjust camera bobbing.

**Target platform:** Godot 4.5 or later.

---

## Who is this for?

- Developers building a first-person shooter who want solid movement and gunfeel without wiring everything from scratch.
- Developers prototyping fantasy or RPG-style games that need first-person magic and melee.
- Anyone who wants a Godot 4 starting point for mouse/keyboard FPS-style controllers, blocking, and simple VFX.

---

## Modules Overview

COBRA is split into a few logical pieces:

- **FPS Feel Showcase**
  - Scene: `scenes/demo/FeelShowcase.tscn`
  - Core gunfeel, movement presets (Twitchy / WW2 / Arcade / Exploration). No magic required; block is disabled by default here.
  - HUD title: "FPS Feel Showcase"

- **Magic & Melee Showcase**
  - Scene: `scenes/demo/MagicShowcase.tscn`
  - Projectile/magic weapons, melee combos, block/parry UI, and the new dummy targets.
  - HUD title: "Magic & Melee Showcase"


**If you only care about gunplay, you can ignore the MagicShowcase scene and magic preset configs entirely.**

---

## Quick Start

1. Clone this repository.
2. Open it in **Godot 4.5.x**.
3. Run `scenes/demo/FeelShowcase.tscn` to try the FPS feel presets
   (Twitchy, WW2, Arcade, Exploration).
4. Run `scenes/demo/MagicShowcase.tscn` to try the magic & melee demo
   (sword in right hand, fireball casting on RMB, block with Q).
5. When you're ready to integrate COBRA into your own project, see
   [docs/COBRA_USER_GUIDE.md](./docs/COBRA_USER_GUIDE.md).

---

### Demo Scenes

- `scenes/demo/FeelShowcase.tscn` — FPS Feel Showcase  
  Cycle feel profiles (F1) and test movement, recoil, weapon kinds,
  and the Exploration profile (no weapon, no crosshair).

- `scenes/demo/MagicShowcase.tscn` — Magic & Melee Showcase  
  sword in the right hand, fireball casting on RMB, and
  block tuneable for magic/melee.

### Utility / Test Scenes

- `scenes/TestRange.tscn` — Simple test range used for quick target testing.

- `scenes/demo/WW2Bootcamp.tscn` — WW2-flavored internal test range used
  during development. This scene is **not** part of the public API and may
  change or be removed in the future.

> **Note:** Officially, COBRA ships as an engine plus these two demo scenes
> (`FeelShowcase` and `MagicShowcase`). Utility scenes like `TestRange`
> and `WW2Bootcamp` are internal examples and are not considered stable API.

---

## Input Map Requirements

COBRA expects these input actions to be configured in your Godot project (Project Settings → Input Map).

**Required for core feel:**

- `move_forward`, `move_backward`, `move_left`, `move_right`
- `jump`, `sprint`, `crouch`
- `fire`, `reload`, `aim`, `melee`

**Optional (advanced features):**

- `interact` (for armory spots / picking configs)
- `switch_profile` (feel profile manager: Twitchy/WW2/Arcade)
- `reset_bootcamp`, `skip_bootcamp` (bootcamp / range utilities)

For complete details, see [docs/integration-modes.md](docs/integration-modes.md).

---

## Documentation

- [User Guide](./docs/COBRA_USER_GUIDE.md) — installation, input mappings, scene overview, and how to plug COBRA into your own project.

- [Integration Modes](./docs/integration-modes.md) — ways to consume COBRA: reference scenes, submodule, or copying select scripts/resources.

- [Feel Profiles](./docs/feel_profiles.md) — details on Twitchy, WW2, Arcade, Exploration, and how to add your own profiles.

For detailed system documentation, see also:
- **Weapons & configs** → [docs/weapon-system-overview.md](docs/weapon-system-overview.md)
- **Feel & presets** → [docs/weapon-feel-presets.md](docs/weapon-feel-presets.md)

---

## Folder Structure

```
/scenes
  FeelShowcase.tscn      # main demo for feel profiles (in demo/ subfolder)
  TestRange.tscn         # minimal shooting range
  FeelPlayer.tscn        # FPS player controller
  HUD.tscn               # crosshair, hitmarker, ammo, stats
  /demo                  # demo scenes (FeelShowcase, WW2Bootcamp)
  /props                 # reusable prop scenes
  /vfx                   # visual effects scenes
  /weapons               # weapon model scenes

/scripts
  /player                # FeelPlayer, WeaponRig, RecoilController
  /weapons               # WeaponBase, WeaponConfig, Damageable, Melee, etc.
  /hud                   # HUD & crosshair logic
  /demo                  # demo scene scripts

/config
  *.tres                 # PlayerFeelConfig, WeaponConfig presets, CrosshairConfig presets
                          (Feel_Twitchy.tres, Feel_WW2.tres, Feel_Arcade.tres,
                           Rifle_*.tres, SMG_*.tres, Shotgun_*.tres,
                           Crosshair_*.tres, MeleeConfig.tres)

/docs
  integration-modes.md
  weapon-system-overview.md
  weapon-feel-presets.md
  architecture.md
```

---

## Using COBRA in Your Own Godot Project

### Option A: Clone as a Standalone Sandbox

Use this repo as a standalone sandbox to test weapon feel and learn the system. Run `scenes/demo/FeelShowcase.tscn` and experiment with configs.

### Option B: Embed into Existing Project

To use COBRA in your own project:

1. **Copy files:**
   - Copy `/scripts` folder (player, weapons, hud subfolders).
   - Copy `/config` folder (all `.tres` preset files).
   - Copy relevant scenes:
     - `scenes/FeelPlayer.tscn` (FPS player controller).
     - `scenes/HUD.tscn` (HUD with crosshair, hitmarkers).
     - Optionally: `scenes/TestRange.tscn` or `scenes/demo/FeelShowcase.tscn` as reference.

2. **Configure Input Map:**
   - Ensure your Godot project has all required input actions (see [Input Map Requirements](#input-map-requirements) above).
   - Link to [docs/integration-modes.md](docs/integration-modes.md) for full details.

3. **Choose integration mode:**
   - **Mode A:** Use `FeelPlayer.tscn` as your main player (see [docs/integration-modes.md](docs/integration-modes.md#2-integration-mode-a--drop-in-feelplayer)).
   - **Mode B:** Wire `WeaponRig` + `WeaponBase` into your own character controller (see [docs/integration-modes.md](docs/integration-modes.md#3-integration-mode-b--use-cobra-weapons-in-your-own-player)).

4. **Optional:** Copy configs from `/config` or create new presets based on them (Twitchy / WW2 / Arcade). For projectile/magic weapons, see `MagicShowcase.tscn` and the MagicArcane presets (optional).

---

## Assets & Licensing

### Audio Assets

All included **sound effects** are sourced from **Pixabay** under their free license and are intended as **placeholder/prototype** assets. The audio files are located in the `Sounds/` folder and include:

- **Weapon fire/reload sounds** — Used by all weapon configs (rifles, SMGs, shotguns)
- **Melee (sword) SFX** — Used by the Magic & Melee Showcase (sword swings and impacts)
- **Magic fireball sounds** — Cast and impact sounds for projectile weapons

Pixabay does not require attribution, but we document this for transparency. Users are **encouraged to replace these SFX** with their own production assets for final games. These placeholder sounds are safe for prototyping and commercial use per Pixabay's license terms.

**Note:** On the **FPS Feel Showcase**, the default melee SFX is a Pixabay "melee attack with voice" clip (assigned via `MeleeConfig.tres`). On the **Magic & Melee Showcase**, that clip is not used; sword swings and impacts use their own sword-specific SFX. Developers can swap out any of these audio files with their own assets as needed.

### Visual Assets

All 3D models, textures, and visual effects are placeholder/greybox assets created for the demo. Swap these with your own art as needed.

---

## Known Limitations & Next Steps

- **No AI, enemies, or full gameplay loops** — COBRA focuses on **first-person feel**, not complete game logic.

- **No networking or multiplayer** — all examples are single-player/local only.

- **Assets are placeholder / greybox** — demo geometry, dummies, sword, and fireball are intentionally simple so you can swap in your own art.

- **Melee swings are procedural, not animation-driven** — ideal for prototyping, but you'll likely pair this with your own animations later.

- **Magic is a single fireball archetype** — you're expected to duplicate/extend the projectile and configs for different spells.

- **`WW2Bootcamp.tscn` and similar internal scenes are dev examples** — not documented, not stable, and may change or be removed.

---

## License

COBRA FPS Feel Kit is released under the MIT License.  
See the [LICENSE](./LICENSE) file for full details.

---
