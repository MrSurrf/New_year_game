extends Control

@onready var round_label: Label = $VBox/TopBar/RoundLabel
@onready var phase_label: Label = $VBox/PhaseLabel
@onready var question_text: Label = $VBox/QuestionText
@onready var options_box: VBoxContainer = $VBox/OptionsBox
@onready var timer_bar: ProgressBar = $VBox/TimerBox/TimerBar
@onready var timer_label: Label = $VBox/TimerBox/TimerLabel
@onready var hint_label: Label = $VBox/HintLabel
@onready var answer_label: Label = $VBox/HostPanel/HostVBox/AnswerLabel
@onready var correct_button: Button = $VBox/HostPanel/HostVBox/VerdictBox/CorrectButton
@onready var wrong_button: Button = $VBox/HostPanel/HostVBox/VerdictBox/WrongButton
@onready var no_answer_button: Button = $VBox/HostPanel/HostVBox/VerdictBox/NoAnswerButton
@onready var ability_button: Button = $VBox/HostPanel/HostVBox/AbilityButton

var queue: Array = []
var current: Dictionary = {}
var time_left := 0.0
var timer_running := false
var steal_phase := false
var option_buttons: Array = []
var selected_option := -1


func _ready() -> void:
	round_label.text = "Раунд %d — %s вызывает, %s отвечает" % [
		GameState.round_number,
		GameState.team_label(GameState.challenging_team),
		GameState.team_label(GameState.answering_team),
	]
	var ability: Dictionary = GameState.current_character.get("ability", {})
	ability_button.text = "Способность: %s" % ability.get("name", "—")
	ability_button.disabled = GameState.ability_used_this_round or ability.is_empty()
	correct_button.pressed.connect(_on_correct_pressed)
	wrong_button.pressed.connect(_on_wrong_pressed)
	no_answer_button.pressed.connect(_on_no_answer_pressed)
	ability_button.pressed.connect(_on_ability_pressed)
	queue = GameState.pick_questions(GameState.pending_category)
	_next_question()


func _process(delta: float) -> void:
	if not timer_running:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		timer_running = false
		_update_timer_display()
		_on_timeout()
	else:
		_update_timer_display()


func _next_question() -> void:
	if queue.is_empty():
		_end_round()
		return
	current = queue.pop_front()
	steal_phase = false
	selected_option = -1
	GameState.double_points_active = false
	question_text.text = current.get("text", "")
	hint_label.visible = false
	answer_label.text = "Правильный ответ: %s" % current.get("answer", "")
	phase_label.text = "Отвечает: %s" % GameState.team_label(GameState.answering_team)
	no_answer_button.visible = true
	correct_button.text = "Верно (+%d отвечающей)" % DataLoader.get_config_int("points_correct")
	_set_verdicts_enabled(true)
	_build_options()
	_start_timer(float(DataLoader.get_config_int("answer_time_sec")))


func _build_options() -> void:
	for b in option_buttons:
		b.queue_free()
	option_buttons.clear()
	if current.get("type") != "choice":
		return
	var letters := ["А", "Б", "В", "Г", "Д", "Е"]
	var options: Array = current.get("options", [])
	for i in options.size():
		var b := Button.new()
		b.text = "%s) %s" % [letters[i], options[i]]
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_on_option_pressed.bind(i))
		options_box.add_child(b)
		option_buttons.append(b)


func _on_option_pressed(index: int) -> void:
	selected_option = index
	for i in option_buttons.size():
		option_buttons[i].modulate = Color(0.7, 1.0, 0.7) if i == index else Color.WHITE


func _start_timer(seconds: float) -> void:
	time_left = seconds
	timer_bar.max_value = seconds
	timer_running = true
	_update_timer_display()


func _update_timer_display() -> void:
	timer_bar.value = time_left
	timer_label.text = "%d с" % int(ceil(time_left))


func _set_verdicts_enabled(enabled: bool) -> void:
	correct_button.disabled = not enabled
	wrong_button.disabled = not enabled
	no_answer_button.disabled = not enabled


func _on_timeout() -> void:
	if steal_phase:
		GameState.mark_question(current["id"], "unanswered")
		_next_question()
	else:
		_start_steal()


func _on_correct_pressed() -> void:
	timer_running = false
	_set_verdicts_enabled(false)
	if steal_phase:
		GameState.award(GameState.challenging_team, DataLoader.get_config_int("points_steal"))
	else:
		GameState.award(GameState.answering_team, DataLoader.get_config_int("points_correct"))
	GameState.mark_question(current["id"], "answered")
	_next_question()


func _on_wrong_pressed() -> void:
	if steal_phase:
		timer_running = false
		GameState.mark_question(current["id"], "unanswered")
		_next_question()
	else:
		_start_steal()


func _on_no_answer_pressed() -> void:
	if steal_phase:
		return
	_start_steal()


func _start_steal() -> void:
	steal_phase = true
	phase_label.text = "Перехват! Отвечает: %s" % GameState.team_label(GameState.challenging_team)
	no_answer_button.visible = false
	correct_button.text = "Верно (+%d вызывающей)" % DataLoader.get_config_int("points_steal")
	_set_verdicts_enabled(true)
	_start_timer(float(DataLoader.get_config_int("steal_time_sec")))


func _on_ability_pressed() -> void:
	ability_button.disabled = true
	SoundManager.play_ability()
	for action in GameState.use_ability():
		if action is String and action == "show_hint":
			hint_label.text = "Подсказка: %s" % current.get("hint", "подсказки нет")
			hint_label.visible = true
		elif action is Dictionary and action.get("type") == "extra_time":
			time_left += float(action.get("value", 0))
			timer_bar.max_value = maxf(timer_bar.max_value, time_left)
			timer_running = time_left > 0.0
			_update_timer_display()


func _end_round() -> void:
	timer_running = false
	GameState.finish_round()
	var main := get_tree().get_first_node_in_group("main")
	if GameState.is_game_over():
		main.show_screen("result")
	else:
		main.show_screen("roster")
