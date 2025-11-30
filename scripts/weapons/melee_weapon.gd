extends Node3D

class_name MeleeWeapon



@export var config: MeleeConfig

@export var aim_node_path: NodePath

var aim_node: Node3D

@export var sword_node_path: NodePath

var _sword_node: Node3D = null

var _sword_idle_transform: Transform3D

var _sword_idle_cached := false

# SFX overrides (with config fallback)
@export var swing_sfx_override: AudioStream = null
@export var world_hit_sfx_override: AudioStream = null
@export var dummy_hit_sfx_override: AudioStream = null

@onready var _sfx_player: AudioStreamPlayer3D = get_node_or_null("SfxPlayer")



var _is_swinging: bool = false

var _in_recovery: bool = false

var _swing_elapsed: float = 0.0

# Combo tracking
var _combo_index: int = 0  # 0 = Light1, 1 = Light2, 2 = Heavy
var _combo_timer: float = 0.0  # counts down time remaining to chain the next hit
var _queued_next: bool = false  # player pressed melee while we were in recovery
const COMBO_RESET_TIME := 0.6  # if this much time passes after a swing with no valid queue, reset combo

# Combo stage multipliers
const LIGHT1_DAMAGE_MULT := 1.0
const LIGHT2_DAMAGE_MULT := 1.1
const HEAVY_DAMAGE_MULT := 1.8

# Per-stage recovery time multipliers
const LIGHT1_RECOVER_MULT := 1.0
const LIGHT2_RECOVER_MULT := 1.0
const HEAVY_RECOVER_MULT := 1.2



func _ready() -> void:

	# Resolve aim_node from NodePath

	if aim_node_path != NodePath():

		aim_node = get_node(aim_node_path) as Node3D

	else:

		push_warning("MeleeWeapon has no aim_node_path set.")

	if aim_node == null:

		push_warning("MeleeWeapon has no aim_node assigned; cannot melee.")

	if config == null:

		push_warning("MeleeWeapon has no MeleeConfig assigned.")

	# Resolve sword node (may not exist yet if spawned later)
	_resolve_sword_node()

	# Enable processing for swing/recovery timing

	set_process(true)


func _resolve_sword_node() -> void:
	if _sword_node == null and sword_node_path != NodePath(""):
		_sword_node = get_node_or_null(sword_node_path) as Node3D
		if _sword_node and not _sword_idle_cached:
			_sword_idle_transform = _sword_node.transform
			_sword_idle_cached = true


func _reset_combo() -> void:
	_combo_index = 0
	_combo_timer = 0.0
	_queued_next = false


func _current_damage_mult() -> float:
	match _combo_index:
		1: return LIGHT2_DAMAGE_MULT
		2: return HEAVY_DAMAGE_MULT
		_: return LIGHT1_DAMAGE_MULT


func _current_recovery_time() -> float:
	var base := config.recovery_time
	match _combo_index:
		2: return base * HEAVY_RECOVER_MULT
		_: return base


func _get_swing_sfx() -> AudioStream:
	if swing_sfx_override:
		return swing_sfx_override
	if config and config.swing_sfx:
		return config.swing_sfx
	return null


func _get_dummy_hit_sfx() -> AudioStream:
	if dummy_hit_sfx_override:
		return dummy_hit_sfx_override
	if config and config.hit_sfx:
		return config.hit_sfx
	return null


func _get_world_hit_sfx() -> AudioStream:
	if world_hit_sfx_override:
		return world_hit_sfx_override
	if config and config.hit_sfx:
		return config.hit_sfx
	return null


func _start_swing_for_current_stage() -> void:
	_is_swinging = true
	_in_recovery = false
	_swing_elapsed = 0.0
	# Swing SFX moved to miss case in _do_melee_hit()


func get_combo_stage_name() -> String:
	if _is_swinging or _in_recovery:
		match _combo_index:
			1: return "Light 2"
			2: return "Heavy"
			_: return "Light 1"
	return "None"



func try_melee() -> void:

	if config == null:
		push_warning("MeleeWeapon: no config assigned")
		return

	if aim_node == null:
		push_warning("MeleeWeapon: no aim_node assigned")
		return

	if _is_swinging:
		return

	if _in_recovery:
		if _combo_timer > 0.0:
			_queued_next = true
		return

	# IDLE path - start swing at current combo index
	_start_swing_for_current_stage()



func _process(delta: float) -> void:
	# Lazily resolve sword node (in case it's spawned after _ready())
	_resolve_sword_node()

	# Update combo timer
	if _combo_timer > 0.0:
		_combo_timer = max(_combo_timer - delta, 0.0)
		if _combo_timer == 0.0 and not _is_swinging and not _in_recovery:
			_reset_combo()

	if _is_swinging:

		_swing_elapsed += delta

		if _swing_elapsed >= config.swing_time:

			_do_melee_hit()

			_is_swinging = false

			_in_recovery = true

			_swing_elapsed = 0.0

			_combo_timer = COMBO_RESET_TIME

	elif _in_recovery:

		_swing_elapsed += delta

		var recovery_time := _current_recovery_time()

		if _swing_elapsed >= recovery_time:

			_in_recovery = false

			_swing_elapsed = 0.0

			if _queued_next and _combo_timer > 0.0:
				_queued_next = false
				if _combo_index < 2:
					_combo_index += 1
				_start_swing_for_current_stage()  # Light2 or Heavy
			else:
				_reset_combo()
	
	# Update sword visual based on swing state
	_update_sword_visual(delta)



