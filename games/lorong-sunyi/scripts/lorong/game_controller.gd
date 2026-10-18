extends Control
class_name LorongGameController

const RoomComponent = preload("res://scripts/lorong/room.gd")
const COVER_ART: Texture2D = preload("res://assets/share/lorong-title-1280x720.png")

var _mode := "judul"
var _room: LorongRoom
var _title_screen: Control
var _hud: Control
var _pause_layer: Control
var _code_layer: Control
var _result_layer: Control
var _help_label: Label
var _status_label: Label
var _lives_label: Label
var _fear_bar: ProgressBar
var _message_label: Label
var _prompt_label: Label
var _interact_button: Button
var _tint_layer: ColorRect
var _code_display: Label
var _code_entry := ""
var _touch_actions: Array[String] = ["move_left", "move_right", "move_up", "move_down"]


func _ready() -> void:
	name = "LorongSunyi"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_title_screen()


func _process(_delta: float) -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.modulate.a = clampf(_active_tune("ui.hud.opacity", 0.94), 0.4, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if _code_layer != null:
		if event.keycode == KEY_ESCAPE:
			_close_code_panel()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			_submit_code_entry()
		elif event.keycode == KEY_BACKSPACE:
			_code_entry = _code_entry.left(maxi(0, _code_entry.length() - 1))
			_update_code_display()
		elif event.keycode >= KEY_0 and event.keycode <= KEY_9:
			_add_code_digit(str(event.keycode - KEY_0))
		get_viewport().set_input_as_handled()
		return
	if _mode != "bermain":
		return
	if event.keycode in [KEY_ESCAPE, KEY_P]:
		_toggle_pause()
	elif event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		_request_interaction()
	get_viewport().set_input_as_handled()


func _build_title_screen() -> void:
	_title_screen = Control.new()
	_title_screen.name = "TitleScreen"
	_title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_title_screen)

	var cover := TextureRect.new()
	cover.name = "CoverArt"
	cover.texture = COVER_ART
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_screen.add_child(cover)

	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.color = Color(0.035, 0.025, 0.055, 0.34)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_screen.add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "IntroPanel"
	panel.position = Vector2(42.0, 416.0)
	panel.size = Vector2(520.0, 274.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.045, 0.075, 0.94)))
	_title_screen.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	margin.add_child(stack)

	var heading := _label("Mika dan Lorong yang Berubah", 23, Color(0.97, 0.86, 0.67))
	stack.add_child(heading)
	var intro := _label("Seekor kelinci kecil terkurung di kamar sunyi. Periksa setiap benda, temukan kode, dan hindari sesuatu yang mengubah ruangan.", 15, Color(0.87, 0.84, 0.87))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.y = 46.0
	stack.add_child(intro)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	stack.add_child(button_row)
	var start_button := _button("MASUK KE LORONG", Vector2(220.0, 52.0), true)
	start_button.pressed.connect(_start_game)
	button_row.add_child(start_button)
	var help_button := _button("CARA BERMAIN", Vector2(190.0, 52.0), false)
	help_button.pressed.connect(_toggle_help)
	button_row.add_child(help_button)

	_help_label = _label("Gerak: tombol panah/WASD atau pad sentuh. Dekati benda lalu tekan E, Spasi, atau PERIKSA. Setelah bayangan muncul, masuk ke lemari yang terbuka dan tunggu.", 13, Color(0.79, 0.76, 0.82))
	_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help_label.visible = false
	stack.add_child(_help_label)
	var note := _label("HOROR PSIKOLOGIS 2.5D  |  TANPA GORE", 11, Color(0.79, 0.59, 0.47))
	stack.add_child(note)


func _toggle_help() -> void:
	if _help_label != null:
		_help_label.visible = not _help_label.visible


