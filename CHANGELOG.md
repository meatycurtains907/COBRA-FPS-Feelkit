# Changelog

All notable changes to COBRA FPS Feel Kit will be documented in this file.

---

## v0.4.0 — Initial Public Feel Kit

**Release Date:** 2025

Packaged COBRA as a standalone FPS feel kit for Godot 4.

### Added

- **FeelShowcase demo scene** (`scenes/demo/FeelShowcase.tscn`): Primary demo showcasing feel profiles (Twitchy / WW2 / Arcade), FeelPlayer, HUD, and training targets.

- **TestRange reference scene** (`scenes/TestRange.tscn`): Minimal shooting range for quick testing.

- **PlayerFeelConfig presets**:
  - `Feel_Twitchy.tres` — Fast, responsive arena-style feel.
  - `Feel_WW2.tres` — Heavy, deliberate WW2-style feel.
  - `Feel_Arcade.tres` — Balanced arcade-style feel.

- **WeaponConfig presets** (Rifle, SMG, Shotgun × Twitchy/WW2/Arcade):
  - Multiple weapon types with tuned damage, spread, recoil, and fire rates.
  - Each preset matched to corresponding feel profile.

- **CrosshairConfig presets** (`Crosshair_Twitchy.tres`, `Crosshair_WW2.tres`, `Crosshair_Arcade.tres`):
  - Dynamic crosshair styles tuned for each feel profile.

- **Integration documentation**:
  - `docs/integration-modes.md` — Complete guide for integrating COBRA into your project (Mode A: Drop-in FeelPlayer, Mode B: Use WeaponRig in your own character).
  - `docs/weapon-system-overview.md` — Detailed weapon system documentation.
  - `docs/weapon-feel-presets.md` — Feel preset tuning guide.

- **Enemies & Damageable integration**:
  - `Damageable` script for custom enemies and targets.
  - Signal pipeline documentation (WeaponBase → Damageable → HUD).

### Core Systems

- **FeelPlayer** (`scenes/FeelPlayer.tscn`): First-person controller with movement, camera, ADS, recoil, and head bob.

- **WeaponRig** (`scripts/player/weapon_rig.gd`): Viewmodel system with ADS state and weapon sway.

- **WeaponBase** (`scripts/weapons/weapon_base.gd`): Hitscan weapon system with spread, recoil patterns, ammo, and damage.

- **RecoilController** (`scripts/player/recoil_controller.gd`): Camera recoil and optional shake.

- **HUD** (`scenes/HUD.tscn`): Dynamic crosshair, hitmarkers, kill markers, ammo display, and range stats.

- **MeleeWeapon** (`scripts/weapons/melee_weapon.gd`): Melee system using same Damageable pipeline.

---





