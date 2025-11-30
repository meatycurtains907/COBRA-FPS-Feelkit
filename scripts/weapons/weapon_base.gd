extends Node3D

class_name WeaponBase



signal fired

signal shot_fired  # Stats tracking - emitted when a real bullet is fired

signal hit_confirmed(target)

@warning_ignore("unused_signal")
signal kill_confirmed(target: Node)  # Emitted by Damageable when target dies, connected externally by HUD

signal ammo_changed(current_in_mag: int, mag_size: int)

signal reload_started

signal reload_finished

signal recoil_requested(offset: Vector2) # Camera rig can listen to this



@export var config: WeaponConfig

@export var muzzle_node_path: NodePath

var _muzzle_node: Node3D

@export var aim_node_path: NodePath

var aim_node: Node3D

@export var projectile_scene: PackedScene  # If assigned, this weapon fires projectiles instead of hitscan



var _current_ammo: int

var _time_since_last_shot: float = 0.0

var _is_reloading: bool = false

var _is_ads: bool = false

var _recoil_index: int = 0

var _current_spread: float = 0.0

const MAX_RAY_DISTANCE: float = 1000.0



func _ready() -> void:

	randomize()

	# Resolve aim_node from NodePath

	if aim_node_path != NodePath():

		aim_node = get_node(aim_node_path) as Node3D

	if aim_node == null:

		push_warning("WeaponBase has no aim_node assigned; cannot shoot.")

	if config == null:

		push_warning("WeaponBase has no WeaponConfig assigned.")

		return

	# Resolve optional muzzle node

	if muzzle_node_path != NodePath():

		_muzzle_node = get_node(muzzle_node_path) as Node3D

	_current_ammo = config.mag_size

	if config.uses_ammo:
		_notify_ammo_changed()



func _process(delta: float) -> void:

	_time_since_last_shot += delta

	_decay_spread(delta)



func set_ads(enabled: bool) -> void:

	_is_ads = enabled



func get_current_ammo() -> int:

	return _current_ammo



func get_spread_ratio() -> float:

	if config == null:

		return 0.0

	var base_max: float = max(config.hip_spread, config.ads_spread)

	if base_max <= 0.0001:

		return 0.0

	return clamp(_current_spread / base_max, 0.0, 1.5)



func _notify_ammo_changed() -> void:

	emit_signal("ammo_changed", _current_ammo, config.mag_size)



func try_fire() -> void:

	if config == null:

		return

	if _is_reloading:

		return

	if not _can_fire_now():

		return

	# Skip ammo check if weapon doesn't use ammo
	if config and config.uses_ammo:
		if _current_ammo <= 0:
			_play_empty()
			return

	_do_fire()



func try_reload() -> void:

	if config == null:

		return

	# Skip reload if weapon doesn't use ammo
	if not config.uses_ammo:
		return

	if _is_reloading:

		return

	if _current_ammo >= config.mag_size:

		return

	_start_reload()



func apply_config(new_config: WeaponConfig) -> void:

	if new_config == null:

		push_warning("WeaponBase.apply_config: new_config is null")

		return

	config = new_config

	if config.mag_size <= 0:

		push_warning("WeaponBase.apply_config: mag_size <= 0, using default")

		_current_ammo = 1

	else:

		_current_ammo = config.mag_size

	# Only notify if weapon uses ammo
	if config.uses_ammo:
		_notify_ammo_changed()



func _can_fire_now() -> bool:

	var fire_interval := 1.0 / config.fire_rate

	return _time_since_last_shot >= fire_interval



func _do_fire() -> void:

	_time_since_last_shot = 0.0

	# Only consume ammo and emit signals if weapon uses ammo
	if config and config.uses_ammo:
		_current_ammo -= 1
		_notify_ammo_changed()

	emit_signal("fired")

	emit_signal("shot_fired")  # Stats tracking

	_increase_spread()

	_apply_recoil()

	# SFX and VFX on successful shot
	# Skip weapon fire_sfx for projectile weapons - the projectile plays its own cast sound
	if config != null:
		if config.fire_sfx and projectile_scene == null:
			_play_sfx(config.fire_sfx)

		_spawn_muzzle_flash()

	_perform_shot()



