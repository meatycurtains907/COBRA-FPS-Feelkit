extends Area3D

signal hit(collider: Object, position: Vector3, normal: Vector3)

@export var speed: float = 40.0
@export var gravity_strength: float = 9.8  # Renamed from 'gravity' to avoid conflict with Area3D.gravity
@export var max_lifetime: float = 3.0

var _velocity: Vector3 = Vector3.ZERO
var _age: float = 0.0

@onready var _cast_sfx: AudioStreamPlayer3D = get_node_or_null("CastSfx")
@onready var _impact_sfx: AudioStreamPlayer3D = get_node_or_null("ImpactSfx")


func configure(start: Vector3, direction: Vector3) -> void:
	global_position = start
	_velocity = direction.normalized() * speed
	_age = 0.0


func _ready() -> void:
	# Play cast sound when projectile spawns
	if _cast_sfx and _cast_sfx.stream:
		_cast_sfx.play()


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	var from := global_position
	if gravity_strength != 0.0:
		_velocity += Vector3(0.0, -gravity_strength * delta, 0.0)
	var to := from + _velocity * delta

	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(from, to)

	# Match hitscan behavior: bodies only, no areas
	params.collide_with_areas = false
	params.collide_with_bodies = true

	# Exclude the projectile itself + the player (same pattern as hitscan)
	var exclude := [get_rid()]
	var player_node := get_tree().get_first_node_in_group("player")
	if player_node != null:
		exclude.append(player_node.get_rid())
	params.exclude = exclude

	var result := space.intersect_ray(params)
	if result.size() > 0:
		var collider: Object = result.get("collider")
		var pos: Vector3 = result.get("position", Vector3.ZERO)
		var normal: Vector3 = result.get("normal", Vector3.UP)
		
		# Existing damage/VFX logic via signal
		emit_signal("hit", collider, pos, normal)
		
		# Fireball impact SFX: spawn one-shot audio player at impact position
		# Get scene reference before queue_free() to avoid errors
		var scene: Node = null
		if is_inside_tree():
			var tree := get_tree()
			if tree:
				scene = tree.current_scene
		
		# Spawn impact SFX before queue_free() using cached scene reference
		if _impact_sfx and _impact_sfx.stream and scene:
			var player := AudioStreamPlayer3D.new()
			player.stream = _impact_sfx.stream
			scene.add_child(player)
			# Set position after adding to scene tree (required for global_transform)
			player.global_transform.origin = pos
			player.play()
			# Clean up once finished
			player.finished.connect(player.queue_free)
		
		# Now safe to queue_free() - we've done everything we need
		queue_free()
	else:
		global_position = to

	_age += delta
	if _age >= max_lifetime:
		queue_free()
