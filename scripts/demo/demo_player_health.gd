extends Damageable

@export var block_damage_scale: float = 0.4  # damage multiplier while blocking (40% damage taken)

@export var player_path: NodePath

var _player: FeelPlayer = null


func _ready() -> void:
	if player_path != NodePath():
		_player = get_node(player_path) as FeelPlayer
	else:
		_player = get_parent() as FeelPlayer
	
	if _player == null:
		push_warning("demo_player_health: Could not find FeelPlayer reference")


func apply_damage(amount: float, killer: Node = null) -> bool:
	var scaled := amount
	
	if _player and _player.is_blocking():
		scaled *= block_damage_scale
	
	_current_health -= scaled
	
	if _current_health <= 0.0:
		emit_signal("died", killer)
		
		if killer and killer.has_signal("kill_confirmed"):
			killer.emit_signal("kill_confirmed", self)
		
		queue_free()
		return true  # Return true if killed
	
	return false  # Return false if still alive



