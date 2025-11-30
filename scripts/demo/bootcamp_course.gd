extends Node3D

@onready var hud: FeelHUD = $"../../HUD"

@onready var station1_trigger: Area3D = $Station1_Walk/Trigger

@onready var station2_trigger: Area3D = $Station2_Jump/Trigger

@onready var station3_trigger: Area3D = $Station3_Crouch/Trigger

var _stage: int = 0

var tutorial_enabled: bool = true



func _ready() -> void:

	# Connect triggers

	if station1_trigger != null:

		if not station1_trigger.body_entered.is_connected(_on_station1_body_entered):

			station1_trigger.body_entered.connect(_on_station1_body_entered)

	if station2_trigger != null:

		if not station2_trigger.body_entered.is_connected(_on_station2_body_entered):

			station2_trigger.body_entered.connect(_on_station2_body_entered)

	if station3_trigger != null:

		if not station3_trigger.body_entered.is_connected(_on_station3_body_entered):

			station3_trigger.body_entered.connect(_on_station3_body_entered)

	# Initialize

	_stage = 0

	if hud != null:

		hud.set_prompt("Walk to the marker ahead.")



func _is_player(body: Node) -> bool:

	return body.is_in_group("player")



func set_tutorial_enabled(enabled: bool) -> void:

	tutorial_enabled = enabled



	if station1_trigger:

		station1_trigger.monitoring = enabled

	if station2_trigger:

		station2_trigger.monitoring = enabled

	if station3_trigger:

		station3_trigger.monitoring = enabled



func _on_station1_body_entered(body: Node3D) -> void:

	if not tutorial_enabled:

		return

	if not _is_player(body) or _stage != 0:

		return

	_stage = 1

	if hud != null:

		hud.set_prompt("Jump over the barrier ahead.")



func _on_station2_body_entered(body: Node3D) -> void:

	if not tutorial_enabled:

		return

	if not _is_player(body) or _stage != 1:

		return

	_stage = 2

	if hud != null:

		hud.set_prompt("Crouch under the low beam.")



func _on_station3_body_entered(body: Node3D) -> void:

	if not tutorial_enabled:

		return

	if not _is_player(body) or _stage != 2:

		return

	_stage = 3

	if hud != null:

		hud.set_prompt("Movement training complete. Proceed to the range.")

