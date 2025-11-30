# COBRA FPS Feel Kit — User Guide

- [Getting Started](#getting-started)
- [Demo Scenes](#demo-scenes)
- [Input & Controls](#input--controls)
- [Feel Profiles](#feel-profiles)
- [Integrating Into Your Game](#integrating-into-your-game)
- [Magic & Melee Showcase](#magic--melee-showcase)
- [Known Limitations](#known-limitations)

---

> **Note:** This guide is currently being developed. See README.md for basic information.

## Demo Scenes & Modes

### FeelShowcase (FPS feel presets)

**Title shown in HUD:** "FPS Feel Showcase" (set by FeelShowcase script at runtime)

**Note:** The base HUD scene's default title is "COBRA FPS Feel Kit". Individual demo scenes (like FeelShowcase and Magic & Melee Showcase) override this title at runtime to show their specific mode names.

**Mode label:** "Mode: Gunplay & Movement" (displayed in HUD)

### Magic & Melee Showcase

**Title shown in HUD:** "Magic & Melee Showcase" (set at runtime by the scene script)

**Mode label:** "Mode: Magic / Melee" (displayed in HUD)

---

## Known Limitations

COBRA FPS Feel Kit focuses on first-person feel mechanics and is not a complete game engine. Key limitations include:

- No AI, enemies, or full gameplay loops
- No networking or multiplayer support
- Assets are placeholder/greybox (intentionally simple for easy replacement)
- Melee swings are procedural, not animation-driven
- Magic system includes a single fireball archetype (extend as needed)
- Internal dev scenes (like `WW2Bootcamp.tscn`) are not stable API

### Audio Assets

COBRA ships with placeholder sound effects from **Pixabay** located in `Sounds/`. These free-license assets are safe for prototyping and commercial use (per Pixabay license), but you are **recommended to replace them** with your own production audio assets for final games.

**Audio usage by showcase:**
- **FPS Feel Showcase** — Uses a default melee attack sound with voice/vocalization from Pixabay (assigned via `MeleeConfig.tres`). The MeleeWeapon instance does not override SFX exports, so it uses the config defaults.
- **Magic & Melee Showcase** — Uses sword-specific swing and impact sounds. The MeleeWeapon instance overrides the default SFX exports with sword clips (`sword-slice-393847.mp3`, `sword-clashhit-393837.mp3`, `sword-blade-slicing-flesh-352708.mp3`) and does not use the voice-y melee clip.

For full details, see the [Known Limitations section](../README.md#known-limitations--next-steps) and [Assets & Licensing section](../README.md#assets--licensing) in the README.

