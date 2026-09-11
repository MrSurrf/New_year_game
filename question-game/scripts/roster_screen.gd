extends Control

@onready var info_label: Label = $VBox/InfoLabel
@onready var grid: GridContainer = $VBox/Grid
@onready var selected_label: Label = $VBox/BottomBar/SelectedLabel
@onready var confirm_button: Button = $VBox/BottomBar/ConfirmButton

var selected_card: Button = null
var sprites := {}


func _ready() -> void:
	var skip_msg := GameState.begin_round()
	info_label.text = "Раунд %d. %s вызывает игрока: %s выбирает персонажа" % [
		GameState.round_number,
		GameState.team_label(GameState.challenging_team),
		GameState.team_label(GameState.answering_team),
	]
	if skip_msg != "":
		info_label.text = skip_msg + "\n" + info_label.text
	confirm_button.pressed.connect(_on_confirm_pressed)
	_build_cards()


func _build_cards() -> void:
	for ch in DataLoader.characters:
		var card := Button.new()
		card.custom_minimum_size = Vector2(230, 270)

		var vb := VBoxContainer.new()
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 8)
		card.add_child(vb)

		var holder := Control.new()
		holder.custom_minimum_size = Vector2(128, 128)
		holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(holder)

		var sprite := AnimatedSprite2D.new()
		var frames := SpriteFrames.new()
		frames.add_frame(&"default", load("res://assets/characters/%s/frame1.png" % ch["id"]))
		frames.add_frame(&"default", load("res://assets/characters/%s/frame2.png" % ch["id"]))
		frames.set_animation_speed(&"default", 3.0)
		sprite.frames = frames
		sprite.position = Vector2(64, 64)
		holder.add_child(sprite)
		sprites[card] = sprite

		var name_label := Label.new()
		name_label.text = ch["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(name_label)

		var ability_label := Label.new()
		ability_label.text = "%s: %s" % [ch["ability"]["name"], ch["ability"]["description"]]
		ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ability_label.custom_minimum_size = Vector2(210, 0)
		ability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(ability_label)

		card.pressed.connect(_on_card_pressed.bind(ch, card))
		card.mouse_entered.connect(_on_card_hover.bind(card, true))
		card.mouse_exited.connect(_on_card_hover.bind(card, false))
		grid.add_child(card)


func _on_card_pressed(ch: Dictionary, card: Button) -> void:
	GameState.current_character = ch
	if selected_card != null and selected_card != card:
		selected_card.modulate = Color.WHITE
		sprites[selected_card].stop()
		sprites[selected_card].frame = 0
	selected_card = card
	card.modulate = Color(0.7, 1.0, 0.7)
	sprites[card].play(&"default")
	selected_label.text = "Выбран: %s" % ch["name"]
	confirm_button.disabled = false


func _on_card_hover(card: Button, entered: bool) -> void:
	var sprite: AnimatedSprite2D = sprites[card]
	if entered:
		sprite.play(&"default")
	elif card != selected_card:
		sprite.stop()
		sprite.frame = 0


func _on_confirm_pressed() -> void:
	get_tree().get_first_node_in_group("main").show_screen("categories")
