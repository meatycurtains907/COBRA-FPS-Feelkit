extends CharacterBody3D

class_name FeelPlayer

# Returns a simple, human-readable movement state.
# Examples: "Idle", "Walk", "Sprint", "Crouch", "Crouch + ADS"
func get_movement_state() -> String:
	var state := "Idle"

	# Horizontal speed from our internal _velocity.
	var horizontal_speed := Vector2(_velocity.x, _velocity.z).length()
	var is_moving := horizontal_speed > 0.05
	var is_sprinting := Input.is_action_pressed("sprint") and is_moving

	if _is_crouching:
		state = "Crouch"
	elif is_sprinting:
		state = "Sprint"
	elif is_moving:
		state = "Walk"
	else:
		state = "Idle"

	if _is_ads:
		state += " + ADS"

	return state


@export var feel_config: PlayerFeelConfig



# Feel config-driven vars (defaults will be overridden by _apply_feel_config())

var move_speed: float = 5.0

var sprint_speed: float = 8.0

var crouch_speed: float = 3.0

var jump_force: float = 4.5

var mouse_sensitivity: float = 0.12

var ads_sensitivity_multiplier: float = 0.7

var hip_fov: float = 75.0

var ads_fov: float = 55.0

var ads_fov_lerp_speed: float = 10.0



@export var bob_amount: float = 0.08

@export var bob_speed: float = 10.0

@export var bob_reset_speed: float = 10.0

@export var stand_height: float = 2.0

@export var crouch_height: float = 1.2

@export var crouch_transition_speed: float = 8.0

@export var stand_camera_height: float = 1.6

@export var crouch_camera_height: float = 1.0

@export var enable_block: bool = true

@export var enable_fire: bool = true

@export var fire_triggers_melee: bool = false

@export var aim_triggers_magic: bool = false



@onready var cam: Camera3D = $RecoilPivot/Camera3D

@onready var weapon_rig: WeaponRig = $RecoilPivot/Camera3D/WeaponRig

func get_active_weapon() -> WeaponBase:
	if weapon_rig and weapon_rig.active_weapon:
		return weapon_rig.active_weapon
	return null

func is_blocking() -> bool:
	return _is_blocking

@onready var melee_weapon: MeleeWeapon = $RecoilPivot/Camera3D/MeleeWeapon

@onready var recoil_pivot: RecoilController = $RecoilPivot

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D



var _velocity: Vector3 = Vector3.ZERO

var _bob_time: float = 0.0

var _cam_default_position: Vector3

var _current_fov: float

var _is_ads: bool = false

var _is_crouching: bool = false

var _is_blocking: bool = false

var _target_height: float

var _current_height: float

var _target_camera_height: float

var _current_camera_height: float



func _apply_feel_config() -> void:

	if feel_config == null:

		return



	move_speed = feel_config.move_speed

	sprint_speed = feel_config.sprint_speed

	crouch_speed = feel_config.crouch_speed



	jump_force = feel_config.jump_force



	mouse_sensitivity = feel_config.mouse_sensitivity

	ads_sensitivity_multiplier = feel_config.ads_sensitivity_multiplier



	hip_fov = feel_config.hip_fov

	ads_fov = feel_config.ads_fov

	ads_fov_lerp_speed = feel_config.ads_fov_lerp_speed



	if cam:

		cam.fov = hip_fov

	_current_fov = hip_fov



	# Push recoil/shake scale down to the recoil_pivot if present

	if recoil_pivot and feel_config:

		recoil_pivot.recoil_scale = feel_config.recoil_scale

		recoil_pivot.shake_scale = feel_config.shake_scale



