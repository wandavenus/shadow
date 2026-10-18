extends Node2D
class_name LorongRoom

signal message_changed(text: String)
signal prompt_changed(text: String)
signal status_changed(state: Dictionary)
signal visual_tone_changed(tint_alpha: float, threat_visible: bool)
signal code_entry_requested
signal game_finished(outcome: String)

const ROOM_ART: Texture2D = preload("res://assets/environment/lorong-empty-room-1280x720.png")
const FURNITURE_ATLAS: Texture2D = preload("res://assets/props/catalog-furniture/Untitled 17.png")
const PRESENCE_ART: Texture2D = preload("res://assets/characters/empty-presence-512.png")
const PlayerComponent = preload("res://scripts/lorong/player.gd")
const PropComponent = preload("res://scripts/lorong/interactive_prop.gd")
const PropCatalog = preload("res://scripts/lorong/prop_catalog.gd")
const PLAYER_SPAWN := Vector2(520.0, 520.0)
const FEAR_TRIGGER := 3.0
const INTERACTION_DISTANCE := 98.0

var player: LorongPlayer
var _camera: Camera2D
var _actors: Node2D
var _presence: Node2D
var _presence_sprite: Sprite2D
var _background: Sprite2D
var _props: Dictionary = {}
var _specs: Dictionary = {}
var _clues: Dictionary = {}
var _inventory: Array[String] = []
var _successful_interactions: Dictionary = {}
var _focused_id := ""
var _last_prompt := ""
var _last_message := ""
var _fear := 0.0
var _lives := 3
var _key_found := false
var _cabinet_open := false
var _lamp_on := false
var _order_noted := false
var _threat_active := false
var _player_hidden := false
var _hide_timer := 0.0
var _invulnerability_timer := 0.0
var _completed := false
var _distorted := false
var _distortion_tween: Tween
var _elapsed := 0.0
var _last_tint_alpha := -1.0


func _ready() -> void:
	name = "RuangSunyi"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_world()


func start_run() -> void:
	if player == null:
		return
	if _distortion_tween != null and _distortion_tween.is_running():
		_distortion_tween.kill()
	_distortion_tween = null
	_fear = 0.0
	_lives = int(_active_tune("player.lives", 3.0))
	_key_found = false
	_cabinet_open = false
	_lamp_on = false
	_order_noted = false
	_threat_active = false
	_player_hidden = false
	_hide_timer = 0.0
	_invulnerability_timer = 0.0
	_completed = false
	_distorted = false
	_clues.clear()
	_inventory.clear()
	_successful_interactions.clear()
	_focused_id = ""
	_last_prompt = ""
	_last_message = "Mika tiba di kamar yang tidak ia kenali. Periksa benda-benda di sekitarmu."
	for spec: Dictionary in PropCatalog.all_props():
		var prop: LorongInteractiveProp = _props[str(spec.id)]
		prop.set_world_position(spec.position)
		prop.set_visual_state({})
		prop.set_focused(false)
	player.global_position = PLAYER_SPAWN
	player.set_hidden(false)
	player.set_move_speed(_active_tune("player.move.max_speed", 170.0))
	player.set_visual_scale(_active_tune("player.visual.scale", 1.0))
	player.set_reduced_motion(_active_tune_bool("ui.reduced_motion", false))
	_presence.position = Vector2(1160.0, 440.0)
	_presence.visible = false
	_update_tuning()
	message_changed.emit(_last_message)
	_emit_status()
	_update_nearest(true)


func _build_world() -> void:
	_background = Sprite2D.new()
	_background.name = "LatarKamar"
	_background.texture = ROOM_ART
	_background.centered = true
	_background.position = Vector2(640.0, 360.0)
	_background.scale = Vector2.ONE
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_background.z_index = -50
	add_child(_background)

	_actors = Node2D.new()
	_actors.name = "BendaDanTokoh"
	_actors.y_sort_enabled = true
	add_child(_actors)

	for spec: Dictionary in PropCatalog.all_props():
		var id := str(spec.id)
		_specs[id] = spec.duplicate(true)
		var prop: LorongInteractiveProp = PropComponent.new()
		prop.configure(spec, FURNITURE_ATLAS)
		_actors.add_child(prop)
		_props[id] = prop

	player = PlayerComponent.new()
	player.position = PLAYER_SPAWN
	_actors.add_child(player)

	_presence = Node2D.new()
	_presence.name = "Kehadiran"
	_presence.visible = false
	_presence_sprite = Sprite2D.new()
	_presence_sprite.name = "Siluet"
	_presence_sprite.texture = PRESENCE_ART
	_presence_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_presence_sprite.scale = Vector2.ONE * 0.39
	_presence_sprite.position.y = -float(PRESENCE_ART.get_height()) * 0.39 * 0.5
	_presence_sprite.modulate = Color(0.82, 0.72, 0.92, 0.92)
	_presence.add_child(_presence_sprite)
	_actors.add_child(_presence)

	_camera = Camera2D.new()
	_camera.name = "KameraOblique"
	_camera.position = Vector2(640.0, 360.0)
	add_child(_camera)
	_camera.make_current()


