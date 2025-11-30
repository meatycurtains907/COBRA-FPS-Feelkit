extends Node3D



@export var auto_respawn: bool = false

@export var respawn_delay: float = 2.0

@export var training_target_scene: PackedScene = null

@export var hud_path: NodePath = NodePath("../../HUD")



var _target_spawns: Dictionary = {}  # Maps target nodes to their spawn transforms

var _connected_targets: Dictionary = {}  # Maps target nodes to their connection callables

var _is_resetting: bool = false  # Prevent multiple simultaneous resets

@onready var _hud: Node = get_node_or_null(hud_path)



func _ready() -> void:

	# Find all TrainingTarget instances under Range

	_collect_targets()



func _collect_targets() -> void:

	_target_spawns.clear()

	

	# Traverse all children recursively to find TrainingTarget instances

	_collect_targets_recursive(self)



func _collect_targets_recursive(node: Node) -> void:

	# Check if this node is a TrainingTarget

	if node is TrainingTarget:

		var target := node as TrainingTarget

		var spawn_transform := target.global_transform

		_target_spawns[target] = spawn_transform

		

		# Connect to died signal using a lambda to capture spawn_transform

		# Disconnect previous connection if exists

		if target in _connected_targets:

			var old_callable = _connected_targets[target]

			if target.died.is_connected(old_callable):

				target.died.disconnect(old_callable)

		

		# Create and store new callable

		var new_callable = func(killer: Node): _on_target_died(killer, spawn_transform)

		_connected_targets[target] = new_callable

		target.died.connect(new_callable)

	

	# Recursively check children

	for child in node.get_children():

		_collect_targets_recursive(child)



func _on_target_died(_killer: Node, spawn_transform: Transform3D) -> void:

	if not auto_respawn:

		return

	

	# Create a timer for respawn delay

	var timer := get_tree().create_timer(respawn_delay)

	timer.timeout.connect(_respawn_target.bind(spawn_transform))



func _respawn_target(spawn_transform: Transform3D) -> void:

	if training_target_scene == null:

		push_warning("BootcampRange: training_target_scene is null, cannot respawn target")

		return

	

	# Instantiate new target

	var new_target := training_target_scene.instantiate() as TrainingTarget

	if new_target == null:

		push_warning("BootcampRange: Failed to instantiate training_target_scene")

		return

	

	# Set spawn transform

	new_target.global_transform = spawn_transform

	

	# Add to Range as child

	add_child(new_target)

	

	# Store spawn transform and connect died signal

	_target_spawns[new_target] = spawn_transform

	

	# Disconnect previous connection if exists

	if new_target in _connected_targets:

		var old_callable = _connected_targets[new_target]

		if new_target.died.is_connected(old_callable):

			new_target.died.disconnect(old_callable)

	

	# Create and store new callable

	var new_callable = func(killer: Node): _on_target_died(killer, spawn_transform)

	_connected_targets[new_target] = new_callable

	new_target.died.connect(new_callable)



func _process(_delta: float) -> void:

	if InputMap.has_action("reset_range") and Input.is_action_just_pressed("reset_range"):

		reset_range()



func reset_range() -> void:

	# Prevent multiple simultaneous resets

	if _is_resetting:

		return

	_is_resetting = true

	

	# 1) Reset HUD stats if available

	if _hud and _hud.has_method("reset_stats"):

		_hud.reset_stats()

	

	# 2) Remove existing targets under this Range

	#    (targets are in group "training_target")

	for node in get_tree().get_nodes_in_group("training_target"):

		if self.is_ancestor_of(node):

			# Clean up connection tracking

			if node in _connected_targets:

				_connected_targets.erase(node)

			node.queue_free()

	

	# To avoid reusing stale keys, clear the dictionary keys;

	# we will reconstruct it from transforms.

	var spawn_transforms: Array[Transform3D] = []

	for spawn_transform_value in _target_spawns.values():

		spawn_transforms.append(spawn_transform_value)

	_target_spawns.clear()

	

	# 3) Respawn targets at the stored transforms

	# Note: we use call_deferred here to ensure queue_free() completes first.

	call_deferred("_respawn_targets", spawn_transforms)

	

	# Reset flag will be cleared after respawn completes



func _respawn_targets(spawn_transforms: Array[Transform3D]) -> void:

	if training_target_scene == null:

		return

	

	for spawn_tr in spawn_transforms:

		var t := training_target_scene.instantiate() as TrainingTarget

		if t == null:

			continue

		

		t.global_transform = spawn_tr

		add_child(t)

		

		if not t.is_in_group("training_target"):

			t.add_to_group("training_target")

		

		# Restore spawn record in dictionary for future resets

		_target_spawns[t] = spawn_tr

		

		# Disconnect previous connection if exists

		if t in _connected_targets:

			var old_callable = _connected_targets[t]

			if t.died.is_connected(old_callable):

				t.died.disconnect(old_callable)

		

		# Create and store new callable

		var new_callable = func(killer: Node): _on_target_died(killer, spawn_tr)

		_connected_targets[t] = new_callable

		t.died.connect(new_callable)

	

	# Reset is complete

	_is_resetting = false
