extends Node

const MUSIC_BASE := "res://sound/music/background_loop"
const CLICK_BASE := "res://sound/ui/click"
const SWITCH_BASE := "res://sound/ui/switch"
const ABILITIES_DIR := "res://sound/abilities"
const CORRECT_BASE := "res://sound/choise/correct"
const WRONG_BASE := "res://sound/choise/wrong"
const GAME_START_BASE := "res://sound/game_start/game_start"
const CHARACTER_SELECT_BASE := "res://sound/character_select/character_select"
const CATEGORY_SELECT_BASE := "res://sound/category_select/category_select"
const STEAL_BASE := "res://sound/steal/steal"
const TIMER_TICK_BASE := "res://sound/timer/timer_tick"
const TIMEOUT_BASE := "res://sound/timer/timeout"
const ROUND_END_BASE := "res://sound/round_end/round_end"
const GAME_END_BASE := "res://sound/game_end/game_end"
const EXTENSIONS: Array[String] = [".wav", ".ogg", ".mp3"]

var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _ability_sounds: Array[String] = []
var _media: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = _make_player(_find_stream(MUSIC_BASE), -12.0)
	_music.finished.connect(_music.play)
	_music.play()
	for i in 6:
		_sfx.append(_make_player("", 0.0))
	_media = _make_player("", 0.0)
	_ability_sounds = _scan_audio_dir(ABILITIES_DIR)
	get_tree().node_added.connect(_on_node_added)


func _find_stream(base: String) -> String:
	for ext in EXTENSIONS:
		var path := base + ext
		if ResourceLoader.exists(path):
			return path
	push_warning("SoundManager: файл не найден: " + base + " (искал " + ", ".join(EXTENSIONS) + ")")
	return ""


func _scan_audio_dir(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("SoundManager: папка не найдена: " + dir_path)
		return result
	for file_name in dir.get_files():
		for ext in EXTENSIONS:
			if file_name.ends_with(ext):
				result.append(dir_path.path_join(file_name))
				break
	if result.is_empty():
		push_warning("SoundManager: нет звуков в " + dir_path)
	return result


func _make_player(stream_path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	if not stream_path.is_empty():
		player.stream = load(stream_path)
	player.volume_db = volume_db
	player.bus = "Master"
	add_child(player)
	return player


func _play(base: String) -> void:
	var path := _find_stream(base)
	if path.is_empty():
		return
	_play_path(path)


func _play_path(path: String) -> void:
	var player := _sfx[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx.size()
	player.stream = load(path)
	player.play()


func play_switch() -> void:
	_play(SWITCH_BASE)


func play_ability() -> void:
	if not _ability_sounds.is_empty():
		_play_path(_ability_sounds[randi() % _ability_sounds.size()])


func play_correct() -> void:
	_play(CORRECT_BASE)


func play_wrong() -> void:
	_play(WRONG_BASE)


func play_game_start() -> void:
	_play(GAME_START_BASE)


func play_character_select() -> void:
	_play(CHARACTER_SELECT_BASE)


func play_category_select() -> void:
	_play(CATEGORY_SELECT_BASE)


func play_steal() -> void:
	_play(STEAL_BASE)


func play_timer_tick() -> void:
	_play(TIMER_TICK_BASE)


func play_timeout() -> void:
	_play(TIMEOUT_BASE)


func play_round_end() -> void:
	_play(ROUND_END_BASE)


func play_game_end() -> void:
	_play(GAME_END_BASE)


func play_media(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("SoundManager: медиафайл не найден: " + path)
		return
	_media.stream = load(path)
	_media.play()


func stop_media() -> void:
	_media.stop()


func _on_node_added(node: Node) -> void:
	if node is Button and not node.pressed.is_connected(_on_any_button_pressed):
		node.pressed.connect(_on_any_button_pressed)


func _on_any_button_pressed() -> void:
	_play(CLICK_BASE)
