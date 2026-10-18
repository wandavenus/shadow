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
	get_tree().root.get_node("AudioDirector").call("release_streams")
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
	_check(settings.size() == 12, "seluruh 12 Tweak yang terdaftar harus dipakai game")
	var required_ids := [
		"ui.hud.opacity", "ui.reduced_motion", "gameplay.respawn.invulnerability",
		"player.move.max_speed", "player.lives", "player.visual.scale",
		"enemies.move.speed_multiplier", "enemies.ai.aggression", "enemies.visual.scale",
		"environment.filter.enabled", "environment.filter.intensity", "environment.camera.zoom"
	]
	for id: String in required_ids:
		var setting: Dictionary = tuning.call("get_setting", id)
		_check(not setting.is_empty(), "Tweak hilang: " + id)
		if setting.is_empty():
			continue
		var label := str(i18n.call("t", str(setting.label_key)))
		var description := str(i18n.call("t", str(setting.description_key)))
		_check(not label.begins_with("tuning."), "label Tweak belum diterjemahkan: " + id)
		_check(not description.begins_with("tuning."), "deskripsi Tweak belum diterjemahkan: " + id)
		var control: Dictionary = bridge.call("control_for", setting)
		_check(str(control.get("label", "")) == label, "adapter harus mempertahankan label Bahasa Indonesia: " + id)
		if str(control.get("applyMode", "LIVE")) != "LIVE":
			_check(not str(control.get("description", "")).contains("Next "), "suffix waktu Tweak tidak boleh berbahasa Inggris: " + id)
	tuning.call("end_run")
	tuning.call("reset_defaults")
	_check(not bool(tuning.call("set_value", "player.move.max_speed", 9999.0)), "nilai di luar batas Tweak harus ditolak")
	_check(is_equal_approx(float(tuning.call("get_active_value", "player.move.max_speed")), 170.0), "nilai yang ditolak tidak boleh mengubah kecepatan")
	_check(bool(tuning.call("set_value", "player.lives", 5.0)), "nilai kesempatan valid harus diterima")
	_check(is_equal_approx(float(tuning.call("get_active_value", "player.lives")), 3.0), "NEXT_RUN harus tetap tertunda sebelum permainan dimulai")
	tuning.call("begin_run", false)
	_check(is_equal_approx(float(tuning.call("get_active_value", "player.lives")), 5.0), "NEXT_RUN harus aktif saat permainan dimulai")
	_check(not bool(tuning.call("is_ranked_eligible")), "tuning gameplay non-default harus menandai run sebagai latihan")
	tuning.call("end_run")
	tuning.call("reset_defaults")


func _test_controller() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	_check(scene != null, "scene utama harus dapat dimuat")
	if scene == null:
		return
	var main: Control = scene.instantiate()
	main.name = "MainUnderTest"
	get_tree().root.add_child(main)
	await get_tree().process_frame
	_check(main.get_node_or_null("TitleScreen") != null, "layar judul harus muncul")
	main.call("_start_game")
	await get_tree().process_frame
	var touch_controls := main.get_node_or_null("HUD/TouchControls")
	_check(touch_controls != null, "kontrol sentuh harus aktif pada HUD")
	for button_name: String in ["MoveUp", "MoveDown", "MoveLeft", "MoveRight", "InteractButton"]:
		_check(touch_controls != null and touch_controls.get_node_or_null(button_name) is Button, "tombol sentuh hilang: " + button_name)
	_check(InputMap.has_action("move_left") and InputMap.has_action("move_down"), "aksi gerak keyboard harus tersedia")
	_check(int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)) == 0, "orientasi Android harus lanskap")
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
	var room: Node2D = room_script.new()
	room.name = "RoomUnderTest"
	get_tree().root.add_child(room)
	await get_tree().process_frame
	room.call("start_run")
	var prop_ids: Array = room.call("prop_ids_for_testing")
	_check(prop_ids.size() == 8, "ruang harus memuat delapan prop interaktif")
	for required: String in ["bangku", "lemari", "laci", "meja", "lampu", "jam", "potret", "pintu"]:
		_check(required in prop_ids, "prop wajib hilang: " + required)
	var code_requests := [0]
	room.code_entry_requested.connect(func() -> void: code_requests[0] += 1)
	_check(bool(room.call("interact_prop", "pintu")), "pintu terkunci tetap harus memberi respons")
	_check(code_requests[0] == 0, "keypad tidak boleh terbuka sebelum petunjuk ditemukan")
	for prop_id: String in ["jam", "potret", "bangku", "laci", "lemari", "meja", "lampu"]:
		_check(bool(room.call("interact_prop", prop_id)), "prop harus dapat berinteraksi: " + prop_id)
		var snapshot: Dictionary = room.call("snapshot_for_testing")
		_check(not str(snapshot.get("last_message", "")).is_empty(), "prop harus menghasilkan respons teks: " + prop_id)
	var gathered: Dictionary = room.call("snapshot_for_testing")
	_check(bool(gathered.get("key_found", false)), "laci harus memberikan kunci")
	_check(bool(gathered.get("cabinet_open", false)), "lemari harus dapat dibuka dengan kunci")
	_check(bool(gathered.get("lamp_on", false)), "lampu harus dapat dinyalakan")
	_check(bool(gathered.get("order_noted", false)), "meja harus mengungkap urutan kode")
	_check((gathered.get("clues", {}) as Dictionary).size() == 3, "tiga petunjuk angka harus terkumpul")
	_check(bool(gathered.get("threat_active", false)), "kegelisahan harus memunculkan Kehadiran")
	_check(bool(room.call("interact_prop", "pintu")), "pintu harus merespons setelah teka-teki siap")
	_check(code_requests[0] == 1, "pintu harus membuka keypad setelah tiga angka dan urutannya ditemukan")
	_check(bool(room.call("interact_prop", "lemari")), "lemari terbuka harus menerima aksi bersembunyi")
	var hidden: Dictionary = room.call("snapshot_for_testing")
	_check(bool(hidden.get("player_hidden", false)), "Mika harus dapat bersembunyi dari ancaman")

	room.call("start_run")
	for prop_id: String in ["bangku", "laci", "lemari", "meja", "lampu"]:
		room.call("interact_prop", prop_id)
	room.call("interact_prop", "pintu")
	_check(bool(room.call("submit_code", "417")), "kode 417 harus menyelesaikan teka-teki")
	var completed: Dictionary = room.call("snapshot_for_testing")
	_check(bool(completed.get("completed", false)), "kode benar harus mencapai kondisi menang")
	_check(is_equal_approx(float(tuning.call("get_active_value", "player.lives")), 3.0), "run test harus memulihkan default Tweak")
	room.queue_free()
	await get_tree().process_frame
	tuning.call("end_run")
	tuning.call("reset_defaults")


func _finish() -> void:
	for failure: String in _failures:
		push_error("[lorong-sunyi-tests] " + failure)
	print("[lorong-sunyi-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
	get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
