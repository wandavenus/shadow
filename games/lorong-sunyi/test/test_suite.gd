extends Node

var _failures := PackedStringArray()
var _checks := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var i18n: Node = get_tree().root.get_node_or_null("I18n")
	var tuning: Node = get_tree().root.get_node_or_null("TuningStore")
	var bridge: Node = get_tree().root.get_node_or_null("TuningBridge")
	_check(i18n != null, "autoload I18n harus tersedia")
	_check(tuning != null, "autoload TuningStore harus tersedia")
	_check(bridge != null, "adapter Tweak harus tersedia pada build pengembangan")
	if i18n == null or tuning == null or bridge == null:
		_finish()
		return

	_test_language(i18n)
	_test_tuning(tuning, bridge, i18n)
	await _test_controller()
	await _test_room(tuning)
	if _failures.is_empty():
		print("[lorong-sunyi-tests] PASS: %d checks" % _checks)
	else:
		for failure: String in _failures:
			push_error("[lorong-sunyi-tests] " + failure)
		print("[lorong-sunyi-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
	var audio_director := get_tree().root.get_node_or_null("AudioDirector")
	if audio_director != null:
		audio_director.call("release_streams")
	await get_tree().process_frame
	get_tree().quit(0 if _failures.is_empty() else 1)


func _test_language(i18n: Node) -> void:
	_check(str(i18n.call("get_locale")) == "id-ID", "Bahasa Indonesia harus dipatok")
	_check(str(i18n.call("detect_locale", "en_US")) == "id-ID", "locale OS tidak boleh mengganti bahasa game")
	_check(str(i18n.call("resolve_locale", "zh-CN", "en_US")) == "id-ID", "locale tersimpan tidak boleh mengganti bahasa game")
	i18n.call("set_locale", "en")
	i18n.call("toggle_locale")
	_check(str(i18n.call("get_locale")) == "id-ID", "game tidak boleh menyediakan pergantian bahasa")
	_check(str(i18n.call("t", "language.name")) == "Bahasa Indonesia", "katalog id-ID harus dimuat")
	_check(i18n.call("catalog_keys", "en").is_empty(), "katalog bahasa lain tidak boleh aktif")


func _test_tuning(tuning: Node, bridge: Node, i18n: Node) -> void:
	var settings: Array = tuning.call("get_settings")
	_check(not settings.is_empty(), "pengaturan game harus tersedia")
	for setting_value: Variant in settings:
		var setting: Dictionary = setting_value
		var id := str(setting.get("id", ""))
		var label := str(i18n.call("t", str(setting.get("label_key", ""))))
		var description := str(i18n.call("t", str(setting.get("description_key", ""))))
		_check(not label.begins_with("tuning."), "label Tweak belum diterjemahkan: " + id)
		_check(not description.begins_with("tuning."), "deskripsi Tweak belum diterjemahkan: " + id)
		var control: Dictionary = bridge.call("control_for", setting)
		_check(str(control.get("label", "")) == label, "adapter harus mempertahankan label Bahasa Indonesia: " + id)
		if str(control.get("applyMode", "LIVE")) != "LIVE":
			_check(not str(control.get("description", "")).contains("Next "), "suffix waktu Tweak tidak boleh berbahasa Inggris: " + id)

	tuning.call("end_run")
	tuning.call("reset_defaults")
	_check(not bool(tuning.call("set_value", "player.move.max_speed", 9999.0)), "nilai kecepatan di luar batas harus ditolak")
	_check(is_equal_approx(float(tuning.call("get_active_value", "player.move.max_speed")), 170.0), "nilai yang ditolak tidak boleh mengubah kecepatan")
	_check(bool(tuning.call("set_value", "ui.reduced_motion", true)), "preferensi reduced motion harus dapat diaktifkan")
	_check(bool(tuning.call("get_active_value", "ui.reduced_motion")), "preferensi reduced motion harus langsung aktif")
	tuning.call("reset_defaults")
	_check(not bool(tuning.call("get_active_value", "ui.reduced_motion")), "reset harus mengembalikan preferensi visual default")


func _test_controller() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	_check(scene != null, "scene utama harus dapat dimuat")
	if scene == null:
		return
	var main := scene.instantiate() as Control
	main.name = "MainUnderTest"
	get_tree().root.add_child(main)
	await get_tree().process_frame
	_check(main.get_node_or_null("TitleScreen") != null, "layar judul harus muncul")
	var title_audio := _find_named_node(main, "AudioToggleButton") as Button
	_check(title_audio != null and title_audio.text == "SUARA: MATI", "suara harus nonaktif secara default dan punya toggle eksplisit")
	main.call("_start_game")
	await get_tree().process_frame

	var room := main.get("_room") as Node2D
	var touch_controls := main.get_node_or_null("HUD/TouchControls")
	_check(room != null, "room desa harus aktif setelah mulai")
	_check(touch_controls != null, "kontrol sentuh harus aktif pada HUD")
	for button_name: String in ["MoveUp", "MoveDown", "MoveLeft", "MoveRight", "InteractButton"]:
		_check(touch_controls != null and touch_controls.get_node_or_null(button_name) is Button, "tombol sentuh hilang: " + button_name)
	for button_name: String in ["MoveUp", "MoveDown", "MoveLeft", "MoveRight"]:
		var dpad_button := touch_controls.get_node_or_null(button_name) as Button if touch_controls != null else null
		_check(dpad_button != null and dpad_button.size.x >= 78.0 and dpad_button.size.y >= 72.0, "area sentuh D-pad harus cukup besar: " + button_name)
	_check(InputMap.has_action("move_left") and InputMap.has_action("move_down"), "aksi gerak keyboard harus tersedia")
	var move_down_bound := false
	for event: InputEvent in InputMap.action_get_events("move_down"):
		if event is InputEventKey and (event.physical_keycode in [KEY_S, KEY_DOWN] or event.keycode in [KEY_S, KEY_DOWN]):
			move_down_bound = true
	_check(move_down_bound, "move_down harus punya binding S atau panah bawah")

	var move_up_button := touch_controls.get_node_or_null("MoveUp") as Button if touch_controls != null else null
	if move_up_button != null:
		move_up_button.button_down.emit()
		_check(Input.is_action_pressed("move_up"), "D-pad harus mengaktifkan input saat ditekan")
		move_up_button.button_up.emit()
		_check(not Input.is_action_pressed("move_up"), "D-pad harus melepas input saat tombol dilepas")

	var controller_audio := main.get_node_or_null("HUD/AudioToggleButton") as Button
	_check(controller_audio != null and controller_audio.text == "SUARA: MATI", "HUD harus menampilkan kondisi suara default")
	if room != null:
		var initial: Dictionary = room.call("snapshot_for_testing")
		_check(not bool(initial.get("audio_enabled", true)), "helper audio tidak boleh menyala tanpa pilihan")
		var player := room.get("player") as CharacterBody2D
		if player != null:
			player.global_position = room.call("npc_position_for_testing", "pak_ranu")
			room.call("_update_interaction_prompt", true)
		var interact_button := touch_controls.get_node_or_null("InteractButton") as Button if touch_controls != null else null
		if interact_button != null:
			interact_button.pressed.emit()
			_check(int(room.call("snapshot_for_testing").get("main_task_step", 0)) == 1, "tombol aksi touch harus memulai tugas warga")
		if controller_audio != null:
			controller_audio.pressed.emit()
			_check(bool(room.call("snapshot_for_testing").get("audio_enabled", false)), "helper hanya aktif setelah toggle suara dipilih")
			controller_audio.pressed.emit()
			_check(not bool(room.call("snapshot_for_testing").get("audio_enabled", true)), "toggle harus dapat mematikan helper kembali")
		var before_pause: Dictionary = room.call("snapshot_for_testing")
		main.call("_open_pause")
		_check(get_tree().paused, "jeda harus menghentikan SceneTree")
		room.call("advance_simulation_for_testing", 180.0)
		var while_paused: Dictionary = room.call("snapshot_for_testing")
		_check(is_equal_approx(float(before_pause.get("time_of_day", 0.0)), float(while_paused.get("time_of_day", -1.0))), "jam tidak boleh bergerak saat jeda")
		_check(is_equal_approx(float(before_pause.get("weather_elapsed", 0.0)), float(while_paused.get("weather_elapsed", -1.0))), "cuaca tidak boleh berubah saat jeda")
		main.call("_close_pause")
		_check(not get_tree().paused, "lanjutkan harus membuka jeda")
		room.call("advance_simulation_for_testing", 60.0)
		_check(not is_equal_approx(float(before_pause.get("time_of_day", 0.0)), float(room.call("snapshot_for_testing").get("time_of_day", 0.0))), "jam harus berjalan lagi setelah jeda ditutup")

	_check(int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)) == 0, "orientasi Android harus tetap lanskap")
	main.call("_return_to_title")
	await get_tree().process_frame
	main.queue_free()
	await get_tree().process_frame
	get_tree().paused = false