func _process(delta: float) -> void:
	_elapsed += delta
	if _invulnerability_timer > 0.0:
		_invulnerability_timer = maxf(0.0, _invulnerability_timer - delta)
	_update_nearest()
	_update_tuning()
	_update_threat(delta)
	_update_camera()


func _update_nearest(force_emit: bool = false) -> void:
	if player == null or _completed or _player_hidden:
		return
	var nearest_id := ""
	var nearest_distance := INTERACTION_DISTANCE
	for id: String in _props:
		var prop: LorongInteractiveProp = _props[id]
		var distance := player.global_position.distance_to(prop.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_id = id
	if nearest_id != _focused_id:
		if _props.has(_focused_id):
			(_props[_focused_id] as LorongInteractiveProp).set_focused(false)
		_focused_id = nearest_id
		if _props.has(_focused_id):
			(_props[_focused_id] as LorongInteractiveProp).set_focused(true)
		var prompt := ""
		if not _focused_id.is_empty():
			prompt = "E / PERIKSA  |  %s" % str(_specs[_focused_id].name)
		_last_prompt = prompt
		prompt_changed.emit(prompt)
	elif force_emit:
		_last_prompt = ""
		prompt_changed.emit(_last_prompt)


func interact_nearest() -> bool:
	if _focused_id.is_empty():
		_set_message("Tidak ada benda yang cukup dekat untuk diperiksa.")
		return false
	return interact_prop(_focused_id)


func interact_prop(prop_id: String) -> bool:
	if _completed or not _props.has(prop_id):
		return false
	var spec: Dictionary = _specs[prop_id]
	var response := _perform_interaction(prop_id, spec)
	if response.is_empty():
		return false
	_set_message(str(response.get("text", "Tidak terjadi apa-apa.")))
	var successful := bool(response.get("success", false))
	if successful and not _successful_interactions.has(prop_id):
		_successful_interactions[prop_id] = true
		_fear = clampf(_fear + float(spec.get("fear_on_first", 0.0)), 0.0, 5.0)
		_maybe_trigger_threat()
	_update_nearest(true)
	_emit_status()
	_update_tone()
	return true


func _perform_interaction(prop_id: String, spec: Dictionary) -> Dictionary:
	var first_text := str(spec.get("first_text", "Benda itu tetap diam."))
	var repeat_text := str(spec.get("repeat_text", "Tidak ada perubahan."))
	match str(spec.get("action", "examine")):
		"clue":
			var clue_key := str(spec.get("clue_key", prop_id))
			if not _clues.has(clue_key):
				_clues[clue_key] = str(spec.get("clue_value", "?"))
				return {"text": first_text, "success": true}
			return {"text": repeat_text, "success": false}
		"key":
			if not _key_found:
				_key_found = true
				_inventory.append("Kunci kecil")
				return {"text": first_text, "success": true}
			return {"text": repeat_text, "success": false}
		"closet":
			if not _key_found:
				return {"text": str(spec.get("failure_text", "Terkunci.")), "success": false}
			if not _cabinet_open:
				_cabinet_open = true
				_clues["lemari"] = "1"
				(_props["lemari"] as LorongInteractiveProp).set_visual_state({"open": true})
				return {"text": first_text, "success": true}
			if _threat_active and not _player_hidden:
				_player_hidden = true
				_hide_timer = 3.4
				player.set_hidden(true)
				return {"text": "Mika menyelinap ke lemari. Tahan napas sampai langkah itu menjauh.", "success": false}
			return {"text": repeat_text, "success": false}
		"order":
			if not _order_noted:
				_order_noted = true
				return {"text": first_text, "success": true}
			return {"text": repeat_text, "success": false}
		"lamp":
			_lamp_on = not _lamp_on
			(_props["lampu"] as LorongInteractiveProp).set_visual_state({"lamp_on": _lamp_on})
			if _lamp_on and not _clues.has("lampu"):
				_clues["lampu"] = str(spec.get("clue_value", "7"))
				return {"text": first_text, "success": true}
			if _lamp_on:
				return {"text": repeat_text, "success": false}
			return {"text": "Lampu padam. Angka 7 masih tersimpan dalam ingatanmu.", "success": false}
		"door":
			if _code_is_ready():
				code_entry_requested.emit()
				return {"text": "Panel angka terbuka. Masukkan tiga angka sesuai urutan catatan.", "success": true}
			return {"text": "Pintunya terkunci. Temukan tiga angka dan catatan urutannya terlebih dahulu.", "success": false}
		_:
			if not _successful_interactions.has(prop_id):
				return {"text": first_text, "success": true}
			return {"text": repeat_text, "success": false}


func submit_code(code: String) -> bool:
	if _completed:
		return false
	if not _code_is_ready():
		_set_message("Masih ada petunjuk atau urutan yang belum ditemukan.")
		return false
	if code.strip_edges() != "417":
		_fear = clampf(_fear + 0.35, 0.0, 5.0)
		_set_message("Kunci angka menolak kode itu. Dinding bergeser sedikit.")
		_maybe_trigger_threat()
		_emit_status()
		_update_tone()
		return false
	_completed = true
	(_props["pintu"] as LorongInteractiveProp).set_visual_state({"door_open": true})
	_set_message("Pintu terbuka. Lorong di baliknya akhirnya bergerak.")
	_emit_status()
	game_finished.emit("menang")
	return true


func _code_is_ready() -> bool:
	return _order_noted and _clues.has("bangku") and _clues.has("lemari") and _clues.has("lampu")


func _maybe_trigger_threat() -> void:
	if _fear < FEAR_TRIGGER or _threat_active or _completed:
		return
	_threat_active = true
	_presence.position = Vector2(1160.0, 420.0)
	_presence.visible = true
	_set_distortion(true)
	_set_message("Ada langkah di lorong. Sembunyilah di lemari yang sudah terbuka.")
	_emit_status()
	_update_tone()


func _update_threat(delta: float) -> void:
	if not _threat_active or _presence == null or _completed:
		return
	var speed_multiplier := _active_tune("enemies.move.speed_multiplier", 1.0)
	var aggression := _active_tune("enemies.ai.aggression", 1.0)
	var speed := 76.0 * speed_multiplier * (0.72 + aggression * 0.28)
	if _player_hidden:
		_hide_timer -= delta
		var closet: LorongInteractiveProp = _props["lemari"]
		_presence.position = _presence.position.move_toward(closet.position + Vector2(22.0, 0.0), speed * delta * 0.55)
		if _hide_timer <= 0.0:
			_player_hidden = false
			player.set_hidden(false)
			player.global_position = closet.global_position + Vector2(-58.0, 10.0)
			_threat_active = false
			_presence.visible = false
			_fear = minf(_fear, 1.7)
			_set_distortion(false)
			_set_message("Langkah itu menjauh. Mika keluar dari lemari dengan lutut gemetar.")
			_emit_status()
			_update_tone()
		return
	var direction := player.global_position - _presence.global_position
	if direction.length() > 0.1:
		_presence.global_position += direction.normalized() * speed * delta
	if direction.length() < 46.0 and _invulnerability_timer <= 0.0:
		_catch_player()


func _catch_player() -> void:
	_lives -= 1
	var store := get_node_or_null("/root/TuningStore")
	if store != null:
		store.call("apply_boundary", "NEXT_ACTION")
	_invulnerability_timer = _active_tune("gameplay.respawn.invulnerability", 1.2)
	_threat_active = false
	_presence.visible = false
	_player_hidden = false
	player.set_hidden(false)
	player.global_position = PLAYER_SPAWN
	_fear = minf(_fear, 1.6)
	_set_distortion(false)
	if _lives <= 0:
		_completed = true
		_set_message("Kehadiran itu menutup jalan pulang. Mika kehilangan ketenangannya.")
		_emit_status()
		game_finished.emit("kalah")
		return
	_set_message("Mika terkejut, tetapi masih sempat melepaskan diri. Sisa ketenangan: %d." % _lives)
	_emit_status()
	_update_tone()


func _set_distortion(active: bool) -> void:
	_distorted = active
	if _distortion_tween != null and _distortion_tween.is_running():
		_distortion_tween.kill()
	var offsets := {
		"lampu": Vector2(62.0, -26.0),
		"jam": Vector2(-42.0, 22.0),
		"potret": Vector2(76.0, 14.0)
	}
	var reduced := _active_tune_bool("ui.reduced_motion", false)
	if reduced:
		for id: String in offsets:
			var prop: LorongInteractiveProp = _props[id]
			var base_position: Vector2 = _specs[id].position
			prop.set_world_position(base_position + (offsets[id] if active else Vector2.ZERO))
		return
	_distortion_tween = create_tween().set_parallel(true)
	for id: String in offsets:
		var prop: LorongInteractiveProp = _props[id]
		var base_position: Vector2 = _specs[id].position
		var target: Vector2 = base_position + (offsets[id] if active else Vector2.ZERO)
		_distortion_tween.tween_property(prop, "position", target, 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _update_camera() -> void:
	if _camera == null:
		return
	var zoom_value := clampf(_active_tune("environment.camera.zoom", 1.0), 0.75, 1.3)
	_camera.zoom = Vector2.ONE * zoom_value
	var reduced := _active_tune_bool("ui.reduced_motion", false)
	if _threat_active and not reduced:
		var amplitude := minf(_fear, 4.0) * 1.2
		_camera.position = Vector2(640.0, 360.0) + Vector2(sin(_elapsed * 1.7), cos(_elapsed * 1.3)) * amplitude
	else:
		_camera.position = Vector2(640.0, 360.0)


func _update_tuning() -> void:
	if player == null:
		return
	player.set_move_speed(_active_tune("player.move.max_speed", 170.0))
	player.set_visual_scale(_active_tune("player.visual.scale", 1.0))
	player.set_reduced_motion(_active_tune_bool("ui.reduced_motion", false))
	if _presence_sprite != null:
		var threat_scale := _active_tune("enemies.visual.scale", 1.0)
		_presence_sprite.scale = Vector2.ONE * 0.39 * threat_scale
		_presence_sprite.position.y = -float(PRESENCE_ART.get_height()) * 0.39 * threat_scale * 0.5
	_update_tone()


func _update_tone() -> void:
	var enabled := _active_tune_bool("environment.filter.enabled", true)
	var intensity := clampf(_active_tune("environment.filter.intensity", 0.18), 0.0, 0.8)
	var alpha := intensity * clampf(_fear / FEAR_TRIGGER, 0.0, 1.0) if enabled else 0.0
	if not is_equal_approx(alpha, _last_tint_alpha):
		_last_tint_alpha = alpha
		visual_tone_changed.emit(alpha, _threat_active)


func _emit_status() -> void:
	status_changed.emit({
		"fear": _fear,
		"max_fear": 5.0,
		"clue_count": _clues.size(),
		"clues": _clues.duplicate(true),
		"order_noted": _order_noted,
		"inventory": _inventory.duplicate(),
		"lives": _lives,
		"threat_active": _threat_active,
		"hidden": _player_hidden,
		"successful_interactions": _successful_interactions.size()
	})


func _set_message(text: String) -> void:
	_last_message = text
	message_changed.emit(text)


func _active_tune(id: String, fallback: float) -> float:
	var store := get_node_or_null("/root/TuningStore")
	if store == null:
		return fallback
	return float(store.call("get_active_value", id, fallback))


func _active_tune_bool(id: String, fallback: bool) -> bool:
	var store := get_node_or_null("/root/TuningStore")
	if store == null:
		return fallback
	return bool(store.call("get_active_value", id, fallback))


func prop_ids_for_testing() -> Array[String]:
	return PropCatalog.prop_ids()


func snapshot_for_testing() -> Dictionary:
	return {
		"fear": _fear,
		"lives": _lives,
		"key_found": _key_found,
		"cabinet_open": _cabinet_open,
		"lamp_on": _lamp_on,
		"order_noted": _order_noted,
		"threat_active": _threat_active,
		"player_hidden": _player_hidden,
		"clues": _clues.duplicate(true),
		"inventory": _inventory.duplicate(),
		"completed": _completed,
		"last_message": _last_message
	}
