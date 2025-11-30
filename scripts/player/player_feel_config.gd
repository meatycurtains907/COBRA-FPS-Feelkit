extends Resource

class_name PlayerFeelConfig



@export_group("Movement")

@export var move_speed: float = 5.0

@export var sprint_speed: float = 8.0

@export var crouch_speed: float = 3.0



@export_group("Jump")

@export var jump_force: float = 4.5



@export_group("Look")

@export var mouse_sensitivity: float = 0.12

@export var ads_sensitivity_multiplier: float = 0.7



@export_group("FOV / ADS")

@export var hip_fov: float = 75.0

@export var ads_fov: float = 55.0

@export var ads_fov_lerp_speed: float = 10.0



@export_group("Recoil / Shake Scales")

@export var recoil_scale: float = 1.0

@export var shake_scale: float = 1.0

