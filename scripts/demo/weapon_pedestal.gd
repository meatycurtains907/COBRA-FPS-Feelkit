extends Area3D

@export var weapon_kind: StringName = "smg"
@export var feel_showcase_path: NodePath

var _feel_showcase: Node = null
var _player_in_range: bool = false
var _prompt_label: Label3D = null

func _ready() -> void:
	_feel_showcase = get_node_or_null(feel_showcase_path)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Cache prompt label reference
	_prompt_label = get_node_or_null("PromptLabel") as Label3D
	if _prompt_label:
		_prompt_label.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		if _prompt_label:
			_prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if _prompt_label:
			_prompt_label.visible = false

func _process(_delta: float) -> void:
	if not _player_in_range:
		return
	if Input.is_action_just_pressed("interact") and _feel_showcase:
		if _feel_showcase.has_method("set_weapon_kind_from_pedestal"):
			_feel_showcase.set_weapon_kind_from_pedestal(weapon_kind)

