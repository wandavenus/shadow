extends Control
class_name LorongGameController

const RoomComponent = preload("res://scripts/lorong/room.gd")
const COVER_ART: Texture2D = preload("res://assets/environment/desa-kampung-runtime-1280x720.png")

var _mode := "judul"
var _audio_opt_in := false
var _room: Node2D
var _title_screen: Control
var _hud: Control
var _pause_layer: Control
var _result_layer: Control
var _help_label: Label
var _main_task_label: Label
var _optional_task_label: Label
var _inventory_label: Label
var _time_weather_label: Label
var _message_label: Label
var _prompt_label: Label
var _interact_button: Button
var _title_audio_button: Button
var _hud_audio_button: Button
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
	if _mode == "bermain":
		if event.keycode in [KEY_ESCAPE, KEY_P]:
			_toggle_pause()
		elif event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_request_interaction()
		get_viewport().set_input_as_handled()


func _build_title_screen() -> void:
	_title_screen = Control.new()
	_title_screen.name = "TitleScreen"
	_title_screen.z_index = 100
	_title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_title_screen)

	var cover := TextureRect.new()
	cover.name = "CoverArt"
	cover.texture = COVER_ART
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_screen.add_child(cover)

	var shade := ColorRect.new()
	shade.name = "WarmShade"
	shade.color = Color(0.08, 0.09, 0.08, 0.22)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_screen.add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "IntroPanel"
	panel.position = Vector2(42.0, 380.0)
	panel.size = Vector2(610.0, 310.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.11, 0.08, 0.94)))
	_title_screen.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

	stack.add_child(_label("Mika di Desa Sela", 25, Color(0.98, 0.84, 0.58)))
	var intro := _label("Sapa tetangga, bantu mengantar hasil kebun, dan nikmati desa yang berubah mengikuti waktu serta cuaca. Tugas selesai? Hari tetap milikmu untuk menjelajah.", 15, Color(0.93, 0.91, 0.82))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.y = 48.0
	stack.add_child(intro)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	stack.add_child(button_row)
	var start_button := _button("MULAI BERJELAJAH", Vector2(220.0, 50.0), true)
	start_button.pressed.connect(_start_game)
	button_row.add_child(start_button)
	var help_button := _button("CARA BERMAIN", Vector2(168.0, 50.0), false)
	help_button.pressed.connect(_toggle_help)
	button_row.add_child(help_button)
	_title_audio_button = _button(_audio_toggle_text(), Vector2(125.0, 50.0), false)
	_title_audio_button.name = "AudioToggleButton"
	_title_audio_button.pressed.connect(_toggle_audio_opt_in)
	button_row.add_child(_title_audio_button)

	_help_label = _label("Gerak dengan WASD/panah atau D-pad. Dekati warga/objek, lalu tekan E, Spasi, atau BICARA / AKSI. Jam dan cuaca berubah saat bermain; tekan P atau JEDA untuk menghentikan keduanya. Tidak ada deadline atau hukuman.", 13, Color(0.85, 0.88, 0.79))
	_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help_label.visible = false
	stack.add_child(_help_label)
	stack.add_child(_label("SLICE-OF-LIFE 2.5D · DESA DAMAI · TANPA DEADLINE", 11, Color(0.72, 0.82, 0.68)))


func _toggle_help() -> void:
	if _help_label != null:
		_help_label.visible = not _help_label.visible


func _toggle_audio_opt_in() -> void:
	_audio_opt_in = not _audio_opt_in
	if _audio_opt_in:
		var audio_director := get_node_or_null("/root/AudioDirector")
		if audio_director != null:
			audio_director.call("unlock_audio")
	if _room != null and is_instance_valid(_room):
		if not bool(_room.call("set_atmosphere_audio_enabled", _audio_opt_in)):
			_audio_opt_in = false
	_refresh_audio_toggle_labels()


func _audio_toggle_text() -> String:
	return "SUARA: AKTIF" if _audio_opt_in else "SUARA: MATI"


func _refresh_audio_toggle_labels() -> void:
	if _title_audio_button != null and is_instance_valid(_title_audio_button):
		_title_audio_button.text = _audio_toggle_text()
	if _hud_audio_button != null and is_instance_valid(_hud_audio_button):
		_hud_audio_button.text = _audio_toggle_text()


