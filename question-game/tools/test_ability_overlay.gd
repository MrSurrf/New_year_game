extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var overlay = load("res://scenes/ability_overlay.tscn").instantiate()
	root.add_child(overlay)
	overlay.show_ability({
		"id": "alchemist",
		"ability": {"name": "Тест", "description": "Проверка оверлея"},
	})
	await create_timer(5.0).timeout
	if is_instance_valid(overlay) or paused:
		print("TEST_FAIL: overlay alive=", is_instance_valid(overlay), " paused=", paused)
	else:
		print("TEST_OK")
	quit()
