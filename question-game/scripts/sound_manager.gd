extends Node

const MUSIC_PATH := "res://sound/music/background_loop.wav"
const CLICK_PATH := "res://sound/ui/click.wav"
const SWITCH_PATH := "res://sound/ui/switch.wav"
const ABILITY_PATH := "res://sound/abilities/ability.wav"

var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_index := 0


func _ready() -> void:
	_music = _make_player(MUSIC_PATH, -12.0)
	_music.finished.connect(_music.play)
	_music.play()
	for i in 4:
		_sfx.append(_make_player(CLICK_PATH, 0.0))
	get_tree().node_added.connect(_on_node_added)


func _make_player(stream_path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	if ResourceLoader.exists(stream_path):
		player.stream = load(stream_path)
	else:
		push_warning("SoundManager: файл не найден: " + stream_path)
	player.volume_db = volume_db
	player.bus = "Master"
	add_child(player)
	return player


func _play(path: String) -> void:
	var player := _sfx[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx.size()
	if ResourceLoader.exists(path):
		player.stream = load(path)
		player.play()


func play_switch() -> void:
	_play(SWITCH_PATH)


func play_ability() -> void:
	_play(ABILITY_PATH)


func _on_node_added(node: Node) -> void:
	if node is Button and not node.pressed.is_connected(_on_any_button_pressed):
		node.pressed.connect(_on_any_button_pressed)


func _on_any_button_pressed() -> void:
	_play(CLICK_PATH)
