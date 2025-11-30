extends Area3D

@export var weapon_config: WeaponConfig
@export var display_name: String = "Weapon"
@export_multiline var description: String = ""

var _player: FeelPlayer = null

@onready var prompt_label: Label3D = $PromptLabel

func _ready() -> void:
	# Connect body entered/exited signals
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	# Initialize prompt label
	if prompt_label != null:
		prompt_label.text = "Press E to equip %s" % display_name
		prompt_label.visible = false

func _on_body_entered(body: Node3D) -> void:
	# Check if it's the player
	if body is FeelPlayer:
		_player = body as FeelPlayer
		if prompt_label != null:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	# Clear player reference if they left
	if body == _player:
		_player = null
		if prompt_label != null:
			prompt_label.visible = false

func _process(_delta: float) -> void:
	# Check for interact input when player is in range
	if _player != null and Input.is_action_just_pressed("interact"):
		# Find the Weapon node using the path specified in task
		var weapon: WeaponBase = _player.get_node("RecoilPivot/Camera3D/WeaponRig/Weapon") as WeaponBase
		
		if weapon != null and weapon_config != null:
			# Swap the weapon config using apply_config if available
			if weapon.has_method("apply_config"):
				weapon.apply_config(weapon_config)
			else:
				# Fallback for any future weapon types
				weapon.config = weapon_config
			print("Equipped: %s" % display_name)
		else:
			if weapon == null:
				push_warning("ArmoryWeaponSpot: Could not find Weapon node on player")
			if weapon_config == null:
				push_warning("ArmoryWeaponSpot: weapon_config is null")

