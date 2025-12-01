extends Node3D

class_name MagicShowcase

@export var player_path: NodePath = NodePath("FeelPlayer")
@export var hud_path: NodePath = NodePath("HUD")
@export var magic_hand_path: NodePath

@onready var _sword_scene: PackedScene = preload("res://scenes/weapons/SwordModel.tscn")

var _player: FeelPlayer = null
var _hud: FeelHUD = null
var _magic_hand: Node3D = null

var _weapon: Node3D = null
var _rifle_model: Node3D = null

var _hud_title_label: Label = null
var _hud_controls_label: Label = null
var _hud_block_label: Label = null
var _hud_block_tint: ColorRect = null

func _ready() -> void:
	_player = get_node_or_null(player_path)
	_hud = get_node_or_null(hud_path)
	
	if _player and _hud:
		# Wait a frame to ensure weapon is fully initialized
		await get_tree().process_frame
		
		# Resolve magic hand node
		if _player and magic_hand_path != NodePath(""):
			_magic_hand = _player.get_node_or_null(magic_hand_path) as Node3D
		
		# Resolve weapon and rifle model references
		if _player:
			_weapon = _player.get_node_or_null("RecoilPivot/Camera3D/WeaponRig/Weapon") as Node3D
			if _weapon:
				_rifle_model = _weapon.get_node_or_null("RifleModel") as Node3D
		
		# Configure projectile weapon for magic showcase
		_apply_projectile_config()
		
		# Wire magic hand as muzzle for projectiles
		_setup_magic_hand_casting()
		
		_connect_weapon_to_hud()
		
		# Optional: if HUD has set_prompt, give a hint
		if _hud.has_method("set_prompt"):
			_hud.set_prompt("Use WASD + Mouse to move and shoot. Magic projectiles fire visible orbs that arc toward targets.")
		
		# Set title and mode label
		if _hud:
			_hud.set_title("Magic & Melee Showcase")
			_hud.set_mode_label("Mode: Magic / Melee")
		
		# Hide stats panel for clean magic showcase
		if _hud and _hud.has_method("set_stats_visible"):
			_hud.set_stats_visible(false)
		
		# Cache HUD nodes and apply magic-specific overrides
		if _hud:
			_cache_magic_hud_nodes()
			_apply_magic_hud_overrides()
		
		# Make sure the base setup is done first
		await get_tree().process_frame
		await get_tree().process_frame
		
		# --- MAGIC SWORD SETUP START ---
		
		# 1) Spawn SwordWeapon as a child of Weapon
		_spawn_sword_weapon()
		
		# 2) Hide RifleModel in this showcase so only the sword is visible
		if _player and _player.weapon_rig:
			var weapon := _player.weapon_rig.get_node_or_null("Weapon") as Node3D
			if weapon:
				var rifle_model := weapon.get_node_or_null("RifleModel") as Node3D
				if rifle_model:
					rifle_model.hide()
		
		# 3) Nudge MeleeWeapon to resolve the sword node
		if _player:
			var melee_weapon := _player.get_node_or_null("RecoilPivot/Camera3D/MeleeWeapon")
			if melee_weapon:
				if "_resolve_sword_node" in melee_weapon:
					melee_weapon._resolve_sword_node()
				
				# Assign sword SFX overrides for magic showcase
				if "swing_sfx_override" in melee_weapon:
					melee_weapon.swing_sfx_override = load("res://Sounds/sword-slice-393847.mp3")
				if "world_hit_sfx_override" in melee_weapon:
					melee_weapon.world_hit_sfx_override = load("res://Sounds/sword-clashhit-393837.mp3")
				if "dummy_hit_sfx_override" in melee_weapon:
					melee_weapon.dummy_hit_sfx_override = load("res://Sounds/sword-blade-slicing-flesh-352708.mp3")
		
		# --- MAGIC SWORD SETUP END ---

func _apply_projectile_config() -> void:
	if not _player or not _player.weapon_rig or not _player.weapon_rig.active_weapon:
		return
	
	var weapon := _player.weapon_rig.active_weapon as WeaponBase
	if weapon:
		# Assign projectile scene for magic showcase
		weapon.projectile_scene = preload("res://scenes/weapons/Projectile.tscn")
		# Set MagicArcane config
		weapon.config = preload("res://config/Rifle_MagicArcane.tres")
	
	# Apply MagicArcane feel config to player
	if _player:
		_player.feel_config = preload("res://config/Feel_MagicArcane.tres")
		if _player.has_method("_apply_feel_config"):
			_player._apply_feel_config()
	
	# Apply MagicArcane crosshair config to HUD
	if _hud:
		_hud.crosshair_config = preload("res://config/Crosshair_MagicArcane.tres")
		if _hud.has_method("_apply_crosshair_config"):
			_hud._apply_crosshair_config()