func _perform_shot() -> void:

	if aim_node == null:

		push_warning("WeaponBase has no aim_node assigned; cannot shoot.")

		return

	if config == null:

		return



	# 1) Get origin & base forward direction from the aim node (Camera3D)

	var origin: Vector3 = aim_node.global_transform.origin

	# Use camera's global transform to get the forward direction including rotation

	var camera: Camera3D = aim_node as Camera3D

	if camera == null:

		push_warning("WeaponBase aim_node is not a Camera3D")

		return

	var camera_transform := camera.global_transform

	# Get forward direction from camera transform (base direction without spread)

	var base_direction: Vector3 = -camera_transform.basis.z.normalized()

	var aim_basis: Basis = camera_transform.basis

	# Decide projectile origin (prefer muzzle for visuals, fallback to camera/aim origin)
	var projectile_origin := origin
	if _muzzle_node != null:
		projectile_origin = _muzzle_node.global_transform.origin
	# Hitscan continues to use the camera/aim origin; projectiles
	# visually spawn from the muzzle when available.



	# Branch: hitscan vs projectile
	if projectile_scene == null:
		# Hitscan path (supports pellet mode)
		var pellet_count := 1
		if config and config.pellet_count > 1:
			pellet_count = config.pellet_count
		
		if pellet_count > 1:
			var base_spread: float = config.hip_spread if config else 0.0
			if _is_ads and config:
				base_spread = config.ads_spread
		
		for i in pellet_count:
			_perform_single_pellet_hitscan(origin, base_direction, aim_basis)
	else:
		# Projectile path (unchanged - single projectile per trigger)
		# Apply spread for projectile as before
		var dir: Vector3 = base_direction
		var spread_deg: float = _current_spread
		if spread_deg > 0.0:
			var spread_rad := deg_to_rad(spread_deg)
			var yaw_offset := randf_range(-spread_rad, spread_rad)
			var pitch_offset := randf_range(-spread_rad, spread_rad)
			var right: Vector3 = aim_basis.x.normalized()
			dir = dir.rotated(Vector3.UP, yaw_offset)
			dir = dir.rotated(right, pitch_offset).normalized()
		
		_spawn_projectile(projectile_origin, dir)

func _perform_single_pellet_hitscan(origin: Vector3, base_direction: Vector3, aim_basis: Basis) -> void:
	# Start from base_direction (already camera-based)
	var direction := base_direction
	
	# For pellets, use base spread (hip_spread or ads_spread) as foundation, not accumulated _current_spread
	# This ensures shotguns always have a wide cone even on first shot
	var base_spread: float = config.hip_spread if config else 0.0
	if _is_ads and config:
		base_spread = config.ads_spread
	
	var spread_deg: float = base_spread
	
	# Apply pellet spread scaling to widen the cone
	var spread_scale := 1.0
	if config and config.pellet_spread_scale > 0.0:
		spread_scale = config.pellet_spread_scale
	
	spread_deg *= spread_scale
	
	if spread_deg > 0.0:
		var spread_rad := deg_to_rad(spread_deg)
		var yaw_offset := randf_range(-spread_rad, spread_rad)
		var pitch_offset := randf_range(-spread_rad, spread_rad)
		var right: Vector3 = aim_basis.x.normalized()
		
		# Apply yaw first (around global up), then pitch (around camera's right axis)
		direction = direction.rotated(Vector3.UP, yaw_offset)
		direction = direction.rotated(right, pitch_offset).normalized()
	
	# Perform raycast
	var to: Vector3 = origin + direction * MAX_RAY_DISTANCE
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	# Exclude player from raycast
	var player_node := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player_node != null:
		query.exclude = [player_node.get_rid()]
	
	var result := space_state.intersect_ray(query)
	
	if result.size() > 0:
		var collider: Node = result.get("collider", null)
		var hit_pos: Vector3 = result.get("position", Vector3.ZERO)
		var hit_normal: Vector3 = result.get("normal", Vector3.UP)
		# Always spawn impact effect for pellets - makes spread visible
		_handle_hit(collider, hit_pos, hit_normal)

