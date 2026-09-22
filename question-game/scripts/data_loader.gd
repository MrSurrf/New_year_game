extends Node

var config: Dictionary = {}
var categories: Array = []
var characters: Array = []


func _ready() -> void:
	config = _load_json("res://data/config.json")
	categories = _load_json("res://data/categories.json")
	characters = _load_json("res://data/characters.json")
	_validate()


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Файл данных не найден: " + path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if data == null:
		push_error("Ошибка разбора JSON: " + path)
		return null
	return data


func _validate() -> void:
	if typeof(config) != TYPE_DICTIONARY:
		push_error("config.json должен содержать объект")
		config = {}
	for key in ["answer_time_sec", "steal_time_sec", "points_correct", "points_steal", "questions_first_pick"]:
		if not config.has(key):
			push_error("В config.json отсутствует поле: " + key)
			config[key] = 0
	if typeof(categories) != TYPE_ARRAY:
		push_error("categories.json должен содержать массив категорий")
		categories = []
	for cat in categories:
		if not (cat.has("id") and cat.has("name") and cat.has("questions")):
			push_error("Категория без id/name/questions: " + str(cat))
			continue
		var questions: Array = cat["questions"]
		if questions.size() != 6:
			push_error("Категория '%s' должна содержать ровно 6 вопросов, найдено: %d" % [cat["name"], questions.size()])
		for q in questions:
			_validate_question(cat["id"], q)
	if typeof(characters) != TYPE_ARRAY:
		push_error("characters.json должен содержать массив персонажей")
		characters = []
	for ch in characters:
		if not (ch.has("id") and ch.has("name") and ch.has("ability")):
			push_error("Персонаж без id/name/ability: " + str(ch))
			continue
		if not ch["ability"].has("effects") or typeof(ch["ability"]["effects"]) != TYPE_ARRAY:
			push_error("У персонажа '%s' способность без массива effects" % ch["id"])
		for frame in ["frame1.png"]:
			var path := "res://assets/characters/%s/%s" % [ch["id"], frame]
			if not FileAccess.file_exists(path):
				push_error("Не найден кадр анимации: " + path)


func _validate_question(cat_id: String, q: Variant) -> void:
	if typeof(q) != TYPE_DICTIONARY:
		push_error("Некорректный вопрос в категории '%s': %s" % [cat_id, str(q)])
		return
	for key in ["id", "type", "text", "answer"]:
		if not q.has(key):
			push_error("Вопрос в категории '%s' без поля '%s': %s" % [cat_id, key, str(q)])
	if q.get("type") not in ["open", "choice"]:
		push_error("Вопрос '%s': неизвестный type '%s' (ожидается open или choice)" % [q.get("id"), q.get("type")])
	if q.get("type") == "choice":
		var options: Array = q.get("options", [])
		if options.is_empty():
			push_error("Вопрос '%s' типа choice без options" % q.get("id"))
		elif q.get("answer") not in options:
			push_error("Вопрос '%s': answer отсутствует среди options" % q.get("id"))
	if q.has("media"):
		var media: Variant = q["media"]
		if typeof(media) != TYPE_DICTIONARY \
				or media.get("type") not in ["image", "audio"] \
				or not media.has("path"):
			push_error("Вопрос '%s': некорректное поле media (нужны type: image|audio и path)" % q.get("id"))
		elif not FileAccess.file_exists(media["path"]):
			push_error("Вопрос '%s': медиафайл не найден: %s" % [q.get("id"), media["path"]])
	if q.has("time") and float(q["time"]) <= 0.0:
		push_error("Вопрос '%s': time должен быть положительным числом" % q.get("id"))


func get_category(cat_id: String) -> Dictionary:
	for cat in categories:
		if cat.get("id") == cat_id:
			return cat
	return {}


func get_config_int(key: String) -> int:
	return int(config.get(key, 0))
