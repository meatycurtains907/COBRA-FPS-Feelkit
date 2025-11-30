extends Control

class_name DebugOverlay


@export var player_path: NodePath

@export var profile_manager_path: NodePath


@onready var _label: Label = $PanelContainer/MarginContainer/Label


var _player: FeelPlayer

var _profile_manager: FeelProfileManager


func _ready() -> void:
	visible = false
	# Wait a frame to ensure all nodes in the scene are ready
	call_deferred("_resolve_refs")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_debug_overlay"):
		visible = not visible

	if not visible:
		return

	if not is_instance_valid(_player) or not is_instance_valid(_profile_manager):
		_resolve_refs()

	var movement_state := "?"
	var spread_ratio := 0.0
	var recoil_offset := Vector2.ZERO
	var weapon_name := "None"
	var profile_name := "Unknown"
	var blocking := false

	if _player:
		movement_state = _player.get_movement_state()

		var weapon := _player.get_active_weapon()
		if weapon:
			if weapon.config:
				weapon_name = str(weapon.config.display_name)
			if weapon.has_method("get_spread_ratio"):
				spread_ratio = float(weapon.get_spread_ratio())

		if _player.recoil_pivot and _player.recoil_pivot.has_method("get_current_offset"):
			recoil_offset = _player.recoil_pivot.get_current_offset()
		
		if _player.has_method("is_blocking"):
			blocking = _player.is_blocking()

	if _profile_manager:
		profile_name = _profile_manager.get_current_profile_name()

	_label.text = ""
	_label.text += "COBRA Debug Overlay\n"
	_label.text += "-------------------\n"
	_label.text += "Movement: %s\n" % movement_state
	_label.text += "Blocking: %s\n" % ("Yes" if blocking else "No")
	_label.text += "Spread ratio: %.3f\n" % spread_ratio
	_label.text += "Recoil offset: (%.3f, %.3f)\n" % [recoil_offset.x, recoil_offset.y]
	_label.text += "Weapon: %s\n" % weapon_name
	_label.text += "Feel profile: %s\n" % profile_name


func _resolve_refs() -> void:
	var scene_root = get_tree().current_scene
	if scene_root:
		if player_path != NodePath(""):
			_player = scene_root.get_node_or_null(player_path) as FeelPlayer
		if profile_manager_path != NodePath(""):
			_profile_manager = scene_root.get_node_or_null(profile_manager_path) as FeelProfileManager