func _start_game() -> void:
	get_tree().paused = false
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null and _audio_opt_in:
		audio_director.call("unlock_audio")
	_release_touch_actions()
	_close_modal_layers()
	if _title_screen != null and is_instance_valid(_title_screen):
		_title_screen.queue_free()
		_title_screen = null
	_title_audio_button = null
	if _hud != null and is_instance_valid(_hud):
		_hud.queue_free()
		_hud = null
	_hud_audio_button = null
	if _room != null and is_instance_valid(_room):
		_room.call("shutdown_atmosphere_audio")
		_room.queue_free()
		_room = null
	var store := get_node_or_null("/root/TuningStore")
	if store != null:
		store.call("begin_run", false)
	_room = RoomComponent.new() as Node2D
	_room.name = "Room"
	_room.process_mode = Node.PROCESS_MODE_PAUSABLE
	_room.connect("message_changed", Callable(self, "_on_room_message"))
	_room.connect("prompt_changed", Callable(self, "_on_room_prompt"))
	_room.connect("status_changed", Callable(self, "_on_room_status"))
	_room.connect("game_finished", Callable(self, "_on_room_finished"))
	add_child(_room)
	_build_hud()
	_mode = "bermain"
	_room.call("start_run", _audio_opt_in)


func _build_hud() -> void:
	_hud = Control.new()
	_hud.name = "HUD"
	_hud.z_index = 100
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hud)

	var status_back := ColorRect.new()
	status_back.name = "StatusBack"
	status_back.position = Vector2(22.0, 18.0)
	status_back.size = Vector2(520.0, 190.0)
	status_back.color = Color(0.055, 0.075, 0.055, 0.83)
	status_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(status_back)

	var brand := _label("LORONG SUNYI · DESA", 21, Color(0.98, 0.84, 0.58))
	brand.position = Vector2(40.0, 26.0)
	brand.size = Vector2(460.0, 34.0)
	_hud.add_child(brand)

	_main_task_label = _label("TUGAS UTAMA\nTemui Pak Ranu untuk memulai.", 14, Color(0.95, 0.93, 0.83))
	_main_task_label.position = Vector2(40.0, 66.0)
	_main_task_label.size = Vector2(478.0, 47.0)
	_main_task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.add_child(_main_task_label)

	_optional_task_label = _label("OPSIONAL · Temui Nara jika ingin membantu Lio.", 12, Color(0.83, 0.90, 0.74))
	_optional_task_label.position = Vector2(40.0, 117.0)
	_optional_task_label.size = Vector2(478.0, 36.0)
	_optional_task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.add_child(_optional_task_label)

	_inventory_label = _label("Bawaan: kosong", 12, Color(0.92, 0.82, 0.62))
	_inventory_label.position = Vector2(40.0, 164.0)
	_inventory_label.size = Vector2(300.0, 22.0)
	_hud.add_child(_inventory_label)

	_time_weather_label = _label("06:00 · CERAH", 17, Color(0.98, 0.91, 0.70))
	_time_weather_label.position = Vector2(908.0, 25.0)
	_time_weather_label.size = Vector2(230.0, 40.0)
	_time_weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud.add_child(_time_weather_label)

	var pause_button := _button("JEDA", Vector2(96.0, 46.0), false)
	pause_button.name = "PauseButton"
	pause_button.position = Vector2(1158.0, 24.0)
	pause_button.pressed.connect(_toggle_pause)
	_hud.add_child(pause_button)
	_hud_audio_button = _button(_audio_toggle_text(), Vector2(150.0, 38.0), false)
	_hud_audio_button.name = "AudioToggleButton"
	_hud_audio_button.position = Vector2(1008.0, 79.0)
	_hud_audio_button.add_theme_font_size_override("font_size", 12)
	_hud_audio_button.pressed.connect(_toggle_audio_opt_in)
	_hud.add_child(_hud_audio_button)

	var prompt_back := ColorRect.new()
	prompt_back.position = Vector2(400.0, 570.0)
	prompt_back.size = Vector2(480.0, 34.0)
	prompt_back.color = Color(0.055, 0.075, 0.055, 0.78)
	prompt_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(prompt_back)
	_prompt_label = _label("", 14, Color(1.0, 0.86, 0.58))
	_prompt_label.position = Vector2(410.0, 575.0)
	_prompt_label.size = Vector2(460.0, 24.0)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(_prompt_label)

	var message_back := ColorRect.new()
	message_back.position = Vector2(390.0, 608.0)
	message_back.size = Vector2(500.0, 84.0)
	message_back.color = Color(0.055, 0.075, 0.055, 0.84)
	message_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(message_back)
	_message_label = _label("Dekati warga atau objek kecil untuk berinteraksi.", 14, Color(0.93, 0.92, 0.84))
	_message_label.position = Vector2(406.0, 615.0)
	_message_label.size = Vector2(468.0, 70.0)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud.add_child(_message_label)

	_build_touch_controls()


