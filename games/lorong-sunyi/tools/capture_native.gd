extends SceneTree

# Bukti visual native saja; tools/ tidak disertakan dalam ekspor pemain.

func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var capture_path := OS.get_environment("GENERIC2D_CAPTURE_PATH")
	if capture_path.is_empty():
		push_error("GENERIC2D_CAPTURE_PATH harus berisi path PNG keluaran")
		quit(1)
		return
	var mode := OS.get_environment("LORONG_CAPTURE_MODE")
	if mode.is_empty():
		mode = "title"
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Scene utama Lorong Sunyi tidak dapat dimuat")
		quit(1)
		return
	var main := packed.instantiate() as LorongGameController
	root.add_child(main)
	await process_frame
	await process_frame

	if mode != "title":
		main.call("_start_game")
		await process_frame
		var room := main.get("_room") as LorongRoom
		if room == null:
			push_error("Area permainan tidak tersedia untuk capture")
			quit(1)
			return
		match mode:
			"threat", "result":
				for prop_id: String in ["bangku", "laci", "lemari", "meja", "lampu"]:
					room.interact_prop(prop_id)
				if mode == "result":
					room.interact_prop("jam")
					room.interact_prop("potret")
					room.interact_prop("pintu")
					room.submit_code("417")
			"pause":
				main.call("_toggle_pause")
			"touch":
				var touch_controls := main.get_node_or_null("HUD/TouchControls") as Control
				if touch_controls != null:
					touch_controls.visible = true
			_:
				pass

	for _frame: int in 8:
		await process_frame
	await create_timer(0.25).timeout
	var image := root.get_texture().get_image()
	var error := image.save_png(capture_path)
	paused = false
	var audio := root.get_node_or_null("AudioDirector")
	if audio != null:
		audio.call("release_streams")
	await process_frame
	print("[capture-lorong-sunyi] %s (%s)" % [capture_path, error_string(error)])
	quit(0 if error == OK else 1)