func _connect_weapon_to_hud() -> void:
	if not _player or not _hud:
		return
	
	var weapon = _player.weapon_rig.active_weapon
	if weapon != null:
		_hud.connect_weapon(weapon)
		
		# Connect magic cast flash to weapon fired signal
		if _hud and weapon and _hud.has_method("show_magic_cast_flash"):
			if not weapon.is_connected("fired", Callable(_hud, "show_magic_cast_flash")):
				weapon.connect("fired", Callable(_hud, "show_magic_cast_flash"))
	else:
		push_warning("MagicShowcase: Could not find active weapon from player.weapon_rig")

func _cache_magic_hud_nodes() -> void:
	if not _hud:
		return
	
	_hud_title_label = _hud.get_node_or_null("TitleLabel") as Label
	_hud_controls_label = _hud.get_node_or_null("ControlsLabel") as Label
	_hud_block_label = _hud.get_node_or_null("BlockLabel") as Label
	_hud_block_tint = _hud.get_node_or_null("BlockTint") as ColorRect

func _apply_magic_hud_overrides() -> void:
	if not _hud:
		return
	
	# Title and mode label are now set via helpers above, no need to override here
	
	# 2) Magic-specific controls text (multi-line)
	if _hud_controls_label:
		var magic_controls_text := ""
		magic_controls_text += "WASD: Move   Space: Jump   Ctrl: Crouch   Shift: Sprint\n"
		magic_controls_text += "LMB: Melee (Sword)   RMB: Cast Fireball   Q: Block (reduces incoming damage)"
		_hud_controls_label.text = magic_controls_text
	
	# 3) Magic description via prompt
	if _hud.has_method("set_prompt"):
		_hud.set_prompt(
			"Use WASD + Mouse to move and swing. RMB casts visible magic orbs that arc toward targets."
		)
	
	# 4) Hide ammo label in magic mode
	if _hud and _hud.has_node("AmmoLabel"):
		var ammo_label := _hud.get_node("AmmoLabel") as Label
		if ammo_label:
			ammo_label.visible = false
	
	# 5) Block HUD hint: more explicit + slightly more arcane tint
	if _hud_block_label:
		_hud_block_label.text = "BLOCKING (Q)"
	
	if _hud_block_tint:
		# Slightly stronger cyan/arcane tint than the FPS version
		_hud_block_tint.color = Color(0.25, 0.65, 1.0, 0.18)

func _spawn_sword_weapon() -> Node3D:
	if _player == null:
		return null
	
	var weapon_rig := _player.weapon_rig
	if weapon_rig == null:
		return null
	
	var weapon := weapon_rig.get_node_or_null("Weapon") as Node3D
	if weapon == null:
		return null
	
	# Reuse existing SwordWeapon if already present
	var existing := weapon.get_node_or_null("SwordWeapon") as Node3D
	if existing:
		existing.show()
		return existing
	
	if _sword_scene == null:
		return null
	
	var sword_weapon := _sword_scene.instantiate() as Node3D
	sword_weapon.name = "SwordWeapon"
	weapon.add_child(sword_weapon)
	
	# 1) Start by matching RifleModel's transform (same anchor / hierarchy)
	var rifle_model := weapon.get_node_or_null("RifleModel") as Node3D
	if rifle_model:
		sword_weapon.transform = rifle_model.transform
	else:
		sword_weapon.transform = Transform3D.IDENTITY
	
	# 2) VISIBILITY FIX — nudge the sword so it sits clearly in front of the camera.
	#
	# The problem right now is that the SwordModel's mesh is probably centered
	# around its origin, so when we drop it exactly where the rifle's pivot is,
	# most of it lives inside the camera's near-clip region and gets clipped.
	#
	# We keep the same parent/pivot, but:
	#   - push it a bit forward along local -Z
	#   - raise it slightly so it's more in view
	#   - angle it toward the camera so you can see more of the blade
	#
	# You can tweak these numbers later, but this should make it *visible*.
	sword_weapon.translate_object_local(Vector3(0.0, -0.05, -0.60))
	sword_weapon.rotate_object_local(Vector3(0, 1, 0), deg_to_rad(-10.0))
	sword_weapon.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(-15.0))
	
	return sword_weapon

func _setup_magic_hand_casting() -> void:
	if not _player or not _magic_hand or not _player.weapon_rig:
		return
	
	var weapon := _player.weapon_rig.active_weapon
	if not weapon:
		return
	
	# Update the public path for bookkeeping
	weapon.muzzle_node_path = _player.get_path_to(_magic_hand)
	
	# Also override the cached muzzle node so projectiles spawn from MagicHandL
	# NOTE: _muzzle_node is an internal field on WeaponBase; we intentionally poke it here
	# for this demo scene only.
	weapon._muzzle_node = _magic_hand
