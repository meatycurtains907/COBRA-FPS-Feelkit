extends Node3D

class_name WeaponRig



@export var active_weapon: WeaponBase



@export var position_sway_amount: float = 0.002

@export var position_sway_max: Vector2 = Vector2(0.06, 0.04)



@export var rotation_sway_amount: float = 0.04

@export var rotation_sway_max: Vector2 = Vector2(3.0, 2.0)



@export var idle_bob_amount: float = 0.015

@export var idle_bob_speed: float = 1.5

@export var moving_bob_multiplier: float = 1.5



@export var sway_smooth_speed: float = 10.0



var _default_position: Vector3

var _default_rotation_degrees: Vector3



var _pos_offset: Vector3 = Vector3.ZERO

var _rot_offset_degrees: Vector3 = Vector3.ZERO



var _pos_offset_target: Vector3 = Vector3.ZERO

var _rot_offset_target_degrees: Vector3 = Vector3.ZERO



var _bob_time: float = 0.0



func _ready() -> void:

	# If active_weapon is a NodePath, resolve it

	if active_weapon == null:

		var weapon_node: Node = get_node_or_null("Weapon")

		var weapon_path: WeaponBase = weapon_node as WeaponBase

		if weapon_path != null:

			active_weapon = weapon_path

		else:

			push_warning("WeaponRig has no active_weapon assigned.")

	# Cache defaults for viewmodel offsets

	_default_position = position

	_default_rotation_degrees = rotation_degrees

	set_process(true)



func fire() -> void:

	if active_weapon:

		active_weapon.try_fire()



func reload() -> void:

	if active_weapon:

		active_weapon.try_reload()



func set_ads(enabled: bool) -> void:

	if active_weapon:

		active_weapon.set_ads(enabled)



func _process(delta: float) -> void:

	# Read mouse velocity for sway (pixels per frame)

	var mouse_vel: Vector2 = Input.get_last_mouse_velocity()

	# Determine if player is moving to scale bobbing

	var moving := (

		Input.is_action_pressed("move_forward")

		or Input.is_action_pressed("move_backward")

		or Input.is_action_pressed("move_left")

		or Input.is_action_pressed("move_right")

	)

	# Target position sway (local X/Y), move opposite to mouse motion

	var target_pos_x: float = clamp(-mouse_vel.x * position_sway_amount, -position_sway_max.x, position_sway_max.x)

	var target_pos_y: float = clamp(-mouse_vel.y * position_sway_amount, -position_sway_max.y, position_sway_max.y)

	# Idle bob (scaled when moving)

	var bob_multiplier: float = 1.0

	if moving:

		bob_multiplier = moving_bob_multiplier

	var bob_speed: float = idle_bob_speed * bob_multiplier

	_bob_time += delta * bob_speed

	var bob_offset_y: float = sin(_bob_time) * idle_bob_amount

	_pos_offset_target = Vector3(target_pos_x, target_pos_y + bob_offset_y, 0.0)

	# Rotation sway: small yaw (Y) opposite X, pitch (X) following Y

	var target_yaw: float = clamp(-mouse_vel.x * rotation_sway_amount, -rotation_sway_max.x, rotation_sway_max.x)

	var target_pitch: float = clamp(mouse_vel.y * rotation_sway_amount, -rotation_sway_max.y, rotation_sway_max.y)

	_rot_offset_target_degrees = Vector3(target_pitch, target_yaw, 0.0)

	# Smooth toward targets

	var t: float = clamp(sway_smooth_speed * delta, 0.0, 1.0)

	_pos_offset = _pos_offset.lerp(_pos_offset_target, t)

	_rot_offset_degrees = _rot_offset_degrees.lerp(_rot_offset_target_degrees, t)

	# Apply to viewmodel (relative to defaults)

	position = _default_position + _pos_offset

	rotation_degrees = _default_rotation_degrees + _rot_offset_degrees