func _ready() -> void:

	# Load default config if not assigned

	if feel_config == null:

		feel_config = preload("res://config/Feel_Default.tres")



	# Apply config before using any feel-dependent values

	_apply_feel_config()



	add_to_group("player")

	# Initialize crouch state

	_current_height = stand_height

	_target_height = stand_height

	_current_camera_height = stand_camera_height

	_target_camera_height = stand_camera_height

	# Set up collision shape height

	if _collision_shape != null:

		var capsule := _collision_shape.shape as CapsuleShape3D

		if capsule != null:

			capsule.height = stand_height

			# Position capsule so feet are at ground level

			_collision_shape.transform.origin.y = stand_height * 0.5

	# Cache default camera position for head bob

	if cam != null:

		_cam_default_position = Vector3(cam.position.x, stand_camera_height, cam.position.z)

		cam.position = _cam_default_position

	# Wait for weapon to be initialized, then connect recoil signal

	await get_tree().process_frame

	var weapon = weapon_rig.active_weapon

	if weapon != null and recoil_pivot != null:

		if not weapon.recoil_requested.is_connected(recoil_pivot.apply_recoil):

			weapon.recoil_requested.connect(recoil_pivot.apply_recoil)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func _input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:

		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:

			_handle_look(event)



func _physics_process(delta: float) -> void:

	_handle_crouch_input()

	_handle_movement(delta)

	_update_crouch_transition(delta)

	_update_head_bob(delta)

	_handle_actions()

	_update_ads_fov(delta)



func _handle_movement(delta: float) -> void:

	var input_dir := Vector2.ZERO

	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	input_dir.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")

	input_dir = input_dir.normalized()



	var player_basis := global_transform.basis

	var forward := -player_basis.z

	var right := player_basis.x



	var desired_velocity := (forward * input_dir.y + right * input_dir.x)

	desired_velocity.y = 0.0



	var speed := move_speed

	if _is_crouching:

		speed = crouch_speed

	elif Input.is_action_pressed("sprint"):

		speed = sprint_speed



	_velocity.x = desired_velocity.x * speed

	_velocity.z = desired_velocity.z * speed



	# Apply gravity (gravity pulls down, so we subtract it)

	var gravity_value: Variant = ProjectSettings.get_setting("physics/3d/default_gravity")

	var gravity: float = float(gravity_value) * delta

	var was_on_floor := is_on_floor()

	if was_on_floor:

		# On floor: only jump if button pressed, otherwise stay on ground

		if Input.is_action_just_pressed("jump"):

			_velocity.y = jump_force

		else:

			# Force velocity to 0 or slightly negative to ensure floor contact

			_velocity.y = -0.1

	else:

		# In air: apply gravity (subtract to pull down)

		_velocity.y -= gravity

		# Clamp falling velocity to terminal velocity

		var max_fall_speed: float = 50.0

		if _velocity.y < -max_fall_speed:

			_velocity.y = -max_fall_speed



	velocity = _velocity

	move_and_slide()

	_velocity = velocity

	# After move_and_slide, force Y velocity to 0 if on floor (unless jumping)

	var now_on_floor := is_on_floor()

	if now_on_floor and not Input.is_action_just_pressed("jump"):

		_velocity.y = 0.0

		velocity.y = 0.0




func _update_head_bob(delta: float) -> void:

	if cam == null:

		return

	# Calculate horizontal movement speed (ignore Y velocity)

	var horizontal_speed := Vector2(_velocity.x, _velocity.z).length()

	var is_moving := is_on_floor() and horizontal_speed > 0.1

	# Use current camera height as base (from crouch) and apply bob offset

	var base_camera_position := Vector3(_cam_default_position.x, _current_camera_height, _cam_default_position.z)

	if is_moving:

		# Increment bob time and calculate vertical offset

		_bob_time += delta * bob_speed

		var bob_offset_y := sin(_bob_time) * bob_amount

		# Apply bob to camera position (local) - only Y axis

		cam.position = base_camera_position + Vector3(0.0, bob_offset_y, 0.0)

	else:

		# Reset bob time when not moving (or reset slowly if preferred)

		_bob_time = 0.0

		# Smoothly lerp camera back to base position

		cam.position = cam.position.lerp(base_camera_position, bob_reset_speed * delta)



