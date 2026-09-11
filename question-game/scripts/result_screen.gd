extends Control

@onready var winner_label: Label = $Center/VBox/WinnerLabel
@onready var score_label: Label = $Center/VBox/ScoreLabel
@onready var new_game_button: Button = $Center/VBox/NewGameButton


func _ready() -> void:
	SoundManager.play_game_end()
	var s1: int = GameState.scores["team1"]
	var s2: int = GameState.scores["team2"]
	if s1 > s2:
		winner_label.text = "Победила Команда 1!"
	elif s2 > s1:
		winner_label.text = "Победила Команда 2!"
	else:
		winner_label.text = "Ничья!"
	score_label.text = "Команда 1: %d  —  Команда 2: %d" % [s1, s2]
	new_game_button.pressed.connect(_on_new_game_pressed)


func _on_new_game_pressed() -> void:
	GameState.reset_game()
	get_tree().get_first_node_in_group("main").show_start()
