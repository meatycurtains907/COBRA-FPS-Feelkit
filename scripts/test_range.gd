extends Node3D

@onready var player: FeelPlayer = $FeelPlayer

@onready var hud: FeelHUD = $HUD

func _ready() -> void:

    # Wait a frame to ensure weapon is fully initialized

    await get_tree().process_frame

    var weapon = player.weapon_rig.active_weapon

    if weapon != null:

        hud.connect_weapon(weapon)

    else:

        push_error("TestRange: Could not find active weapon from player.weapon_rig")
