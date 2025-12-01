extends Node3D

class_name FeelShowcase

@export var player_path: NodePath = NodePath("FeelPlayer")
@export var hud_path: NodePath = NodePath("HUD")
@export var profile_manager_path: NodePath = NodePath("FeelProfileManager")

var _player: FeelPlayer = null
var _hud: FeelHUD = null
var _profile_manager: FeelProfileManager = null

const WEAPON_KIND_SMG: StringName = "smg"
const WEAPON_KIND_RIFLE: StringName = "rifle"
const WEAPON_KIND_SHOTGUN: StringName = "shotgun"

var _current_weapon_kind: StringName = WEAPON_KIND_SMG

func _ready() -> void:
	_player = get_node_or_null(player_path)
	_hud = get_node_or_null(hud_path)
	_profile_manager = get_node_or_null(profile_manager_path)
	
	if _profile_manager:
		_profile_manager.profile_changed.connect(_on_profile_changed)
	
	if _player and _hud:
		# Wait frames to ensure weapon is fully initialized and profile manager has set initial profile
		await get_tree().process_frame
		await get_tree().process_frame  # Wait for profile manager deferred call
		await get_tree().process_frame  # Wait one more to ensure profile manager has finished
		
		# Set default weapon to SMG for FeelShowcase
		_current_weapon_kind = WEAPON_KIND_SMG
		_apply_current_weapon_for_profile()
		
		_connect_weapon_to_hud()
		
		# Optional: if HUD has set_prompt, give a tiny hint
		if _hud.has_method("set_prompt"):
			_hud.set_prompt("Use WASD + Mouse to move and shoot. Press F1 to toggle feel presets.")
		
		# Set title and mode label
		if _hud:
			_hud.set_title("FPS Feel Showcase")
			_hud.set_mode_label("Mode: Gunplay & Movement")
		
		# Hide stats panel for clean feel showcase
		if _hud and _hud.has_method("set_stats_visible"):
			_hud.set_stats_visible(false)
		
		# Sync crosshair state for initial profile
		if _profile_manager != null and _hud != null:
			_on_profile_changed(_profile_manager.get_current_profile_name())

func _on_profile_changed(profile_name: String) -> void:
	_current_weapon_kind = WEAPON_KIND_SMG
	_apply_current_weapon_for_profile(profile_name)
	
	# Control crosshair visibility based on profile
	var show_crosshair := profile_name != "Exploration"
	if _hud != null and _hud.has_method("set_crosshair_enabled"):
		_hud.set_crosshair_enabled(show_crosshair)
	
	# Control fire and weapon visibility for Exploration preset
	var is_exploration := (profile_name == "Exploration")
	if _player != null:
		_player.enable_fire = not is_exploration
		if _player.weapon_rig != null:
			_player.weapon_rig.visible = not is_exploration

func _connect_weapon_to_hud() -> void:
	if not _player or not _hud:
		return
	
	var weapon = _player.weapon_rig.active_weapon
	if weapon != null:
		_hud.connect_weapon(weapon)
	else:
		push_warning("FeelShowcase: Could not find active weapon from player.weapon_rig")

func _get_weapon_config_for_profile_and_kind(profile_name: String, kind: StringName) -> WeaponConfig:
	if profile_name.is_empty():
		return null
	
	var prefix := ""
	match kind:
		WEAPON_KIND_SMG:
			prefix = "SMG"
		WEAPON_KIND_SHOTGUN:
			prefix = "Shotgun"
		WEAPON_KIND_RIFLE:
			prefix = "Rifle"
		_:
			prefix = "SMG"
	
	var res_path := "res://config/%s_%s.tres" % [prefix, profile_name]
	var cfg := load(res_path) as WeaponConfig
	
	# Fallback: Exploration profile doesn't have its own weapon configs
	# It uses Twitchy configs (since it's non-combat, weapon tuning doesn't matter)
	if cfg == null and profile_name == "Exploration":
		var fallback_path := "res://config/%s_Twitchy.tres" % prefix
		cfg = load(fallback_path) as WeaponConfig
	
	return cfg

func _apply_current_weapon_for_profile(profile_name: String = "") -> void:
	if not _player or not _player.weapon_rig:
		return
	
	var weapon := _player.weapon_rig.active_weapon as WeaponBase
	if not weapon:
		return
	
	if profile_name.is_empty() and _profile_manager:
		profile_name = _profile_manager.get_current_profile_name()
	
	if profile_name.is_empty():
		return
	
	var cfg := _get_weapon_config_for_profile_and_kind(profile_name, _current_weapon_kind)
	if cfg:
		if weapon.has_method("apply_config"):
			weapon.apply_config(cfg)
		else:
			weapon.config = cfg
	else:
		push_warning("FeelShowcase: Could not load weapon config for profile '%s' kind '%s'" % [profile_name, _current_weapon_kind])

func set_weapon_kind(kind: StringName) -> void:
	_current_weapon_kind = kind
	_apply_current_weapon_for_profile()

func set_weapon_kind_from_pedestal(kind: StringName) -> void:
	set_weapon_kind(kind)