func _start_game() -> void:
	get_tree().paused = false
	_release_touch_actions()
	if _title_screen != null:
		_title_screen.queue_free()
		_title_screen = null
	if _hud != null:
		_hud.queue_free()
		_hud = null
	if _room != null and is_instance_valid(_room):
		_room.queue_free()
	var store := get_node_or_null("/root/TuningStore")
	if store != null:
		store.call("begin_run", false)
	_room = RoomComponent.new()
	_room.name = "Room"
	_room.process_mode = Node.PROCESS_MODE_PAUSABLE
	_room.message_changed.connect(_on_room_message)
	_room.prompt_changed.connect(_on_room_prompt)
	_room.status_changed.connect(_on_room_status)
	_room.visual_tone_changed.connect(_on_room_tone)
	_room.code_entry_requested.connect(_open_code_panel)
	_room.game_finished.connect(_on_room_finished)
	add_child(_room)
	_build_hud()
	_mode = "bermain"
	_room.start_run()


func _build_hud() -> void:
	_hud = Control.new()
	_hud.name = "HUD"
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hud)

	_tint_layer = ColorRect.new()
	_tint_layer.name = "DistortionTint"
	_tint_layer.color = Color(0.26, 0.09, 0.31, 0.0)
	_tint_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tint_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_tint_layer)

	var status_back := ColorRect.new()
	status_back.name = "StatusBack"
	status_back.position = Vector2(22.0, 18.0)
	status_back.size = Vector2(390.0, 166.0)
	status_back.color = Color(0.035, 0.035, 0.055, 0.84)
	status_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(status_back)

	var brand := _label("LORONG SUNYI", 23, Color(0.98, 0.84, 0.61))
	brand.position = Vector2(40.0, 28.0)
	brand.size = Vector2(338.0, 34.0)
	_hud.add_child(brand)
	_status_label = _label("Petunjuk: bangku — / lemari — / cahaya —\nUrutan catatan: belum ditemukan.", 13, Color(0.87, 0.85, 0.89))
	_status_label.position = Vector2(40.0, 68.0)
	_status_label.size = Vector2(348.0, 46.0)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.add_child(_status_label)

	var fear_label := _label("KEGELISAHAN", 11, Color(0.75, 0.65, 0.73))
	fear_label.position = Vector2(40.0, 122.0)
	fear_label.size = Vector2(112.0, 22.0)
	_hud.add_child(fear_label)
	_fear_bar = ProgressBar.new()
	_fear_bar.name = "FearMeter"
	_fear_bar.position = Vector2(145.0, 126.0)
	_fear_bar.size = Vector2(165.0, 15.0)
	_fear_bar.min_value = 0.0
	_fear_bar.max_value = 5.0
	_fear_bar.show_percentage = false
	_fear_bar.value = 0.0
	var fear_background := StyleBoxFlat.new()
	fear_background.bg_color = Color(0.09, 0.07, 0.12, 0.96)
	fear_background.border_color = Color(0.35, 0.27, 0.34, 0.94)
	fear_background.set_border_width_all(1)
	fear_background.set_corner_radius_all(5)
	_fear_bar.add_theme_stylebox_override("background", fear_background)
	var fear_fill := StyleBoxFlat.new()
	fear_fill.bg_color = Color(0.66, 0.34, 0.43, 0.98)
	fear_fill.set_corner_radius_all(4)
	_fear_bar.add_theme_stylebox_override("fill", fear_fill)
	_hud.add_child(_fear_bar)
	_lives_label = _label("KETENANGAN: 3", 12, Color(0.91, 0.81, 0.66))
	_lives_label.position = Vector2(40.0, 148.0)
	_lives_label.size = Vector2(225.0, 22.0)
	_hud.add_child(_lives_label)

	var pause_button := _button("JEDA", Vector2(96.0, 46.0), false)
	pause_button.name = "PauseButton"
	pause_button.position = Vector2(1158.0, 24.0)
	pause_button.pressed.connect(_toggle_pause)
	_hud.add_child(pause_button)

	var prompt_back := ColorRect.new()
	prompt_back.position = Vector2(426.0, 573.0)
	prompt_back.size = Vector2(430.0, 34.0)
	prompt_back.color = Color(0.035, 0.03, 0.05, 0.77)
	prompt_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(prompt_back)
	_prompt_label = _label("", 15, Color(1.0, 0.83, 0.56))
	_prompt_label.position = Vector2(436.0, 578.0)
	_prompt_label.size = Vector2(410.0, 24.0)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(_prompt_label)

	var message_back := ColorRect.new()
	message_back.position = Vector2(416.0, 612.0)
	message_back.size = Vector2(452.0, 80.0)
	message_back.color = Color(0.035, 0.03, 0.05, 0.83)
	message_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(message_back)
	_message_label = _label("Dekati sebuah benda untuk memeriksanya.", 14, Color(0.92, 0.88, 0.91))
	_message_label.position = Vector2(432.0, 619.0)
	_message_label.size = Vector2(420.0, 66.0)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud.add_child(_message_label)

	_build_touch_controls()
	_on_room_status({"fear": 0.0, "clues": {}, "order_noted": false, "lives": 3})