func _test_room(tuning: Node) -> void:
	var room_script: Script = load("res://scripts/lorong/room.gd")
	_check(room_script != null, "controller ruang harus dapat dimuat")
	if room_script == null:
		return
	var room := room_script.new() as Node2D
	room.name = "RoomUnderTest"
	get_tree().root.add_child(room)
	await get_tree().process_frame
	var finished_outcomes: Array[String] = []
	room.connect("game_finished", func(outcome: String) -> void: finished_outcomes.append(outcome))
	room.call("start_run")

	var initial: Dictionary = room.call("snapshot_for_testing")
	_check(initial.get("npc_ids", []).size() == 5, "desa harus memiliki lima warga bernama")
	for villager_id: String in ["pak_ranu", "bu_sari", "nara", "pak_jati", "lio"]:
		_check(villager_id in initial.get("npc_ids", []), "warga hilang: " + villager_id)
	_check(int(initial.get("routine_count", 0)) == 2, "dua warga harus memiliki rutinitas bergerak")
	_check(str(initial.get("daypart", "")) == "morning", "run harus dimulai pada daypart morning")
	_check(str(initial.get("weather_state", "")) == "clear", "run harus dimulai dengan weather clear")
	_check(str(initial.get("time_label", "")) == "06:00", "jam awal harus ditampilkan sebagai 06:00")
	_check(bool(initial.get("audio_configured", false)), "helper audio harus tersedia dalam mode opt-in")
	_check(not bool(initial.get("audio_enabled", true)), "helper audio harus nonaktif sampai pemain memilihnya")
	var opening_message := str(initial.get("last_message", ""))
	_check(not opening_message.to_lower().contains("pagi"), "pesan pembuka run harus netral terhadap waktu")

	var background := room.get_node_or_null("VillageBackground") as Sprite2D
	_check(background != null and background.texture != null, "latar runtime desa harus dimuat")
	if background != null and background.texture != null:
		_check(background.texture.resource_path.ends_with("desa-kampung-runtime-1280x720.png"), "room harus menggunakan turunan runtime 1280×720")

		var expected_species := {
			"pak_ranu": "goat", "bu_sari": "cat", "nara": "rabbit", "pak_jati": "bear", "lio": "dog",
		}
		var npc_visuals: Dictionary = room.get("_npc_visuals")
		var npc_actors: Dictionary = room.get("_npc_nodes")
		_check(npc_visuals.size() == 5, "seluruh warga harus punya visual rig sendiri")
		for villager_id: String in expected_species:
			var visual := npc_visuals.get(villager_id) as Node
			var actor := npc_actors.get(villager_id) as Node2D
			_check(visual != null, "visual warga hilang: " + villager_id)
			_check(actor != null and actor.get_node_or_null("CharacterVisual/BodySprite") is Sprite2D, "path fokus harus menemukan BodySprite pada rig: " + villager_id)
			if visual == null:
				continue
			var visual_state: Dictionary = visual.call("animation_snapshot_for_testing")
			_check(str(visual_state.get("species", "")) == str(expected_species[villager_id]), "spesies visual salah: " + villager_id)
			_check(bool(visual_state.get("has_tail", false)), "ekor animated harus ada: " + villager_id)
			_check(int(visual_state.get("limb_count", 0)) == 4, "rig harus menganimasikan dua lengan dan dua kaki: " + villager_id)
			_check(Vector2(visual_state.get("texture_size", Vector2.ZERO)) == Vector2(384.0, 576.0), "sprite runtime harus berukuran ringan 384×576: " + villager_id)
			_check(not str(visual_state.get("name_text", "")).is_empty(), "name tag harus memuat nama: " + villager_id)
			_check(not str(visual_state.get("activity_text", "")).is_empty(), "name tag harus memuat peran/aktivitas: " + villager_id)
			_check(Vector2(visual_state.get("name_tag_size", Vector2.ZERO)).x >= 180.0 and int(visual_state.get("name_font_size", 0)) >= 14, "name tag harus kontras dan terbaca: " + villager_id)

		var player := room.get("player") as CharacterBody2D
		var ranu_actor := npc_actors.get("pak_ranu") as Node2D
		var ranu_body := ranu_actor.get_node_or_null("CharacterVisual/BodySprite") as Sprite2D if ranu_actor != null else null
		if player != null and ranu_actor != null and ranu_body != null:
			var player_start_position := player.global_position
			player.global_position = ranu_actor.global_position + Vector2(1000.0, 0.0)
			room.call("_update_interaction_prompt", true)
			var unfocused_scale := ranu_body.scale.x
			player.global_position = ranu_actor.global_position
			room.call("_update_interaction_prompt", true)
			_check(str(room.call("snapshot_for_testing").get("focused_target_id", "")) == "pak_ranu", "fokus terdekat harus memilih warga yang didekati")
			_check(ranu_body.scale.x > unfocused_scale, "zoom fokus harus mengubah BodySprite melalui CharacterVisual")
			player.global_position = player_start_position
			room.call("_update_interaction_prompt", true)
			_check(is_equal_approx(ranu_body.scale.x, unfocused_scale), "zoom harus kembali normal setelah fokus dilepas")
		var player_visual := player.get_node_or_null("CharacterVisual") as Node if player != null else null
		_check(player_visual != null, "Mika harus memakai visual rig karakter bersama")
		if player_visual != null:
			var mika_visual_state: Dictionary = player_visual.call("animation_snapshot_for_testing")
			_check(str(mika_visual_state.get("species", "")) == "fox" and str(mika_visual_state.get("name_text", "")) == "Mika", "Mika harus tampil sebagai humanoid rubah dengan name tag")
			player_visual.call("advance_animation_for_testing", 0.1)
			player_visual.call("set_moving", true)
			player_visual.call("advance_animation_for_testing", 0.3)
			var walk_state: Dictionary = player_visual.call("animation_snapshot_for_testing")
			_check(str(walk_state.get("state", "")) == "walk", "visual karakter harus memiliki state berjalan")
			_check(absf(float(walk_state.get("tail_rotation", 0.0))) > 0.05 and absf(float(walk_state.get("body_rotation", 0.0))) > 0.001, "jalan harus menganimasikan badan dan ekor secara terlihat")
			_check(absf(float(walk_state.get("arm_swing", 0.0))) > 1.0 and absf(float(walk_state.get("leg_swing", 0.0))) > 1.0, "jalan harus mengayunkan lengan dan kaki secara nyata")
			player_visual.call("set_moving", false)
			player_visual.call("advance_animation_for_testing", 0.2)
			var idle_state: Dictionary = player_visual.call("animation_snapshot_for_testing")
			_check(str(idle_state.get("state", "")) == "idle", "visual karakter harus kembali ke state idle")
			_check(absf(float(idle_state.get("leg_swing", 1.0))) < 0.01, "kaki harus diam pada pose idle")
			player_visual.call("set_reduced_motion", true)
			player_visual.call("advance_animation_for_testing", 0.2)
			_check(is_zero_approx(float(player_visual.call("animation_snapshot_for_testing").get("body_rotation", 1.0))), "reduced-motion harus meredam animasi badan")
			var reduced_state: Dictionary = player_visual.call("animation_snapshot_for_testing")
			_check(is_zero_approx(float(reduced_state.get("arm_swing", 1.0))) and is_zero_approx(float(reduced_state.get("leg_swing", 1.0))), "reduced-motion harus menghentikan ayunan anggota tubuh")
			player_visual.call("set_reduced_motion", false)

	var visual_api: Dictionary = initial.get("visual_api", {})
	for method_name: String in ["time", "weather", "conditions", "dusk", "fireflies", "window_glow", "reduced_motion"]:
		_check(bool(visual_api.get(method_name, false)), "API visual desa tidak tersedia: " + method_name)
	var hooks: Dictionary = initial.get("visual_hook_calls", {})
	_check(int(hooks.get("set_village_conditions", 0)) >= 1, "visual layer harus menerima pasangan kondisi awal")
	_check(int(hooks.get("set_time_of_day", 0)) >= 1, "visual layer harus menerima waktu awal")

	var effects := room.get("_effects_director") as Node
	_check(effects != null, "EffectsDirector desa harus aktif")
	if effects != null:
		var visual_snapshot: Dictionary = effects.call("debug_snapshot")
		_check(str(visual_snapshot.get("day_phase", "")) == "morning", "visual day phase harus cocok dengan core")
		_check(str(visual_snapshot.get("weather", "")) == "clear", "visual weather harus cocok dengan core")
		_check(is_equal_approx(float(visual_snapshot.get("time_of_day", -1.0)), 6.0), "jam visual harus sama dengan jam inti")

	var helper := room.get("_atmosphere_audio") as Object
	_check(helper != null, "helper audio harus dikonfigurasi tetapi opt-in")
	if helper != null:
		_check(str(helper.get("_daypart")) == "morning" and str(helper.get("_weather")) == "clear", "audio menerima baseline awal meski tidak aktif")

	var activity_morning := str((initial.get("npc_activities", {}) as Dictionary).get("pak_ranu", ""))
	var ranu_morning_position: Vector2 = room.call("npc_position_for_testing", "pak_ranu")
	var ranu_morning_target: Vector2 = room.call("npc_routine_target_for_testing", "pak_ranu")
	room.call("advance_time_for_testing", 300.0)
	var at_day: Dictionary = room.call("snapshot_for_testing")
	_check(str(at_day.get("daypart", "")) == "day", "jam yang bergerak harus memindahkan state ke day")
	_check(str(at_day.get("time_label", "")) == "11:00", "jam harus maju satu menit game per detik nyata")
	_check(str((at_day.get("npc_activities", {}) as Dictionary).get("pak_ranu", "")) != activity_morning, "perubahan daypart harus mengubah aktivitas warga")
	var ranu_day_target: Vector2 = room.call("npc_routine_target_for_testing", "pak_ranu")
	_check(ranu_day_target != ranu_morning_target, "daypart harus mengganti titik tujuan rutinitas Pak Ranu")
	room.call("advance_simulation_for_testing", 0.5)
	var ranu_after_day: Vector2 = room.call("npc_position_for_testing", "pak_ranu")
	_check(ranu_after_day.distance_to(ranu_morning_position) > 0.1, "rutinitas day harus benar-benar mengubah posisi Pak Ranu")
	_check(ranu_after_day.distance_to(ranu_day_target) < ranu_morning_position.distance_to(ranu_day_target), "Pak Ranu harus bergerak menuju titik rutinitas day")
	if effects != null:
		var day_visual: Dictionary = effects.call("debug_snapshot")
		_check(str(day_visual.get("day_phase", "")) == "day", "visual day phase harus mengikuti core")
		_check(is_equal_approx(float(day_visual.get("time_of_day", -1.0)), 11.0), "visual harus mempertahankan jam inti yang presisi")
	if helper != null:
		_check(str(helper.get("_daypart")) == "day", "audio daypart harus berubah saat jam berganti")

	room.call("set_weather_for_testing", "rain")
	var at_rain: Dictionary = room.call("snapshot_for_testing")
	_check(str(at_rain.get("weather_state", "")) == "rain", "state hujan harus dapat diaktifkan")
	_check(str((at_rain.get("npc_activities", {}) as Dictionary).get("pak_ranu", "")).contains("berteduh"), "hujan harus mengubah rutinitas Pak Ranu")
	var ranu_rain_target: Vector2 = room.call("npc_routine_target_for_testing", "pak_ranu")
	var ranu_before_rain_step: Vector2 = room.call("npc_position_for_testing", "pak_ranu")
	_check(ranu_rain_target.distance_to(ranu_day_target) > 100.0, "hujan harus memilih lokasi rutinitas berbeda dari siang cerah")
	room.call("advance_simulation_for_testing", 0.5)
	var ranu_after_rain_step: Vector2 = room.call("npc_position_for_testing", "pak_ranu")
	_check(ranu_after_rain_step.distance_to(ranu_before_rain_step) > 0.1, "rutinitas rain harus mengubah posisi Pak Ranu")
	_check(ranu_after_rain_step.distance_to(ranu_rain_target) < ranu_before_rain_step.distance_to(ranu_rain_target), "Pak Ranu harus bergerak menuju lokasi berteduh")
	_check(int((at_rain.get("visual_hook_calls", {}) as Dictionary).get("set_village_conditions", 0)) > int(hooks.get("set_village_conditions", 0)), "perubahan cuaca harus dikirim ke visual conditions")
	if effects != null:
		_check(str(effects.call("debug_snapshot").get("weather", "")) == "rain", "visual weather harus menerima hujan")
	if helper != null:
		_check(str(helper.get("_weather")) == "rain", "audio weather harus menerima hujan meski opt-in mati")

	var before_pause: Dictionary = room.call("snapshot_for_testing")
	get_tree().paused = true
	room.call("advance_simulation_for_testing", 120.0)
	get_tree().paused = false
	var after_pause: Dictionary = room.call("snapshot_for_testing")
	_check(is_equal_approx(float(before_pause.get("time_of_day", 0.0)), float(after_pause.get("time_of_day", -1.0))), "clock harus berhenti saat SceneTree paused")
	_check(is_equal_approx(float(before_pause.get("weather_elapsed", 0.0)), float(after_pause.get("weather_elapsed", -1.0))), "weather cycle harus berhenti saat SceneTree paused")

	room.call("start_run")
	helper = room.get("_atmosphere_audio") as Object
	room.call("advance_simulation_for_testing", 52.0)
	_check(str(room.call("snapshot_for_testing").get("weather_state", "")) == "cloudy", "weather cycle harus berubah dari clear ke cloudy")
	room.call("advance_simulation_for_testing", 46.0)
	_check(str(room.call("snapshot_for_testing").get("weather_state", "")) == "rain", "weather cycle harus berubah dari cloudy ke rain")
	room.call("advance_simulation_for_testing", 42.0)
	var wind_state: Dictionary = room.call("snapshot_for_testing")
	_check(str(wind_state.get("weather_state", "")) == "wind", "weather cycle harus memiliki state wind")
	_check(int(wind_state.get("weather_transition_count", 0)) == 3, "tiga perubahan cuaca harus tercatat sebagai state gameplay")
	_check(str((wind_state.get("npc_activities", {}) as Dictionary).get("lio", "")).contains("daun"), "angin harus mengubah aktivitas Lio")
	if effects != null:
		var wind_visual: Dictionary = effects.call("debug_snapshot")
		_check(str(wind_visual.get("weather", "")) == "wind" and bool(wind_visual.get("wind_particles_active", false)), "visual layer harus merender cuaca berangin")
	if helper != null:
		_check(str(helper.get("_weather")) == "wind", "audio menerima state wind")
	var cycle_hooks: Dictionary = wind_state.get("visual_hook_calls", {})
	_check(int(cycle_hooks.get("set_village_conditions", 0)) >= 4, "visual conditions harus menerima state awal dan transisi cuaca")

	_check(bool(tuning.call("set_value", "ui.reduced_motion", true)), "reduced motion harus dapat diaktifkan")
	room.call("_update_tuning", true)
	_check(bool(room.call("snapshot_for_testing").get("reduced_motion", false)), "room harus menghormati preferensi reduced motion")
	if effects != null:
		_check(bool(effects.call("debug_snapshot").get("reduced_motion", false)), "visual layer harus menghormati reduced motion")
	tuning.call("set_value", "ui.reduced_motion", false)
	room.call("_update_tuning", true)

	room.call("start_run")
	var dialogue_messages: Array[String] = []
	for villager_id: String in ["pak_ranu", "bu_sari", "nara", "pak_jati", "lio"]:
		_check(bool(room.call("interact_with_npc_for_testing", villager_id)), "warga harus dapat diajak bicara: " + villager_id)
		dialogue_messages.append(str(room.call("snapshot_for_testing").get("last_message", "")))
	_check(dialogue_messages.size() == 5, "setiap warga talkable harus menghasilkan dialog")
	var unique_dialogues: Dictionary = {}
	for dialogue: String in dialogue_messages:
		unique_dialogues[dialogue] = true
	_check(unique_dialogues.size() == 5, "dialog tiap warga harus berbeda")
	var talked_snapshot: Dictionary = room.call("snapshot_for_testing")
	_check((talked_snapshot.get("talked_to", []) as Array).size() == 5, "kelima warga harus tercatat sudah disapa")

	room.call("start_run")
	room.call("set_time_for_testing", 21.0)
	room.call("set_weather_for_testing", "wind")
	room.call("interact_with_npc_for_testing", "nara")
	_check(int(room.call("snapshot_for_testing").get("optional_task_step", 0)) == 1, "Nara harus menawarkan tugas opsional")
	room.call("interact_with_object_for_testing", "bunga_kecil")
	_check(int(room.call("snapshot_for_testing").get("optional_task_step", 0)) == 2, "bunga harus dapat dipetik untuk tugas opsional")
	room.call("interact_with_npc_for_testing", "lio")
	var optional_complete: Dictionary = room.call("snapshot_for_testing")
	_check(int(optional_complete.get("optional_task_step", 0)) == 3, "Lio harus menerima bunga dan menuntaskan tugas opsional")
	_check((optional_complete.get("inventory", []) as Array).is_empty(), "bunga harus keluar dari bawaan setelah diberikan")

	var dayparts := [
		{"name": "morning", "hour": 6.0},
		{"name": "day", "hour": 11.0},
		{"name": "evening", "hour": 16.0},
		{"name": "night", "hour": 20.0},
	]
	var weather_states := ["clear", "cloudy", "rain", "wind"]
	var optional_state_completions := 0
	for phase: Dictionary in dayparts:
		for weather: String in weather_states:
			room.call("start_run")
			room.call("set_time_for_testing", float(phase.hour))
			room.call("set_weather_for_testing", weather)
			var conditions: Dictionary = room.call("snapshot_for_testing")
			_check(str(conditions.get("daypart", "")) == str(phase.name), "core daypart tidak sesuai: %s/%s" % [str(phase.name), weather])
			_check(str(conditions.get("weather_state", "")) == weather, "core weather tidak sesuai: %s/%s" % [str(phase.name), weather])
			var previous_finish_count := finished_outcomes.size()
			_check(bool(room.call("interact_with_npc_for_testing", "pak_ranu")), "quest harus bisa dimulai pada %s/%s" % [str(phase.name), weather])
			var first_dialogue := str(room.call("snapshot_for_testing").get("last_message", ""))
			var neutral_greeting := "Halo, Mika."
			var weather_notes := {"clear": "Langit cerah.", "cloudy": "Langit agak mendung.", "rain": "Hujan turun pelan.", "wind": "Angin menyusuri jalan."}
			_check(first_dialogue.begins_with(neutral_greeting), "sapaan harus tetap netral pada %s/%s" % [str(phase.name), weather])
			_check(first_dialogue.contains(str(weather_notes.get(weather, ""))), "sapaan harus mengikuti cuaca: %s/%s" % [str(phase.name), weather])
			_check(int(room.call("snapshot_for_testing").get("main_task_step", 0)) == 1, "permintaan harus tercatat pada %s/%s" % [str(phase.name), weather])
			_check(bool(room.call("interact_with_object_for_testing", "keranjang_sayur")), "objek utama harus bisa diambil pada %s/%s" % [str(phase.name), weather])
			_check(int(room.call("snapshot_for_testing").get("main_task_step", 0)) == 2, "ambil harus maju ke langkah antar pada %s/%s" % [str(phase.name), weather])
			_check(bool(room.call("interact_with_npc_for_testing", "bu_sari")), "keranjang harus bisa diantar pada %s/%s" % [str(phase.name), weather])
			_check(int(room.call("snapshot_for_testing").get("main_task_step", 0)) == 3, "pengantaran harus tercatat pada %s/%s" % [str(phase.name), weather])
			_check(bool(room.call("interact_with_npc_for_testing", "pak_ranu")), "feedback sosial harus tersedia pada %s/%s" % [str(phase.name), weather])
			var completed: Dictionary = room.call("snapshot_for_testing")
			_check(bool(completed.get("peaceful_finish", false)) and bool(completed.get("free_exploration", false)), "finish harus damai dan membuka eksplorasi pada %s/%s" % [str(phase.name), weather])
			_check(finished_outcomes.size() == previous_finish_count + 1, "sinyal finish hanya sekali pada %s/%s" % [str(phase.name), weather])
			_check(str(completed.get("last_message", "")).contains("Terima kasih"), "feedback sosial harus muncul pada %s/%s" % [str(phase.name), weather])
			_check(bool(room.call("interact_with_npc_for_testing", "nara")), "quest opsional harus dapat dimulai pada %s/%s" % [str(phase.name), weather])
			_check(int(room.call("snapshot_for_testing").get("optional_task_step", 0)) == 1, "Nara harus menerima tugas opsional pada %s/%s" % [str(phase.name), weather])
			_check(bool(room.call("interact_with_object_for_testing", "bunga_kecil")), "bunga harus dapat dipetik pada %s/%s" % [str(phase.name), weather])
			_check(int(room.call("snapshot_for_testing").get("optional_task_step", 0)) == 2, "bunga harus masuk ke langkah quest pada %s/%s" % [str(phase.name), weather])
			_check(bool(room.call("interact_with_npc_for_testing", "lio")), "Lio harus dapat menerima bunga pada %s/%s" % [str(phase.name), weather])
			var optional_completed: Dictionary = room.call("snapshot_for_testing")
			_check(int(optional_completed.get("optional_task_step", 0)) == 3 and (optional_completed.get("inventory", []) as Array).is_empty(), "quest opsional harus selesai tanpa sisa item pada %s/%s" % [str(phase.name), weather])
			if int(optional_completed.get("optional_task_step", 0)) == 3 and (optional_completed.get("inventory", []) as Array).is_empty():
				optional_state_completions += 1
			room.call("interact_with_npc_for_testing", "pak_jati")
			_check(finished_outcomes.size() == previous_finish_count + 1, "eksplorasi bebas tidak boleh mengulang finish pada %s/%s" % [str(phase.name), weather])

	_check(finished_outcomes.size() == 16, "quest utama harus dapat dituntaskan pada semua 16 kombinasi state")
	_check(optional_state_completions == 16, "quest opsional harus dapat dituntaskan pada semua 16 kombinasi waktu/cuaca")

	# Navigate from the actual spawn using input actions and physics; do not call the teleporting test helpers here.
	room.call("start_run")
	_release_movement_input()
	var nav_player := room.get("player") as CharacterBody2D
	var nav_npcs: Dictionary = room.get("_npc_nodes")
	var nav_objects: Dictionary = room.get("_object_nodes")
	var nav_ranu := nav_npcs.get("pak_ranu") as Node2D
	var nav_sari := nav_npcs.get("bu_sari") as Node2D
	var nav_basket := nav_objects.get("keranjang_sayur") as Node2D
	var nav_start_position := nav_player.global_position if nav_player != null else Vector2.ZERO
	var nav_finish_count := finished_outcomes.size()
	_check(nav_player != null and nav_ranu != null and nav_sari != null and nav_basket != null, "target utama untuk uji navigasi harus tersedia")
	if nav_player != null and nav_ranu != null and nav_sari != null and nav_basket != null:
		_check(await _walk_player_into_range(room, nav_ranu), "input gerak harus membawa Mika dari spawn ke Pak Ranu")
		_check(nav_player.global_position.distance_to(nav_start_position) > 100.0, "uji navigasi harus benar-benar memindahkan player dari spawn")
		room.call("_update_interaction_prompt", true)
		_check(str(room.call("snapshot_for_testing").get("focused_target_id", "")) == "pak_ranu", "target interaksi real harus memilih Pak Ranu")
		_check(bool(room.call("interact_nearest")), "interaksi normal harus memulai quest dari target Pak Ranu")
		_check(int(room.call("snapshot_for_testing").get("main_task_step", 0)) == 1, "interaksi target real harus memulai quest utama")

		_check(await _walk_player_into_range(room, nav_basket), "input gerak harus membawa Mika ke keranjang sayur")
		room.call("_update_interaction_prompt", true)
		_check(str(room.call("snapshot_for_testing").get("focused_target_id", "")) == "keranjang_sayur", "target interaksi real harus memilih keranjang")
		_check(bool(room.call("interact_nearest")), "interaksi normal harus mengambil keranjang")
		_check(int(room.call("snapshot_for_testing").get("main_task_step", 0)) == 2, "target keranjang harus memajukan quest utama")

		_check(await _walk_player_into_range(room, nav_sari), "input gerak harus membawa Mika ke kedai Bu Sari")
		room.call("_update_interaction_prompt", true)
		_check(str(room.call("snapshot_for_testing").get("focused_target_id", "")) == "bu_sari", "target interaksi real harus memilih Bu Sari")
		_check(bool(room.call("interact_nearest")), "interaksi normal harus mengantar keranjang kepada Bu Sari")
		_check(int(room.call("snapshot_for_testing").get("main_task_step", 0)) == 3, "target Bu Sari harus memajukan quest utama")

		_check(await _walk_player_into_range(room, nav_ranu), "input gerak harus membawa Mika kembali ke Pak Ranu")
		room.call("_update_interaction_prompt", true)
		_check(str(room.call("snapshot_for_testing").get("focused_target_id", "")) == "pak_ranu", "target interaksi real harus memilih Pak Ranu saat kembali")
		_check(bool(room.call("interact_nearest")), "interaksi normal harus menuntaskan quest bersama Pak Ranu")
		var nav_completion: Dictionary = room.call("snapshot_for_testing")
		_check(bool(nav_completion.get("peaceful_finish", false)) and bool(nav_completion.get("free_exploration", false)), "quest harus selesai damai lewat navigasi/input tanpa teleport")
		_check(finished_outcomes.size() == nav_finish_count + 1, "navigasi end-to-end harus mengirim satu sinyal finish")
	_release_movement_input()

	room.call("shutdown_atmosphere_audio")
	room.queue_free()
	await get_tree().process_frame
	tuning.call("end_run")
	tuning.call("reset_defaults")


func _find_named_node(root: Node, wanted_name: String) -> Node:
	if root.name == wanted_name:
		return root
	for child: Node in root.get_children():
		var found := _find_named_node(child, wanted_name)
		if found != null:
			return found
	return null


func _finish() -> void:
	for failure: String in _failures:
		push_error("[lorong-sunyi-tests] " + failure)
	print("[lorong-sunyi-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
	get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _walk_player_into_range(room: Node, target: Node2D, radius: float = 24.0, max_physics_frames: int = 900) -> bool:
	var player := room.get("player") as CharacterBody2D
	if player == null or target == null:
		return false
	for _frame_index: int in max_physics_frames:
		var displacement := target.global_position - player.global_position
		if displacement.length() <= radius:
			_release_movement_input()
			return true
		_release_movement_input()
		if displacement.x < -1.0:
			Input.action_press("move_left")
		elif displacement.x > 1.0:
			Input.action_press("move_right")
		if displacement.y < -1.0:
			Input.action_press("move_up")
		elif displacement.y > 1.0:
			Input.action_press("move_down")
		await get_tree().physics_frame
	_release_movement_input()
	return player.global_position.distance_to(target.global_position) <= radius


func _release_movement_input() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
