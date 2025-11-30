extends Node

class_name BootcampManager



enum Mode {

	FULL_TUTORIAL,

	RANGE_ONLY,

}



@export var mode: Mode = Mode.FULL_TUTORIAL



@export var player_path: NodePath

@export var hud_path: NodePath

@export var course_path: NodePath

@export var range_path: NodePath

@export var armory_spawn_path: NodePath

@export var range_spawn_path: NodePath



var _player: Node3D

var _hud: Node

var _course: Node

var _range: Node

var _armory_spawn: Node3D

var _range_spawn: Node3D



func _ready() -> void:

	print("BootcampManager: _ready() called")



	# Wait a frame to ensure all nodes are in the tree

	call_deferred("_resolve_nodes")



func _resolve_nodes() -> void:

	print("BootcampManager: _resolve_nodes() called")

	print("BootcampManager: Resolving paths - player_path: %s, hud_path: %s, course_path: %s, range_path: %s" % [player_path, hud_path, course_path, range_path])

	print("BootcampManager: Spawn paths - armory: %s, range: %s" % [armory_spawn_path, range_spawn_path])



	# Try to resolve from scene root (like FeelProfileManager)

	var scene_root = get_tree().current_scene

	if scene_root:

		print("BootcampManager: Scene root is: %s" % scene_root.name)

		if player_path != NodePath(""):

			_player = scene_root.get_node_or_null(player_path) as Node3D

		if hud_path != NodePath(""):

			_hud = scene_root.get_node_or_null(hud_path)

		if course_path != NodePath(""):

			_course = scene_root.get_node_or_null(course_path)

		if range_path != NodePath(""):

			_range = scene_root.get_node_or_null(range_path)

		if armory_spawn_path != NodePath(""):

			_armory_spawn = scene_root.get_node_or_null(armory_spawn_path) as Node3D

		if range_spawn_path != NodePath(""):

			_range_spawn = scene_root.get_node_or_null(range_spawn_path) as Node3D



	if _player == null:

		push_warning("BootcampManager: Could not find player at path: %s" % player_path)

	else:

		print("BootcampManager: Found player: %s" % _player.name)



	if _hud == null:

		push_warning("BootcampManager: Could not find HUD at path: %s" % hud_path)

	else:

		print("BootcampManager: Found HUD: %s" % _hud.name)



	if _course == null:

		push_warning("BootcampManager: Could not find course at path: %s" % course_path)

	else:

		print("BootcampManager: Found course: %s" % _course.name)



	if _range == null:

		push_warning("BootcampManager: Could not find range at path: %s" % range_path)

	else:

		print("BootcampManager: Found range: %s" % _range.name)



	if _armory_spawn == null:

		push_warning("BootcampManager: Could not find armory spawn at path: %s" % armory_spawn_path)

	else:

		print("BootcampManager: Found armory spawn at: %s" % _armory_spawn.global_transform.origin)



	if _range_spawn == null:

		push_warning("BootcampManager: Could not find range spawn at path: %s" % range_spawn_path)

	else:

		print("BootcampManager: Found range spawn at: %s" % _range_spawn.global_transform.origin)



	_apply_mode_initial()



	# Ensure processing is enabled

	set_process(true)



func _process(_delta: float) -> void:

	if InputMap.has_action("reset_bootcamp") and Input.is_action_just_pressed("reset_bootcamp"):

		print("BootcampManager: reset_bootcamp pressed")

		reset_bootcamp()

	if InputMap.has_action("skip_bootcamp") and Input.is_action_just_pressed("skip_bootcamp"):

		print("BootcampManager: skip_bootcamp pressed")

		# From FULL_TUTORIAL, skip straight to range-only

		if mode == Mode.FULL_TUTORIAL:

			mode = Mode.RANGE_ONLY

			_apply_mode_change()

		else:

			print("BootcampManager: skip_bootcamp pressed but not in FULL_TUTORIAL mode (current: %d)" % mode)



func _apply_mode_initial() -> void:

	# Called once in _ready()

	_apply_mode_change()



func _apply_mode_change() -> void:

	print("BootcampManager: Applying mode: %d (0=FULL_TUTORIAL, 1=RANGE_ONLY)" % mode)

	if mode == Mode.FULL_TUTORIAL:

		print("BootcampManager: Setting FULL_TUTORIAL mode")

		_enable_course(true)

		_teleport_to_armory()

	elif mode == Mode.RANGE_ONLY:

		print("BootcampManager: Setting RANGE_ONLY mode")

		_enable_course(false)

		_teleport_to_range()

	_reset_ui_and_range()



func reset_bootcamp() -> void:

	# Re-run the current mode from the beginning

	_apply_mode_change()



func _enable_course(enabled: bool) -> void:

	print("BootcampManager: _enable_course(%s) called - course: %s" % [enabled, _course != null])

	if _course and _course.has_method("set_tutorial_enabled"):

		_course.set_tutorial_enabled(enabled)

		print("BootcampManager: Course tutorial_enabled set to: %s" % enabled)

	else:

		if _course == null:

			print("BootcampManager: ERROR - _course is null, cannot enable/disable")

		else:

			print("BootcampManager: ERROR - _course does not have set_tutorial_enabled method")



func _teleport_to_armory() -> void:

	if not _player or not _armory_spawn:

		if not _player:

			push_warning("BootcampManager: Cannot teleport to armory - player is null")

		if not _armory_spawn:

			push_warning("BootcampManager: Cannot teleport to armory - armory_spawn is null")

		return

	print("BootcampManager: Teleporting player to armory at: %s" % _armory_spawn.global_transform.origin)

	_player.global_transform = _armory_spawn.global_transform



	# Clear movement velocity

	if _player is CharacterBody3D:

		_player.velocity = Vector3.ZERO

		print("BootcampManager: Player velocity cleared")

	print("BootcampManager: Player new position: %s" % _player.global_transform.origin)



func _teleport_to_range() -> void:

	print("BootcampManager: _teleport_to_range() called - player: %s, range_spawn: %s" % [_player != null, _range_spawn != null])

	if not _player or not _range_spawn:

		if not _player:

			print("BootcampManager: ERROR - Cannot teleport to range - player is null")

		if not _range_spawn:

			print("BootcampManager: ERROR - Cannot teleport to range - range_spawn is null")

		return

	print("BootcampManager: Teleporting player to range at: %s" % _range_spawn.global_transform.origin)

	_player.global_transform = _range_spawn.global_transform



	if _player is CharacterBody3D:

		_player.velocity = Vector3.ZERO

		print("BootcampManager: Player velocity cleared")

	print("BootcampManager: Player new position: %s" % _player.global_transform.origin)



func _reset_ui_and_range() -> void:

	print("BootcampManager: Resetting UI and range")

	if _hud:

		if _hud.has_method("reset_bootcamp_ui"):

			_hud.reset_bootcamp_ui()

			print("BootcampManager: Called HUD.reset_bootcamp_ui()")

		else:

			if _hud.has_method("reset_stats"):

				_hud.reset_stats()

			if _hud.has_method("set_prompt"):

				_hud.set_prompt("")

			print("BootcampManager: Reset HUD stats and prompt manually")

	else:

		push_warning("BootcampManager: HUD is null, cannot reset UI")



	if _range and _range.has_method("reset_range"):

		_range.reset_range()

		print("BootcampManager: Called Range.reset_range()")

	else:

		if _range == null:

			print("BootcampManager: ERROR - Range is null, cannot reset")

		elif not _range.has_method("reset_range"):

			print("BootcampManager: ERROR - Range does not have reset_range method")
