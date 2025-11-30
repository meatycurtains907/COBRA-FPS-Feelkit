extends Node3D



func _ready() -> void:

	var timer: Timer = $LifetimeTimer as Timer

	if timer != null:

		timer.timeout.connect(queue_free)



