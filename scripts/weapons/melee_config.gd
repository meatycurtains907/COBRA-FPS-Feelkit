extends Resource

class_name MeleeConfig



@export var display_name: String = "Sword"

@export var damage: float = 40.0

@export var melee_range: float = 2.0

@export var swing_time: float = 0.2

@export var recovery_time: float = 0.4

@export var hitbox_radius: float = 0.75



# Optional SFX/VFX

@export var swing_sfx: AudioStream

@export var hit_sfx: AudioStream

@export var hit_effect_scene: PackedScene
