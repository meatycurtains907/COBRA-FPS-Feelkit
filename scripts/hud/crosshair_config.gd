extends Resource
class_name CrosshairConfig

@export_group("Size & Spread")
@export var min_size: float = 6.0          # maps to crosshair_min_size
@export var max_size: float = 18.0         # maps to crosshair_max_size
@export var spread_weight: float = 0.7     # maps to crosshair_spread_weight
@export var movement_weight: float = 0.3   # maps to crosshair_move_weight
@export var smooth_speed: float = 12.0     # maps to crosshair_smooth_speed

@export_group("Colors")
@export var base_color: Color = Color(1, 1, 1, 1)
@export var hit_color: Color = Color(1, 1, 1, 1)
@export var kill_color: Color = Color(1, 0.25, 0.25, 1)

@export_group("Behavior")
@export var show_hitmarker: bool = true
@export var style: String = "cross"  # reserved for future variants