func _do_melee_hit() -> void:

	if aim_node == null or config == null:

		return

	# Match WeaponBase transform calculation pattern

	var camera_transform := aim_node.global_transform

	var forward := -camera_transform.basis.z.normalized()

	var center := camera_transform.origin + forward * config.melee_range

	# Create sphere shape for melee hitbox

	var sphere_shape := SphereShape3D.new()

	sphere_shape.radius = config.hitbox_radius

	# Set up physics shape query

	var params := PhysicsShapeQueryParameters3D.new()

	params.shape = sphere_shape

	params.transform = Transform3D.IDENTITY.translated(center)

	params.collide_with_areas = false

	params.collide_with_bodies = true

	# Exclude player from melee hits (same pattern as WeaponBase)

	var player_node := get_tree().get_first_node_in_group("player") as CharacterBody3D

	if player_node != null:

		params.exclude = [player_node.get_rid()]

	# Perform sphere query

	var space_state := get_world_3d().direct_space_state

	var results := space_state.intersect_shape(params, 16)

	# Track hit types for SFX
	var hit_dummy := false
	var hit_world := false
	var last_hit_position: Vector3 = center  # Default to center if no collision point
	var last_hit_normal: Vector3 = Vector3.UP  # Default normal

	for result in results:

		var collider: Node = result.get("collider", null)
		var hit_pos: Vector3 = result.get("position", center)
		var normal: Vector3 = result.get("normal", Vector3.UP)

		if collider != null and collider.has_method("apply_damage"):

			var damage := config.damage * _current_damage_mult()
			# Call apply_damage - any successful call (regardless of return value) counts as a hit
			collider.apply_damage(damage, self)
			hit_dummy = true
			last_hit_position = hit_pos
			last_hit_normal = normal

		else:
			# Non-damageable collider = world hit
			hit_world = true
			last_hit_position = hit_pos
			last_hit_normal = normal

	# Play hit feedback (SFX/VFX) based on hit type
	if hit_dummy:
		_play_hit_feedback(true, last_hit_position, last_hit_normal)
		_play_sfx(_get_dummy_hit_sfx())
	elif hit_world:
		_play_hit_feedback(true, last_hit_position, last_hit_normal)
		_play_sfx(_get_world_hit_sfx())
	else:
		# No hits at all - swing through empty space (miss)
		_play_sfx(_get_swing_sfx())



func _play_hit_feedback(did_hit: bool, hit_position: Vector3, hit_normal: Vector3) -> void:

	if did_hit:
		# Play hit SFX if configured
		if config.hit_sfx:
			_play_sfx_at_position(config.hit_sfx, hit_position)

		# Spawn hit effect scene if available
		if config.hit_effect_scene:
			var effect_instance := config.hit_effect_scene.instantiate()
			var root := get_tree().current_scene
			if root:
				root.add_child(effect_instance)
				effect_instance.global_position = hit_position
				# Optionally orient effect based on hit normal
				if effect_instance is Node3D:
					var up: Vector3 = Vector3.UP
					if abs(hit_normal.dot(up)) > 0.9:
						up = Vector3.FORWARD
					(effect_instance as Node3D).look_at(hit_position + hit_normal, up)



func _play_sfx(stream: AudioStream) -> void:

	if not _sfx_player or stream == null:

		return

	_sfx_player.stream = stream

	_sfx_player.play()



func _play_sfx_at_position(stream: AudioStream, sfx_position: Vector3) -> void:

	if not stream:

		return

	var p := AudioStreamPlayer3D.new()

	p.stream = stream

	p.global_position = sfx_position

	add_child(p)

	p.play()

	p.finished.connect(p.queue_free)

func _update_sword_visual(delta: float) -> void:
	if _sword_node == null or not _sword_idle_cached:
		return
	
	# During the active swing, drive a simple arc.
	if _is_swinging and config and config.swing_time > 0.0:
		var t: float = clamp(_swing_elapsed / config.swing_time, 0.0, 1.0)
		var eased: float = sin(t * PI)  # 0 → 1 → 0
		
		# Yaw and pitch arc relative to idle.
		var yaw_deg: float = lerp(-10.0, 60.0, t)
		var pitch_deg: float = lerp(5.0, -20.0, t)
		
		var local_basis: Basis = Basis.from_euler(Vector3(
			deg_to_rad(pitch_deg),
			deg_to_rad(yaw_deg),
			0.0
		))
		
		# Small downward offset at peak to feel weighty.
		var offset: Vector3 = Vector3(0.0, lerp(0.0, -0.10, eased), 0.0)
		
		var t_local: Transform3D = Transform3D(local_basis, _sword_idle_transform.origin + offset)
		_sword_node.transform = t_local
		return
	
	# When not actively swinging, smoothly return toward idle.
	var alpha: float = clamp(8.0 * delta, 0.0, 1.0)
	_sword_node.transform = _sword_node.transform.interpolate_with(_sword_idle_transform, alpha)
