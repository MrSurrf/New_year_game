extends TextureRect

@export_dir var frames_dir: String = "res://assets/backgrounds/back_roster"
@export_range(1.0, 60.0, 0.5) var fps: float = 12.0

var frames: Array[Texture2D] = []
var current_frame := 0
var elapsed := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	_load_frames()

	if not frames.is_empty():
		texture = frames[0]


func _process(delta: float) -> void:
	if frames.size() < 2:
		return

	elapsed += delta

	var frame_duration := 1.0 / fps
	while elapsed >= frame_duration:
		elapsed -= frame_duration
		current_frame = (current_frame + 1) % frames.size()
		texture = frames[current_frame]


func _load_frames() -> void:
	var dir := DirAccess.open(frames_dir)

	if dir == null:
		push_warning("AnimatedBackground: папка не найдена: " + frames_dir)
		return

	var names: Array[String] = []

	for file_name in dir.get_files():
		if file_name.to_lower().ends_with(".png"):
			names.append(file_name)

	names.sort()

	for file_name in names:
		var frame := load(frames_dir.path_join(file_name)) as Texture2D
		if frame != null:
			frames.append(frame)

	if frames.is_empty():
		push_warning("AnimatedBackground: в папке нет PNG-кадров: " + frames_dir)
