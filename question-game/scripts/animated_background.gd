extends TextureRect

@export var frames_dir := "res://assets/backgrounds/back"
@export var fps := 12.0

var _frames: Array[Texture2D] = []
var _index := 0
var _accum := 0.0


func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var dir := DirAccess.open(frames_dir)
	if dir == null:
		push_warning("AnimatedBackground: папка не найдена: " + frames_dir)
		return
	var names: Array[String] = []
	for file_name in dir.get_files():
		if file_name.ends_with(".png") or file_name.ends_with(".png.import"):
			var base := file_name.trim_suffix(".import")
			if not names.has(base):
				names.append(base)
	names.sort()
	for file_name in names:
		_frames.append(load(frames_dir.path_join(file_name)))
	if _frames.is_empty():
		push_warning("AnimatedBackground: нет кадров в " + frames_dir)
	else:
		texture = _frames[0]


func _process(delta: float) -> void:
	if _frames.size() < 2:
		return
	_accum += delta
	if _accum >= 1.0 / fps:
		_accum = 0.0
		_index = (_index + 1) % _frames.size()
		texture = _frames[_index]
