extends Node

signal scores_changed

var scores := {"team1": 0, "team2": 0}
var round_number := 1
var answering_team := "team2"
var challenging_team := "team1"
var question_states := {}
var skip_flags := {"team1": false, "team2": false}
var current_character: Dictionary = {}
var current_category_id := ""
var pending_category := ""
var double_points_active := false
var ability_used_this_round := false


func _ready() -> void:
	reset_game()


func reset_game() -> void:
	scores = {"team1": 0, "team2": 0}
	round_number = 1
	answering_team = "team2"
	challenging_team = "team1"
	skip_flags = {"team1": false, "team2": false}
	current_character = {}
	current_category_id = ""
	pending_category = ""
	double_points_active = false
	ability_used_this_round = false
	question_states.clear()
	for cat in DataLoader.categories:
		var states := {}
		for q in cat.get("questions", []):
			states[q.get("id", "")] = "fresh"
		question_states[cat.get("id", "")] = states
	scores_changed.emit()


func team_label(team: String) -> String:
	return "Команда 1" if team == "team1" else "Команда 2"


func begin_round() -> String:
	ability_used_this_round = false
	var msg := ""
	var guard := 0
	while skip_flags[answering_team] and guard < 4:
		skip_flags[answering_team] = false
		msg = "%s пропускает раунд из-за способности!" % team_label(answering_team)
		_swap_roles()
		guard += 1
	return msg


func finish_round() -> void:
	_swap_roles()
	ability_used_this_round = false


func _swap_roles() -> void:
	var tmp := answering_team
	answering_team = challenging_team
	challenging_team = tmp
	round_number += 1


func pick_questions(cat_id: String) -> Array:
	current_category_id = cat_id
	var cat := DataLoader.get_category(cat_id)
	var result: Array = []
	var limit: int = DataLoader.get_config_int("questions_first_pick")
	var taken := 0
	for q in cat.get("questions", []):
		if taken >= limit:
			break
		if question_states.get(cat_id, {}).get(q.get("id")) == "fresh":
			result.append(q)
			taken += 1
	for q in cat.get("questions", []):
		if question_states.get(cat_id, {}).get(q.get("id")) == "unanswered":
			result.append(q)
	return result


func mark_question(question_id: String, state: String) -> void:
	if question_states.has(current_category_id):
		question_states[current_category_id][question_id] = state


func award(team: String, base_points: int) -> void:
	var points := base_points
	if double_points_active:
		points *= 2
	scores[team] += points
	double_points_active = false
	scores_changed.emit()


func remaining_in_category(cat_id: String) -> int:
	var count := 0
	for state in question_states.get(cat_id, {}).values():
		if state != "answered":
			count += 1
	return count


func is_game_over() -> bool:
	for cat_id in question_states:
		if remaining_in_category(cat_id) > 0:
			return false
	return true


func use_ability() -> Array:
	ability_used_this_round = true
	var actions: Array = []
	for effect in current_character.get("ability", {}).get("effects", []):
		match String(effect.get("type", "")):
			"add_points":
				scores[answering_team] += int(effect.get("value", 0))
			"skip_next_round":
				skip_flags[answering_team] = true
			"show_hint":
				actions.append("show_hint")
			"extra_time":
				actions.append(effect)
			"double_points":
				double_points_active = true
			_:
				push_error("Неизвестный тип эффекта способности: " + str(effect.get("type")))
	scores_changed.emit()
	return actions
