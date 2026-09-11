extends Control

@onready var team1_label: Label = $VBox/ScoreBar/Team1Label
@onready var turn_label: Label = $VBox/ScoreBar/TurnLabel
@onready var team2_label: Label = $VBox/ScoreBar/Team2Label
@onready var grid: GridContainer = $VBox/Grid


func _ready() -> void:
	_update_score()
	turn_label.text = "%s выбирает категорию для %s" % [
		GameState.team_label(GameState.challenging_team),
		GameState.team_label(GameState.answering_team),
	]
	GameState.scores_changed.connect(_update_score)
	_build_tiles()


func _update_score() -> void:
	team1_label.text = "Команда 1: %d" % GameState.scores["team1"]
	team2_label.text = "Команда 2: %d" % GameState.scores["team2"]


func _build_tiles() -> void:
	for cat in DataLoader.categories:
		var remaining: int = GameState.remaining_in_category(cat["id"])
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(320, 180)
		tile.text = "%s\nОсталось вопросов: %d" % [cat["name"], remaining]
		tile.add_theme_font_size_override("font_size", 24)
		tile.disabled = remaining == 0
		tile.pressed.connect(_on_tile_pressed.bind(cat["id"]))
		grid.add_child(tile)


func _on_tile_pressed(cat_id: String) -> void:
	SoundManager.play_category_select()
	GameState.pending_category = cat_id
	get_tree().get_first_node_in_group("main").show_screen("question")
