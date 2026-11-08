extends SceneTree

# Developer-only native capture. The old "threat" and "result" modes belonged to
# the retired horror prototype and are intentionally rejected; this tool is not
# part of the player export.
const SUPPORTED_MODES := ["title", "village", "focus", "walk", "pause", "touch"]
const RETIRED_MODES := ["threat", "result"]


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
	if mode in RETIRED_MODES:
		push_error("Mode capture '%s' adalah legacy dari prototype horor dan tidak didukung. Gunakan: %s" % [mode, ", ".join(SUPPORTED_MODES)])
		quit(2)
		return
	if mode not in SUPPORTED_MODES:
		push_error("Mode capture tidak dikenal: %s. Gunakan: %s" % [mode, ", ".join(SUPPORTED_MODES)])
		quit(2)
		return

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
			push_error("Scene Village tidak tersedia untuk capture")
			quit(1)
			return
		match mode:
			"focus":
				var player := room.get("player") as CharacterBody2D
				if player != null:
					player.global_position = room.call("npc_position_for_testing", "pak_ranu")
					room.call("_update_interaction_prompt", true)
			"walk":
				var player := room.get("player") as CharacterBody2D
				var visual := player.get_node_or_null("CharacterVisual") as Node if player != null else null
				if visual != null:
					visual.call("set_moving", true)
			"pause":
				main.call("_open_pause")
			"touch":
				var touch_controls := main.get_node_or_null("HUD/TouchControls") as Control
				if touch_controls != null:
					touch_controls.visible = true
			"village":
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
