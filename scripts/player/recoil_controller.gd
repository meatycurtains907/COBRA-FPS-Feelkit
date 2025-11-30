extends Node3D

class_name RecoilController

func get_current_offset() -> Vector2:
	# _current_recoil is the internal offset we apply each frame.
	return _current_recoil


@export var reset_speed: float = 10.0

@export var max_recoil: Vector2 = Vector2(10.0, 15.0)

@export var shake_enabled: bool = true

@export var shake_intensity_per_recoil: float = 0.002

@export var shake_decay_speed: float = 8.0

@export var recoil_scale: float = 1.0

@export var shake_scale: float = 1.0



var _current_recoil: Vector2 = Vector2.ZERO

var _target_recoil: Vector2 = Vector2.ZERO

var _default_position: Vector3

var _shake_amount: float = 0.0

var _shake_offset: Vector3 = Vector3.ZERO



func _ready() -> void:

	_default_position = position

	randomize()



func apply_recoil(offset: Vector2, scale_multiplier: float = 1.0) -> void:

	# Scale the incoming offset for both rotation and shake

	var scaled_offset := offset * recoil_scale



	# Add scaled offset to target recoil (still apply scale_multiplier for per-shot/weapon scaling)

	_target_recoil += scaled_offset * scale_multiplier

	# Clamp target recoil within max bounds

	_target_recoil.x = clamp(_target_recoil.x, -max_recoil.x, max_recoil.x)

	_target_recoil.y = clamp(_target_recoil.y, -max_recoil.y, max_recoil.y)

	if shake_enabled:

		var add_amount: float = scaled_offset.length() * shake_intensity_per_recoil * scale_multiplier * shake_scale

		_shake_amount += add_amount

		if _shake_amount > 0.1:

			_shake_amount = 0.1



func _process(delta: float) -> void:

	# Store previous recoil to compute delta

	var previous_recoil := _current_recoil

	# Smoothly lerp current recoil toward target recoil

	var lerp_factor := reset_speed * delta

	_current_recoil = _current_recoil.lerp(_target_recoil, lerp_factor)

	# Smoothly lerp target recoil toward zero (decay)

	_target_recoil = _target_recoil.lerp(Vector2.ZERO, lerp_factor)

	# Compute incremental change

	var delta_recoil := _current_recoil - previous_recoil

	# Apply incremental rotation changes

	# Pitch (vertical): negative rotation kicks view up

	rotate_x(-deg_to_rad(delta_recoil.y))

	# Yaw (horizontal): positive rotation kicks view right

	rotate_y(deg_to_rad(delta_recoil.x))

	# Screen shake: decay and apply small random offset

	var st: float = clamp(shake_decay_speed * delta, 0.0, 1.0)

	_shake_amount = lerp(_shake_amount, 0.0, st)

	if _shake_amount < 0.001:

		_shake_offset = Vector3.ZERO

	else:

		var sx: float = (randf() * 2.0 - 1.0) * _shake_amount

		var sy: float = (randf() * 2.0 - 1.0) * _shake_amount

		_shake_offset = Vector3(sx, sy, 0.0)

	position = _default_position + _shake_offset