func _build_touch_controls() -> void:
	var controls := Control.new()
	controls.name = "TouchControls"
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(controls)

	var up := _button("▲", Vector2(62.0, 58.0), false)
	up.name = "MoveUp"
	up.position = Vector2(91.0, 486.0)
	controls.add_child(up)
	_bind_hold_button(up, "move_up")
	var left := _button("◀", Vector2(62.0, 58.0), false)
	left.name = "MoveLeft"
	left.position = Vector2(25.0, 548.0)
	controls.add_child(left)
	_bind_hold_button(left, "move_left")
	var right := _button("▶", Vector2(62.0, 58.0), false)
	right.name = "MoveRight"
	right.position = Vector2(157.0, 548.0)
	controls.add_child(right)
	_bind_hold_button(right, "move_right")
	var down := _button("▼", Vector2(62.0, 58.0), false)
	down.name = "MoveDown"
	down.position = Vector2(91.0, 610.0)
	controls.add_child(down)
	_bind_hold_button(down, "move_down")

	_interact_button = _button("PERIKSA", Vector2(156.0, 78.0), true)
	_interact_button.name = "InteractButton"
	_interact_button.position = Vector2(1092.0, 606.0)
	_interact_button.disabled = true
	_interact_button.pressed.connect(_request_interaction)
	controls.add_child(_interact_button)


func _bind_hold_button(button: Button, action: String) -> void:
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
	button.tree_exiting.connect(func() -> void: Input.action_release(action))


func _request_interaction() -> void:
	if _mode == "bermain" and _room != null and _code_layer == null and _pause_layer == null:
		_room.interact_nearest()


func _toggle_pause() -> void:
	if _mode != "bermain" or _code_layer != null:
		return
	if _pause_layer != null:
		_close_pause()
	else:
		_open_pause()


func _open_pause() -> void:
	_release_touch_actions()
	get_tree().paused = true
	_pause_layer = _full_overlay("PauseLayer", 0.78)
	var panel := _modal_panel(_pause_layer, Vector2(430.0, 350.0), Vector2(425.0, 185.0))
	var stack := _modal_stack(panel)
	stack.add_child(_label("JEDA SEJENAK", 25, Color(0.98, 0.85, 0.65)))
	var note := _label("Lorong tetap sunyi saat kau berhenti.", 15, Color(0.83, 0.8, 0.85))
	stack.add_child(note)
	var resume := _button("LANJUTKAN", Vector2(260.0, 48.0), true)
	resume.pressed.connect(_close_pause)
	stack.add_child(resume)
	var restart := _button("ULANGI RUANG", Vector2(260.0, 46.0), false)
	restart.pressed.connect(_restart_game)
	stack.add_child(restart)
	var quit := _button("KEMBALI KE JUDUL", Vector2(260.0, 46.0), false)
	quit.pressed.connect(_return_to_title)
	stack.add_child(quit)


func _close_pause() -> void:
	if _pause_layer != null:
		_pause_layer.queue_free()
		_pause_layer = null
	get_tree().paused = false


