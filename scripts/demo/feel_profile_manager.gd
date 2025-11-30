extends Node

class_name FeelProfileManager

signal profile_changed(profile_name: String)

@export var player_path: NodePath

@export var hud_path: NodePath

var _player: Node = null

var _hud: Node = null

# 0 = Twitchy, 1 = WW2, 2 = Arcade

var _current_index: int = 0

func get_current_profile_name() -> String:
	if _current_index >= 0 and _current_index < _profiles.size():
		var profile := _profiles[_current_index]
		if "name" in profile:
			return str(profile["name"])
	return "Custom/Unknown"

var _profiles: Array[Dictionary] = []

func _init() -> void:

	pass

func _ready() -> void:

	# Wait a frame to ensure all nodes are in the tree, then resolve nodes

	call_deferred("_resolve_nodes")

func _resolve_nodes() -> void:

	if player_path != NodePath(""):

		_player = get_node_or_null(player_path)

		if _player == null:

			# Try alternative: search by group first (more reliable)

			var player_search = get_tree().get_first_node_in_group("player")

			if player_search:

				_player = player_search

			else:

				push_warning("FeelProfileManager: Could not find player at path: %s or in 'player' group" % player_path)

	else:

		push_warning("FeelProfileManager: player_path is empty!")

	if hud_path != NodePath(""):

		_hud = get_node_or_null(hud_path)

		if _hud == null:

			# Try alternative: search by class name first

			var scene = get_tree().current_scene

			if scene:

				_find_hud_recursive(scene)

			if _hud == null:

				# Try group as last resort

				var hud_search = get_tree().get_first_node_in_group("hud")

				if hud_search:

					_hud = hud_search

				else:

					push_warning("FeelProfileManager: Could not find HUD at path: %s or via search" % hud_path)

	else:

		push_warning("FeelProfileManager: hud_path is empty!")

	# Load profiles

	_profiles = [

		{

			"name": "Twitchy",

			"feel": preload("res://config/Feel_Twitchy.tres"),

			"weapon": preload("res://config/Rifle_Twitchy.tres"),

			"crosshair": preload("res://config/Crosshair_Twitchy.tres"),

		},

		{

			"name": "WW2",

			"feel": preload("res://config/Feel_WW2.tres"),

			"weapon": preload("res://config/Rifle_WW2.tres"),

			"crosshair": preload("res://config/Crosshair_WW2.tres"),

		},

		{

			"name": "Arcade",

			"feel": preload("res://config/Feel_Arcade.tres"),

			"weapon": preload("res://config/Rifle_Arcade.tres"),

			"crosshair": preload("res://config/Crosshair_Arcade.tres"),

		},

		{

			"name": "Exploration",

			"feel": preload("res://config/Feel_Exploration.tres"),

			"weapon": preload("res://config/SMG_Twitchy.tres"),

			"crosshair": preload("res://config/Crosshair_Twitchy.tres"),

		},

	]

	if not _profiles.is_empty():

		_apply_profile(_current_index)

	else:

		push_error("FeelProfileManager: No profiles loaded!")

	# Ensure processing is enabled

	set_process(true)

func _find_hud_recursive(node: Node) -> void:

	if _hud != null:

		return  # Already found

	if node is FeelHUD:

		_hud = node

		return

	for child in node.get_children():

		_find_hud_recursive(child)

func _process(_delta: float) -> void:

	# Check if input action exists (for debugging)

	if not InputMap.has_action("switch_profile"):

		# Only print once to avoid spam

		if not has_meta("_warned_no_action"):

			push_warning("FeelProfileManager: Input action 'switch_profile' not found in InputMap!")

			set_meta("_warned_no_action", true)

		return

	if Input.is_action_just_pressed("switch_profile"):

		_cycle_profile()

func _cycle_profile() -> void:

	if _profiles.is_empty():

		return

	_current_index = (_current_index + 1) % _profiles.size()

	_apply_profile(_current_index)

func _apply_profile(index: int) -> void:

	if _profiles.is_empty():

		return

	var profile := _profiles[index]

	var profile_name: String = profile.get("name", "Unknown")

	var feel = profile.get("feel", null)

	var weapon_cfg = profile.get("weapon", null)

	var crosshair_cfg = profile.get("crosshair", null)

	# 1) Player feel config

	if _player and feel != null:

		# FeelPlayer is expected here; direct property access is fine.

		_player.feel_config = feel

		if _player.has_method("_apply_feel_config"):

			_player._apply_feel_config()

	# 2) Weapon config (active weapon via WeaponRig.active_weapon)

	if _player and weapon_cfg != null:

		var weapon = _get_active_weapon(_player)

		if weapon:

			if weapon.has_method("apply_config"):

				weapon.apply_config(weapon_cfg)

			else:

				weapon.config = weapon_cfg

	# 3) Crosshair config on HUD

	if _hud and crosshair_cfg != null:

		_hud.crosshair_config = crosshair_cfg

		if _hud.has_method("_apply_crosshair_config"):

			_hud._apply_crosshair_config()

	# 4) HUD profile label

	if _hud and _hud.has_method("set_profile_name"):

		_hud.set_profile_name(profile_name)

	# 5) Emit signal for profile change

	emit_signal("profile_changed", profile_name)

func _get_active_weapon(player: Node) -> Node:

	if player == null:

		return null

	# Expect FeelPlayer to expose `weapon_rig` with `active_weapon`

	var rig = player.weapon_rig

	if rig == null:

		return null

	return rig.active_weapon
