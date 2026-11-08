extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "Lorong Sunyi", "identitas ekspor")
	for path: String in [
		"assets/environment/desa-kampung-runtime-1280x720.png",
		"assets/characters/desa-hewan/mika-fox-runtime-384x576.png",
		"assets/characters/desa-hewan/pak-ranu-goat-runtime-384x576.png",
		"assets/characters/desa-hewan/bu-sari-cat-runtime-384x576.png",
		"assets/characters/desa-hewan/nara-rabbit-runtime-384x576.png",
		"assets/characters/desa-hewan/pak-jati-bear-runtime-384x576.png",
		"assets/characters/desa-hewan/lio-dog-runtime-384x576.png",
		"assets/share/favicon-fox-runtime-256.png",
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
		var room := main.get("_room") as Node2D
		_check(room != null and room.name == "Village" and main.get_node_or_null("Village") == room, "pack harus memulai scene desa aktif")
		_check(main.get_node_or_null("HUD/TouchControls/InteractButton") is Button, "kontrol sentuh harus dikemas")
		if room != null:
			var player := room.get("player") as CharacterBody2D
			_check(player != null and player.get_node_or_null("CharacterVisual/BodySprite") is Sprite2D, "pack harus memuat Mika full-body")
			var npc_nodes: Dictionary = room.get("_npc_nodes")
			var pak_ranu := npc_nodes.get("pak_ranu") as Node2D
			var body_sprite := pak_ranu.get_node_or_null("CharacterVisual/BodySprite") as Sprite2D if pak_ranu != null else null
			_check(body_sprite != null, "pack harus memuat rig BodySprite warga")
			if player != null and pak_ranu != null and body_sprite != null:
				player.global_position = pak_ranu.global_position + Vector2(4000.0, 4000.0)
				room.call("_update_interaction_prompt", true)
				var base_scale := body_sprite.scale.x
				player.global_position = pak_ranu.global_position
				room.call("_update_interaction_prompt", true)
				_check(str(room.call("snapshot_for_testing").get("focused_target_id", "")) == "pak_ranu", "pack harus memilih fokus NPC terdekat")
				_check(body_sprite.scale.x > base_scale, "pack harus meng-zoom BodySprite saat NPC difokuskan")
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