func _restart_game() -> void:
	_close_pause()
	_start_game()


func _return_to_title() -> void:
	get_tree().paused = false
	_release_touch_actions()
	_close_modal_layers()
	var store := get_node_or_null("/root/TuningStore")
	if store != null:
		store.call("end_run")
	if _room != null and is_instance_valid(_room):
		_room.queue_free()
	_room = null
	if _hud != null and is_instance_valid(_hud):
		_hud.queue_free()
		_hud = null
	_mode = "judul"
	_build_title_screen()


func _open_code_panel() -> void:
	if _mode != "bermain" or _code_layer != null or _result_layer != null:
		return
	_release_touch_actions()
	_code_entry = ""
	get_tree().paused = true
	_code_layer = _full_overlay("CodeLayer", 0.83)
	var panel := _modal_panel(_code_layer, Vector2(374.0, 536.0), Vector2(453.0, 90.0))
	var stack := _modal_stack(panel)
	stack.add_child(_label("KUNCI ANGKA", 24, Color(0.98, 0.85, 0.65)))
	var clue_note := _label("Catatan menyebut: bangku, lemari, cahaya.", 13, Color(0.82, 0.79, 0.84))
	stack.add_child(clue_note)
	_code_display = _label("_  _  _", 30, Color(1.0, 0.9, 0.72))
	_code_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_display.custom_minimum_size.y = 45.0
	stack.add_child(_code_display)
	var keypad := GridContainer.new()
	keypad.columns = 3
	keypad.add_theme_constant_override("h_separation", 8)
	keypad.add_theme_constant_override("v_separation", 8)
	stack.add_child(keypad)
	for key: String in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "OK"]:
		var digit_button := _button(key, Vector2(82.0, 55.0), key == "OK")
		digit_button.pressed.connect(_on_keypad_pressed.bind(key))
		keypad.add_child(digit_button)
	var cancel := _button("BATAL", Vector2(260.0, 44.0), false)
	cancel.pressed.connect(_close_code_panel)
	stack.add_child(cancel)
	_update_code_display()


func _on_keypad_pressed(key: String) -> void:
	if key == "OK":
		_submit_code_entry()
	elif key == "⌫":
		_code_entry = _code_entry.left(maxi(0, _code_entry.length() - 1))
		_update_code_display()
	else:
		_add_code_digit(key)


func _add_code_digit(digit: String) -> void:
	if _code_entry.length() < 3 and digit.is_valid_int():
		_code_entry += digit
		_update_code_display()


func _update_code_display() -> void:
	if _code_display == null or not is_instance_valid(_code_display):
		return
	var visible_code := _code_entry
	while visible_code.length() < 3:
		visible_code += "_"
	_code_display.text = "  ".join(visible_code.split("", false))


func _submit_code_entry() -> void:
	if _room == null:
		return
	var accepted: bool = _room.submit_code(_code_entry)
	if accepted:
		return
	_code_entry = ""
	_update_code_display()


func _close_code_panel() -> void:
	if _code_layer != null:
		_code_layer.queue_free()
		_code_layer = null
	_code_display = null
	get_tree().paused = false


func _on_room_finished(outcome: String) -> void:
	get_tree().paused = false
	_release_touch_actions()
	_close_modal_layers()
	var store := get_node_or_null("/root/TuningStore")
	if store != null:
		store.call("end_run")
	_mode = "hasil"
	_result_layer = _full_overlay("ResultLayer", 0.84)
	var panel := _modal_panel(_result_layer, Vector2(500.0, 300.0), Vector2(390.0, 205.0))
	var stack := _modal_stack(panel)
	if outcome == "menang":
		stack.add_child(_label("LORONG MEMBUKA DIRI", 23, Color(0.98, 0.86, 0.65)))
		var end_note := _label("Mika melangkah keluar. Di belakangnya, kamar itu kembali sunyi.", 15, Color(0.85, 0.82, 0.87))
		end_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(end_note)
	else:
		stack.add_child(_label("JALAN PULANG TERTUTUP", 22, Color(0.98, 0.75, 0.69)))
		var end_note := _label("Kegelapan menelan kamar sebelum Mika sempat menemukan jalan keluar.", 15, Color(0.85, 0.82, 0.87))
		end_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(end_note)
	var retry := _button("COBA LAGI", Vector2(260.0, 48.0), true)
	retry.pressed.connect(_restart_after_result)
	stack.add_child(retry)
	var menu := _button("KEMBALI KE JUDUL", Vector2(260.0, 46.0), false)
	menu.pressed.connect(_return_to_title)
	stack.add_child(menu)


