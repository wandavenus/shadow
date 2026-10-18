extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "Lorong Sunyi", "identitas ekspor")
	for path: String in [
		"assets/environment/lorong-empty-room-1280x720.png",
		"assets/characters/empty-presence-512.png",
		"assets/characters/catalog-kenney/PNG/Round (outline)/rabbit.png",
		"assets/props/catalog-furniture/Untitled 17.png",
		"assets/share/lorong-title-1280x720.png",
		"assets/share/lorong-sunyi-og-1200x630.png",
		"assets/share/favicon.png",
		"localization/id-ID.json",
		"config/tuning.json",
	]:
		_check(ResourceLoader.exists("res://" + path), "resource pack: " + path)
	_check(not ResourceLoader.exists("res://test/test_suite.tscn"), "scene test dikecualikan dari release")
	_check(not ResourceLoader.exists("res://tools/verify_exported_pack.gd"), "alat verifikasi dikecualikan dari release")
	_check(not root.has_node("GlobalLeaderboard"), "tidak ada autoload leaderboard jaringan")
	var font := load("res://assets/template/fonts/ui_regular.tres") as Font
	_check(font != null, "resource font UI harus tersedia")
	var catalog_path := "res://localization/id-ID.json"
	_check(FileAccess.file_exists(catalog_path), "katalog id-ID harus diekspor")
	if FileAccess.file_exists(catalog_path):
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
		for value: String in catalog.values():
			for index: int in value.length():
				var codepoint := value.unicode_at(index)
				if codepoint >= 32:
					_check(font != null and font.has_char(codepoint), "glyph Indonesia harus tercakup: %d" % codepoint)
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "scene utama harus ada di pack")
	if packed != null:
		var main: Control = packed.instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		_check(main.get_node_or_null("TitleScreen") != null, "pack harus boot ke judul game")
		_check(not main.has_method("_open_tuning"), "panel developer tidak boleh muncul di release")
		main.call("_start_game")
		await process_frame
		_check(main.get_node_or_null("Room") != null, "pack harus memulai area permainan")
		_check(main.get_node_or_null("HUD/TouchControls/InteractButton") is Button, "kontrol sentuh harus dikemas")
		main.call("_return_to_title")
		await process_frame
		root.get_node("AudioDirector").call("release_streams")
		main.queue_free()
		await process_frame
	if _failures.is_empty():
		print("[lorong-sunyi-pack] PASS: identitas, sumber visual, locale, judul, kontrol sentuh, dan gameplay")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[lorong-sunyi-pack] " + failure)
		quit(1)


func _check(condition: bool, context: String) -> void:
	if not condition and context not in _failures:
		_failures.append(context)
