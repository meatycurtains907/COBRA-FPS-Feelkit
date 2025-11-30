extends Damageable

class_name TrainingTarget



@export var destroy_sfx: AudioStream = null

@export var destroy_vfx_scene: PackedScene = null



@onready var _front_panel: MeshInstance3D = get_node_or_null("Visual/FrontPanel") as MeshInstance3D

var _flash_time: float = 0.0

var _front_panel_default_color: Color = Color.WHITE



func _ready() -> void:

	add_to_group("training_target")

	

	if not died.is_connected(_on_died):

		died.connect(_on_died)

	

	# Set up per-instance material override for hit flash

	if _front_panel and _front_panel.material_override == null:

		var base_mat: Material = _front_panel.get_surface_override_material(0)

		if base_mat == null and _front_panel.mesh:

			base_mat = _front_panel.mesh.surface_get_material(0)

		if base_mat:

			_front_panel.material_override = base_mat.duplicate()

	

	# Cache default color for flash reset (from material_override if set, otherwise from surface override)

	if _front_panel:

		var mat: StandardMaterial3D = null

		if _front_panel.material_override:

			mat = _front_panel.material_override as StandardMaterial3D

		elif _front_panel.get_surface_override_material(0):

			mat = _front_panel.get_surface_override_material(0) as StandardMaterial3D

		if mat:

			_front_panel_default_color = mat.albedo_color

	

	set_process(true)



func apply_damage(amount: float, killer: Node = null) -> bool:

	var was_killed := super.apply_damage(amount, killer)

	# Non-lethal hit (target still alive) → flash

	if not was_killed and _current_health > 0.0:

		_start_hit_flash()

	return was_killed



func _start_hit_flash() -> void:

	if _front_panel == null:

		return

	_flash_time = 0.12  # duration in seconds

	var mat := _front_panel.material_override as StandardMaterial3D

	if mat:

		mat.albedo_color = _front_panel_default_color.lightened(0.4)



func _process(delta: float) -> void:

	if _flash_time > 0.0:

		_flash_time -= delta

		if _flash_time <= 0.0 and _front_panel:

			var mat := _front_panel.material_override as StandardMaterial3D

			if mat:

				mat.albedo_color = _front_panel_default_color



func _on_died(_killer: Node) -> void:

	var spawn_position := global_transform.origin

	

	# Spawn SFX if destroy_sfx is set

	if destroy_sfx != null:

		var sfx_player := AudioStreamPlayer3D.new()

		sfx_player.stream = destroy_sfx

		sfx_player.global_position = spawn_position

		

		var root := get_tree().current_scene

		if root != null:

			root.add_child(sfx_player)

			sfx_player.play()

			sfx_player.finished.connect(sfx_player.queue_free)

	

	# Spawn VFX if destroy_vfx_scene is set

	if destroy_vfx_scene != null:

		var vfx := destroy_vfx_scene.instantiate() as Node3D

		if vfx != null:

			var root := get_tree().current_scene

			if root != null:

				root.add_child(vfx)

				vfx.global_transform.origin = spawn_position