func _restart_after_result() -> void:
	if _result_layer != null:
		_result_layer.queue_free()
		_result_layer = null
	_start_game()


func _on_room_message(text: String) -> void:
	if _message_label != null and is_instance_valid(_message_label):
		_message_label.text = text


func _on_room_prompt(text: String) -> void:
	if _prompt_label != null and is_instance_valid(_prompt_label):
		_prompt_label.text = text
	if _interact_button != null and is_instance_valid(_interact_button):
		_interact_button.disabled = text.is_empty()


func _on_room_status(state: Dictionary) -> void:
	if _status_label == null or not is_instance_valid(_status_label):
		return
	var clues: Dictionary = state.get("clues", {})
	var bangku := str(clues.get("bangku", "—"))
	var lemari := str(clues.get("lemari", "—"))
	var cahaya := str(clues.get("lampu", "—"))
	var order_text := "sudah ditemukan" if bool(state.get("order_noted", false)) else "belum ditemukan"
	_status_label.text = "Petunjuk: bangku %s / lemari %s / cahaya %s\nUrutan catatan: %s." % [bangku, lemari, cahaya, order_text]
	if _fear_bar != null:
		_fear_bar.value = float(state.get("fear", 0.0))
	if _lives_label != null:
		_lives_label.text = "KETENANGAN: %d" % int(state.get("lives", 3))


func _on_room_tone(alpha: float, threat_visible: bool) -> void:
	if _tint_layer == null or not is_instance_valid(_tint_layer):
		return
	var base_color := Color(0.29, 0.10, 0.34, alpha)
	if threat_visible:
		base_color = Color(0.35, 0.11, 0.25, alpha)
	_tint_layer.color = base_color


func _full_overlay(layer_name: String, shade_alpha: float) -> Control:
	var overlay := Control.new()
	overlay.name = layer_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.02, 0.04, shade_alpha)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	return overlay


func _modal_panel(parent: Control, panel_size: Vector2, panel_position: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = panel_position
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.045, 0.075, 0.98)))
	parent.add_child(panel)
	return panel


func _modal_stack(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	return stack


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _button(text: String, minimum_size: Vector2, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15 if primary else 13)
	button.add_theme_color_override("font_color", Color(0.98, 0.91, 0.79))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.87))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.26, 0.17, 0.20) if primary else Color(0.10, 0.09, 0.13)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.42, 0.24, 0.22) if primary else Color(0.19, 0.15, 0.20)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.18, 0.13, 0.18)))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.09, 0.08, 0.11)))
	button.add_theme_color_override("font_disabled_color", Color(0.53, 0.50, 0.55))
	return button


func _button_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(0.55, 0.36, 0.31, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _panel_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(0.39, 0.30, 0.34, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	return style


func _release_touch_actions() -> void:
	for action: String in _touch_actions:
		Input.action_release(action)


func _close_modal_layers() -> void:
	for layer: Control in [_pause_layer, _code_layer, _result_layer]:
		if layer != null and is_instance_valid(layer):
			layer.queue_free()
	_pause_layer = null
	_code_layer = null
	_result_layer = null
	_code_display = null


func _active_tune(id: String, fallback: float) -> float:
	var store := get_node_or_null("/root/TuningStore")
	if store == null:
		return fallback
	return float(store.call("get_active_value", id, fallback))