func _build_touch_controls() -> void:
	var controls := Control.new()
	controls.name = "TouchControls"
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(controls)

	var up := _button("▲", Vector2(78.0, 72.0), false)
	up.name = "MoveUp"
	up.position = Vector2(96.0, 462.0)
	up.add_theme_font_size_override("font_size", 24)
	controls.add_child(up)
	_bind_hold_button(up, "move_up")

	var left := _button("◀", Vector2(78.0, 72.0), false)
	left.name = "MoveLeft"
	left.position = Vector2(12.0, 540.0)
	left.add_theme_font_size_override("font_size", 24)
	controls.add_child(left)
	_bind_hold_button(left, "move_left")

	var right := _button("▶", Vector2(78.0, 72.0), false)
	right.name = "MoveRight"
	right.position = Vector2(180.0, 540.0)
	right.add_theme_font_size_override("font_size", 24)
	controls.add_child(right)
	_bind_hold_button(right, "move_right")

	var down := _button("▼", Vector2(78.0, 72.0), false)
	down.name = "MoveDown"
	down.position = Vector2(96.0, 618.0)
	down.add_theme_font_size_override("font_size", 24)
	controls.add_child(down)
	_bind_hold_button(down, "move_down")

	_interact_button = _button("BICARA / AKSI", Vector2(172.0, 78.0), true)
	_interact_button.name = "InteractButton"
	_interact_button.position = Vector2(1080.0, 606.0)
	_interact_button.disabled = true
	_interact_button.pressed.connect(_request_interaction)
	controls.add_child(_interact_button)


func _bind_hold_button(button: Button, action: String) -> void:
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
	button.tree_exiting.connect(func() -> void: Input.action_release(action))


func _request_interaction() -> void:
	if _mode == "bermain" and _room != null and is_instance_valid(_room):
		_room.call("interact_nearest")


func _toggle_pause() -> void:
	if _mode == "jeda":
		_close_pause()
	elif _mode == "bermain":
		_open_pause()


func _open_pause() -> void:
	_release_touch_actions()
	_mode = "jeda"
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null:
		audio_director.call("set_game_paused", true)
	get_tree().paused = true
	_pause_layer = _full_overlay("PauseLayer", 0.68)
	var panel := _modal_panel(_pause_layer, Vector2(460.0, 350.0), Vector2(410.0, 185.0))
	var stack := _modal_stack(panel)
	stack.add_child(_label("JEDA SEJENAK", 25, Color(0.98, 0.85, 0.62)))
	var note := _label("Jam, cuaca, dan rutinitas warga berhenti sampai kamu siap melanjutkan. Tidak ada deadline.", 15, Color(0.88, 0.89, 0.80))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.y = 46.0
	stack.add_child(note)
	var resume := _button("LANJUTKAN", Vector2(270.0, 48.0), true)
	resume.pressed.connect(_close_pause)
	stack.add_child(resume)
	var restart := _button("ULANGI HARI", Vector2(270.0, 46.0), false)
	restart.pressed.connect(_restart_game)
	stack.add_child(restart)
	var quit := _button("KEMBALI KE JUDUL", Vector2(270.0, 46.0), false)
	quit.pressed.connect(_return_to_title)
	stack.add_child(quit)


func _close_pause() -> void:
	if _pause_layer != null and is_instance_valid(_pause_layer):
		_pause_layer.queue_free()
		_pause_layer = null
	_mode = "bermain"
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null:
		audio_director.call("set_game_paused", false)
	get_tree().paused = false


func _restart_game() -> void:
	get_tree().paused = false
	if _pause_layer != null and is_instance_valid(_pause_layer):
		_pause_layer.queue_free()
		_pause_layer = null
	_mode = "bermain"
	_start_game()


func _return_to_title() -> void:
	get_tree().paused = false
	_release_touch_actions()
	_close_modal_layers()
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null:
		audio_director.call("set_game_paused", false)
	var store := get_node_or_null("/root/TuningStore")
	if store != null:
		store.call("end_run")
	if _room != null and is_instance_valid(_room):
		_room.call("shutdown_atmosphere_audio")
		_room.queue_free()
	_room = null
	if _hud != null and is_instance_valid(_hud):
		_hud.queue_free()
		_hud = null
	_hud_audio_button = null
	_mode = "judul"
	_build_title_screen()


func _on_room_message(text: String) -> void:
	if _message_label != null and is_instance_valid(_message_label):
		_message_label.text = text


func _on_room_prompt(text: String) -> void:
	if _prompt_label != null and is_instance_valid(_prompt_label):
		_prompt_label.text = text
	if _interact_button != null and is_instance_valid(_interact_button):
		_interact_button.disabled = text.is_empty()


