extends Resource

class_name WeaponConfig



@export var display_name: String = "Rifle"



enum FireMode { SEMI_AUTO, FULL_AUTO, BURST }

@export var fire_mode: FireMode = FireMode.FULL_AUTO



# Core stats

@export_range(0, 1000) var damage: float = 25.0

@export_range(0.1, 60.0) var fire_rate: float = 10.0 # shots per second

@export_range(1, 200) var mag_size: int = 30

@export_range(0.1, 10.0) var reload_time: float = 2.0

@export var uses_ammo: bool = true



# Accuracy

@export_range(0.0, 10.0) var hip_spread: float = 2.0

@export_range(0.0, 10.0) var ads_spread: float = 0.5

@export_range(0.0, 5.0) var spread_increase_per_shot: float = 0.2

@export_range(0.0, 20.0) var spread_decay_rate: float = 4.0

# Pellet support (for shotguns)

@export_range(1, 20) var pellet_count: int = 1

@export_range(0.1, 5.0) var pellet_spread_scale: float = 1.0



# Recoil pattern: x = yaw offset, y = pitch offset (degrees-ish)

@export var recoil_pattern: Array[Vector2] = [

    Vector2(0.0, -1.5),

    Vector2(0.2, -1.2),

    Vector2(-0.15, -1.0),

    Vector2(0.0, -0.9),

]

@export_range(0.1, 20.0) var recoil_reset_speed: float = 8.0



# Assets (can leave null for now, this is v0.1)

@export var model_scene: PackedScene

@export var muzzle_flash_scene: PackedScene

@export var impact_effect_scene: PackedScene



@export var fire_sfx: AudioStream

@export var reload_sfx: AudioStream

@export var empty_sfx: AudioStream
