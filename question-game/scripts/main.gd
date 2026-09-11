extends Control

const SCREENS := {
	"roster": preload("res://scenes/roster_screen.tscn"),
	"categories": preload("res://scenes/categories_screen.tscn"),
	"question": preload("res://scenes/question_screen.tscn"),
	"result": preload("res://scenes/result_screen.tscn"),
}

@onready var start_screen: CenterContainer = $StartScreen
@onready var screen_container: Control = $ScreenContainer
@onready var start_background: TextureRect = $StartBackground


func _ready() -> void:
	add_to_group("main")
	$StartScreen/VBox/StartButton.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	SoundManager.play_game_start()
	GameState.reset_game()
	show_screen("roster")


func show_screen(screen_name: String) -> void:
	SoundManager.play_switch()
	start_screen.visible = false
	start_background.visible = false
	screen_container.visible = true
	for child in screen_container.get_children():
		child.queue_free()
	screen_container.add_child(SCREENS[screen_name].instantiate())


func show_start() -> void:
	for child in screen_container.get_children():
		child.queue_free()
	screen_container.visible = false
	start_background.visible = true
	start_screen.visible = true
