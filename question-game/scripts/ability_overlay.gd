extends CanvasLayer

@export_range(0.0, 1.0, 0.05) var dim_strength := 0.7
@export var duration := 3.0
@export var items_per_wave := 3
@export var wave_interval := 0.7
@export_range(0.5, 2.0, 0.1) var throw_intensity := 1.0
@export var item_size := 110

@onready var dim: ColorRect = $Dim
@onready var ability_label: Label = $AbilityLabel

var _spawning := true


func show_ability(character: Dictionary) -> void:
	get_tree().paused = true
	var ability: Dictionary = character.get("ability", {})
	ability_label.text = "%s\n%s" % [ability.get("name", ""), ability.get("description", "")]
	ability_label.pivot_offset = ability_label.size / 2.0
	ability_label.scale = Vector2(0.5, 0.5)
	ability_label.modulate.a = 0.0

	var fade_in := create_tween().set_parallel()
	fade_in.tween_property(dim, "modulate:a", dim_strength, 0.3)
	fade_in.tween_property(ability_label, "modulate:a", 1.0, 0.3)
	fade_in.tween_property(ability_label, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_spawn_waves(_load_ulta_textures(character.get("id", "")))

	await get_tree().create_timer(duration).timeout
	_spawning = false
	var fade_out := create_tween().set_parallel()
	fade_out.tween_property(dim, "modulate:a", 0.0, 0.3)
	fade_out.tween_property(ability_label, "modulate:a", 0.0, 0.3)
	await fade_out.finished
	get_tree().paused = false
	queue_free()


func _load_ulta_textures(char_id: String) -> Array:
	var textures: Array = []
	var dir := DirAccess.open("res://assets/characters/%s/ulta" % char_id)
	if dir == null:
		return textures
	for file_name in dir.get_files():
		if file_name.ends_with(".png"):
			textures.append(load(dir.get_current_dir() + "/" + file_name))
	return textures


func _spawn_waves(textures: Array) -> void:
	if textures.is_empty():
		return
	var screen := get_viewport().get_visible_rect().size
	while _spawning:
		for i in items_per_wave:
			if not _spawning:
				return
			_spawn_item(textures[randi() % textures.size()], screen)
		await get_tree().create_timer(wave_interval).timeout


func _spawn_item(texture: Texture2D, screen: Vector2) -> void:
	var item := TextureRect.new()
	item.texture = texture
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.size = Vector2(item_size, item_size)
	item.pivot_offset = item.size / 2.0
	item.rotation = randf_range(-0.3, 0.3)
	item.position = Vector2(
		randf_range(screen.x * 0.1, screen.x * 0.9 - item_size),
		screen.y + item_size
	)
	add_child(item)

	var peak_y: float = clampf(
		randf_range(screen.y * 0.15, screen.y * 0.5) / throw_intensity,
		0.0, screen.y
	)
	var up_time := randf_range(0.45, 0.6) / throw_intensity
	var down_time := randf_range(0.5, 0.7) / throw_intensity

	var toss := create_tween()
	toss.tween_property(item, "position:y", peak_y, up_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	toss.tween_property(item, "position:y", screen.y + item_size, down_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	toss.tween_callback(item.queue_free)

	var spin := create_tween()
	spin.tween_property(item, "rotation", -item.rotation, up_time + down_time)
