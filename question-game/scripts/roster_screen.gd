extends Control


@onready var info_label: Label = $VBox/InfoLabel
@onready var grid: GridContainer = $VBox/MainHBox/LeftBox/Grid
@onready var selected_label: Label = $VBox/MainHBox/RightPanel/RightVBox/SelectedLabel
@onready var confirm_button: Button = $VBox/MainHBox/RightPanel/RightVBox/ConfirmButton
@onready var score1_label: Label = $VBox/MainHBox/RightPanel/RightVBox/Score1Label
@onready var score2_label: Label = $VBox/MainHBox/RightPanel/RightVBox/Score2Label

const HAT_TEXTURE := preload("res://assets/hat.png")
const FRAME_SIZE := 170.0
const HAT_SIZE := Vector2(145, 148)
const HAT_REST_POS := Vector2(0, -53)
const HAT_DROP_HEIGHT := 60.0

var selected_card: Button = null
var holders := {}
var hats := {}
var hat_tweens := {}
var blink_tweens := {}


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
	GameState.scores_changed.connect(_update_scores)
	_update_scores()
	_build_cards()


func _update_scores() -> void:
	score1_label.text = "%s: %d" % [GameState.team_label("team1"), GameState.scores["team1"]]
	score2_label.text = "%s: %d" % [GameState.team_label("team2"), GameState.scores["team2"]]


func _build_cards() -> void:
	for ch in DataLoader.characters:
		var card := Button.new()
		card.custom_minimum_size = Vector2(190, 190)

		var vb := VBoxContainer.new()
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(vb)

		var holder := Control.new()
		holder.custom_minimum_size = Vector2(FRAME_SIZE, FRAME_SIZE)
		holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(holder)

		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/characters/%s/frame1.png" % ch["id"])
		var fit: float = minf(FRAME_SIZE / sprite.texture.get_width(), FRAME_SIZE / sprite.texture.get_height())
		sprite.scale = Vector2(fit, fit)
		sprite.position = Vector2(FRAME_SIZE / 2.0, FRAME_SIZE / 2.0)
		holder.add_child(sprite)
		holders[card] = holder

		var hat := TextureRect.new()
		hat.texture = HAT_TEXTURE
		hat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hat.size = HAT_SIZE
		hat.position = HAT_REST_POS
		hat.visible = false
		hat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(hat)
		hats[card] = hat

		card.pressed.connect(_on_card_pressed.bind(ch, card))
		card.mouse_entered.connect(_on_card_hover.bind(card, true))
		card.mouse_exited.connect(_on_card_hover.bind(card, false))
		grid.add_child(card)


func _on_card_pressed(ch: Dictionary, card: Button) -> void:
	SoundManager.play_character_select()
	GameState.current_character = ch
	if selected_card != null and selected_card != card:
		selected_card.modulate = Color.WHITE
		_stop_blink(selected_card)
		hats[selected_card].visible = false
	selected_card = card
	card.modulate = Color(0.7, 1.0, 0.7)
	hats[card].visible = true
	_start_blink(card)
	selected_label.text = "Выбран: %s" % ch["name"]
	confirm_button.disabled = false


func _start_blink(card: Button) -> void:
	_stop_blink(card)
	var holder: Control = holders[card]
	var tween := create_tween().set_loops()
	tween.tween_property(holder, "modulate:a", 0.25, 0.2)
	tween.tween_property(holder, "modulate:a", 1.0, 0.2)
	blink_tweens[card] = tween


func _stop_blink(card: Button) -> void:
	if blink_tweens.has(card) and blink_tweens[card].is_valid():
		blink_tweens[card].kill()
	holders[card].modulate.a = 1.0


func _on_card_hover(card: Button, entered: bool) -> void:
	var hat: TextureRect = hats[card]
	if hat_tweens.has(card) and hat_tweens[card].is_valid():
		hat_tweens[card].kill()
	if entered:
		hat.visible = true
		hat.position = HAT_REST_POS - Vector2(0, HAT_DROP_HEIGHT)
		var tween := create_tween()
		tween.tween_property(hat, "position", HAT_REST_POS, 0.35) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		hat_tweens[card] = tween
	elif card != selected_card:
		hat.visible = false


func _on_confirm_pressed() -> void:
	get_tree().get_first_node_in_group("main").show_screen("categories")