func _on_room_status(state: Dictionary) -> void:
	if _main_task_label != null and is_instance_valid(_main_task_label):
		var main_prefix := "TUGAS UTAMA SELESAI" if bool(state.get("main_complete", false)) else "TUGAS UTAMA"
		_main_task_label.text = "%s\n%s" % [main_prefix, str(state.get("main_objective", ""))]
	if _optional_task_label != null and is_instance_valid(_optional_task_label):
		var optional_prefix := "OPSIONAL SELESAI" if bool(state.get("optional_complete", false)) else "OPSIONAL"
		_optional_task_label.text = "%s · %s" % [optional_prefix, str(state.get("optional_objective", ""))]
	if _inventory_label != null and is_instance_valid(_inventory_label):
		_inventory_label.text = str(state.get("inventory_text", "Bawaan: kosong"))
	if _time_weather_label != null and is_instance_valid(_time_weather_label):
		_time_weather_label.text = "%s · %s" % [str(state.get("time_label", "06:00")), str(state.get("weather_label", "CERAH"))]


func _on_room_finished(outcome: String) -> void:
	if outcome != "selesai_damai" or _mode != "bermain":
		return
	_release_touch_actions()
	_mode = "selesai"
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null:
		audio_director.call("set_game_paused", true)
	get_tree().paused = true
	_result_layer = _full_overlay("VillageFinishLayer", 0.62)
	var panel := _modal_panel(_result_layer, Vector2(540.0, 320.0), Vector2(370.0, 198.0))
	var stack := _modal_stack(panel)
	stack.add_child(_label("HARI YANG LEBIH RINGAN", 24, Color(0.98, 0.85, 0.62)))
	var note := _label("Tugas utama selesai karena warga saling membantu. Tidak ada akhir paksa—desa tetap terbuka untuk dijelajahi.", 15, Color(0.88, 0.89, 0.80))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.y = 48.0
	stack.add_child(note)
	var continue_button := _button("LANJUT JELAJAH", Vector2(285.0, 48.0), true)
	continue_button.pressed.connect(_resume_free_exploration)
	stack.add_child(continue_button)
	var menu_button := _button("KEMBALI KE JUDUL", Vector2(285.0, 46.0), false)
	menu_button.pressed.connect(_return_to_title)
	stack.add_child(menu_button)


func _resume_free_exploration() -> void:
	if _result_layer != null and is_instance_valid(_result_layer):
		_result_layer.queue_free()
		_result_layer = null
	_mode = "bermain"
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null:
		audio_director.call("set_game_paused", false)
	get_tree().paused = false


func _full_overlay(layer_name: String, shade_alpha: float) -> Control:
	var layer := Control.new()
	layer.name = layer_name
	layer.z_index = 200
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0.045, 0.06, 0.045, shade_alpha)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(shade)
	return layer


func _modal_panel(parent: Control, size: Vector2, position: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = size
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.085, 0.105, 0.08, 0.97)))
	parent.add_child(panel)
	return panel


func _modal_stack(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)
	return stack


func _close_modal_layers() -> void:
	for layer: Control in [_pause_layer, _result_layer]:
		if layer != null and is_instance_valid(layer):
			layer.queue_free()
	_pause_layer = null
	_result_layer = null


func _release_touch_actions() -> void:
	for action: String in _touch_actions:
		Input.action_release(action)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.05, 0.06, 0.04, 0.82))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _button(text: String, size: Vector2, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.size = size
	button.custom_minimum_size = size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14)
	var normal_color := Color(0.27, 0.34, 0.23, 0.97) if primary else Color(0.15, 0.20, 0.15, 0.96)
	var hover_color := Color(0.38, 0.45, 0.28, 1.0) if primary else Color(0.23, 0.31, 0.22, 1.0)
	var pressed_color := Color(0.20, 0.28, 0.18, 1.0) if primary else Color(0.11, 0.16, 0.11, 1.0)
	var disabled := Color(0.15, 0.17, 0.14, 0.74)
	button.add_theme_stylebox_override("normal", _panel_style(normal_color))
	button.add_theme_stylebox_override("hover", _panel_style(hover_color))
	button.add_theme_stylebox_override("pressed", _panel_style(pressed_color))
	button.add_theme_stylebox_override("disabled", _panel_style(disabled))
	button.add_theme_color_override("font_color", Color(0.98, 0.95, 0.83))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.89))
	button.add_theme_color_override("font_disabled_color", Color(0.66, 0.68, 0.61))
	return button


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.66, 0.59, 0.37, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


func _active_tune(id: String, fallback: float) -> float:
	var store := get_node_or_null("/root/TuningStore")
	if store == null:
		return fallback
	return float(store.call("get_active_value", id, fallback))