func _handle_look(event: InputEventMouseMotion) -> void:

	# Yaw: rotate player body around Y axis

	var effective_sensitivity := mouse_sensitivity

	if _is_ads:

		effective_sensitivity *= ads_sensitivity_multiplier

	rotate_y(-event.relative.x * effective_sensitivity * 0.01)

	# Pitch: rotate camera around X axis

	var pitch_delta := -event.relative.y * effective_sensitivity * 0.01

	cam.rotate_x(pitch_delta)

	# Clamp pitch to prevent flipping

	cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -89.0, 89.0)



func _handle_actions() -> void:

	# Fire (scene-gated)
	if enable_fire and not fire_triggers_melee and InputMap.has_action("fire"):
		if Input.is_action_pressed("fire"):
			if weapon_rig:
				weapon_rig.fire()

	if Input.is_action_just_pressed("reload"):

		weapon_rig.reload()

	if InputMap.has_action("aim"):
		if aim_triggers_magic:
			# Magic / melee mode: RMB casts magic instead of ADS.
			if Input.is_action_just_pressed("aim") and weapon_rig:
				# Fire the active weapon once (configured as a magic projectile).
				weapon_rig.fire()

			# Make sure ADS state is always off in this mode.
			if _is_ads:
				_is_ads = false
				if weapon_rig:
					weapon_rig.set_ads(false)
		else:
			# Default FPS behavior: RMB controls ADS.
			var aiming := Input.is_action_pressed("aim")
			if aiming != _is_ads:
				_is_ads = aiming
				if weapon_rig:
					weapon_rig.set_ads(aiming)

	# Block (scene-gated)
	if enable_block:
		if InputMap.has_action("block"):
			var block_pressed := Input.is_action_pressed("block")
			if block_pressed != _is_blocking:
				_is_blocking = block_pressed
		else:
			push_warning("Input action 'block' is not defined; blocking will be disabled.")
	else:
		# Ensure block state is cleared whenever block is disabled for this scene
		if _is_blocking:
			_is_blocking = false

	if melee_weapon:
		if fire_triggers_melee:
			# Skyrim-style: LMB = melee when this flag is on
			if InputMap.has_action("fire") and Input.is_action_just_pressed("fire"):
				melee_weapon.try_melee()
		else:
			if InputMap.has_action("melee") and Input.is_action_just_pressed("melee"):
				melee_weapon.try_melee()
	else:
		# Only warn if melee was actually requested
		if fire_triggers_melee:
			if InputMap.has_action("fire") and Input.is_action_just_pressed("fire"):
				push_warning("FeelPlayer: melee_weapon is null")
		elif InputMap.has_action("melee") and Input.is_action_just_pressed("melee"):
			push_warning("FeelPlayer: melee_weapon is null")



func _update_ads_fov(delta: float) -> void:

	if cam == null:

		return

	var target_fov: float = hip_fov

	if _is_ads:

		target_fov = ads_fov

	var t: float = clamp(ads_fov_lerp_speed * delta, 0.0, 1.0)

	_current_fov = lerp(_current_fov, target_fov, t)

	cam.fov = _current_fov



func _handle_crouch_input() -> void:

	if Input.is_action_just_pressed("crouch"):

		_is_crouching = !_is_crouching

		if _is_crouching:

			_target_height = crouch_height

			_target_camera_height = crouch_camera_height

		else:

			_target_height = stand_height

			_target_camera_height = stand_camera_height



func _update_crouch_transition(delta: float) -> void:

	if _collision_shape == null:

		return

	var t: float = clamp(crouch_transition_speed * delta, 0.0, 1.0)

	_current_height = lerp(_current_height, _target_height, t)

	_current_camera_height = lerp(_current_camera_height, _target_camera_height, t)

	# Apply to collider

	var capsule := _collision_shape.shape as CapsuleShape3D

	if capsule != null:

		capsule.height = _current_height

		# Position capsule so feet are at ground level

		_collision_shape.transform.origin.y = _current_height * 0.5