func _start_reload() -> void:

	_is_reloading = true

	emit_signal("reload_started")

	if config.reload_sfx:

		_play_sfx(config.reload_sfx)

	var t := get_tree().create_timer(config.reload_time)

	t.timeout.connect(_finish_reload)



func _finish_reload() -> void:

	_is_reloading = false

	_current_ammo = config.mag_size

	_notify_ammo_changed()

	emit_signal("reload_finished")



func _increase_spread() -> void:

	var target_spread := config.hip_spread

	if _is_ads:

		target_spread = config.ads_spread

	_current_spread = min(

		_current_spread + config.spread_increase_per_shot,

		target_spread

	)



func _decay_spread(delta: float) -> void:

	if _current_spread <= 0.0:

		return

	_current_spread = max(_current_spread - config.spread_decay_rate * delta, 0.0)



func _apply_recoil() -> void:

	if config.recoil_pattern.size() == 0:

		return

	var offset := config.recoil_pattern[_recoil_index % config.recoil_pattern.size()]

	_recoil_index += 1

	emit_signal("recoil_requested", offset)



func _play_empty() -> void:

	if config.empty_sfx:

		_play_sfx(config.empty_sfx)



func _play_sfx(stream: AudioStream) -> void:

	if not stream:

		return

	var p := AudioStreamPlayer3D.new()

	p.stream = stream

	add_child(p)

	p.play()

	p.finished.connect(p.queue_free)



func _spawn_muzzle_flash() -> void:

	if config == null:

		return

	if config.muzzle_flash_scene == null:

		return

	var flash: Node3D = config.muzzle_flash_scene.instantiate() as Node3D

	if flash == null:

		return

	var spawn_transform: Transform3D

	if _muzzle_node != null:

		spawn_transform = _muzzle_node.global_transform

	else:

		spawn_transform = global_transform

	flash.global_transform = spawn_transform

	var root := get_tree().current_scene

	if root:

		root.add_child(flash)

	else:

		add_child(flash)



func _handle_hit(collider: Object, hit_position: Vector3, hit_normal: Vector3) -> void:
	if collider == null:
		return
	
	var was_kill: bool = false
	
	if collider.has_method("apply_damage"):
		was_kill = collider.apply_damage(config.damage, self)
	
	# Spawn impact VFX at hit position if available
	_spawn_impact_effect(hit_position, hit_normal)
	
	# Only emit hit_confirmed if it wasn't a kill (kill_confirmed already emitted by Damageable)
	if not was_kill:
		emit_signal("hit_confirmed", collider)


func _spawn_impact_effect(hit_position: Vector3, hit_normal: Vector3) -> void:

	if config == null:

		return

	if config.impact_effect_scene == null:

		return

	var impact: Node3D = config.impact_effect_scene.instantiate() as Node3D

	if impact == null:

		return

	# Add to tree first before setting transform/look_at
	var root := get_tree().current_scene

	if root:

		root.add_child(impact)

	else:

		add_child(impact)

	# Now we can safely use global_transform and look_at
	impact.global_transform.origin = hit_position

	var up: Vector3 = Vector3.UP

	if abs(hit_normal.dot(up)) > 0.9:

		up = Vector3.FORWARD

	impact.look_at(hit_position + hit_normal, up)


func _spawn_projectile(origin: Vector3, direction: Vector3) -> void:
	if projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return

	# Match existing pattern: use current_scene, fallback to self.add_child
	var root := get_tree().current_scene
	if root:
		root.add_child(projectile)
	else:
		add_child(projectile)

	if projectile.has_method("configure"):
		projectile.configure(origin, direction)

	if projectile.has_signal("hit"):
		projectile.hit.connect(_on_projectile_hit, CONNECT_ONE_SHOT)


func _on_projectile_hit(collider: Object, hit_position: Vector3, hit_normal: Vector3) -> void:
	_handle_hit(collider, hit_position, hit_normal)
