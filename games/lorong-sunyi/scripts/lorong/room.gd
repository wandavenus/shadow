extends Node2D
class_name LorongRoom

signal message_changed(text: String)
signal prompt_changed(text: String)
signal status_changed(state: Dictionary)
signal game_finished(outcome: String)

const PlayerScript = preload("res://scripts/lorong/player.gd")
const VillageCatalog = preload("res://scripts/lorong/prop_catalog.gd")
const VillageObjectScript = preload("res://scripts/lorong/interactive_prop.gd")
const CharacterVisualScript = preload("res://scripts/lorong/character_visual.gd")
const EffectsScript = preload("res://scripts/effects/effects_director.gd")
const AtmosphereAudioScript = preload("res://scripts/lorong/atmosphere_audio.gd")
const VILLAGE_BACKGROUND: Texture2D = preload("res://assets/environment/desa-kampung-runtime-1280x720.png")
const NPC_TEXTURES := {
	"pak_ranu": preload("res://assets/characters/desa-hewan/pak-ranu-goat-runtime-384x576.png"),
	"bu_sari": preload("res://assets/characters/desa-hewan/bu-sari-cat-runtime-384x576.png"),
	"nara": preload("res://assets/characters/desa-hewan/nara-rabbit-runtime-384x576.png"),
	"pak_jati": preload("res://assets/characters/desa-hewan/pak-jati-bear-runtime-384x576.png"),
	"lio": preload("res://assets/characters/desa-hewan/lio-dog-runtime-384x576.png"),
}

const WORLD_SIZE := Vector2(1280.0, 720.0)
const PLAYER_START := Vector2(650.0, 642.0)
const NPC_INTERACTION_RADIUS := 98.0
const OBJECT_INTERACTION_RADIUS := 82.0
const GAME_HOURS_PER_REAL_SECOND := 1.0 / 60.0
const WEATHER_CYCLE := [
	{"kind": "clear", "label": "CERAH", "intensity": 0.06, "wind": 0.04, "duration": 52.0},
	{"kind": "cloudy", "label": "MENDUNG", "intensity": 0.30, "wind": 0.16, "duration": 46.0},
	{"kind": "rain", "label": "HUJAN", "intensity": 0.66, "wind": 0.28, "duration": 42.0},
	{"kind": "wind", "label": "BERANGIN", "intensity": 0.48, "wind": 0.74, "duration": 42.0},
]

const MAIN_OBJECTIVE_BY_STEP := {
	0: "Bicara dengan Pak Ranu untuk memulai tugas.",
	1: "Ambil keranjang sayur di sisi kebun.",
	2: "Antarkan keranjang kepada Bu Sari di kedai.",
	3: "Kembali ke Pak Ranu dan ceritakan kabar dari kedai.",
	4: "Tugas selesai — jelajahi desa sepuasnya.",
}
const OPTIONAL_OBJECTIVE_BY_STEP := {
	0: "Opsional: temui Nara jika ingin membantu Lio.",
	1: "Petik satu bunga kecil di dekat jalan tengah.",
	2: "Berikan bunga itu kepada Lio.",
	3: "Tugas kecil selesai — Lio senang sekali.",
}

enum MainTaskStep { NOT_STARTED, ACCEPTED, BASKET_PICKED, DELIVERED, COMPLETE }
enum OptionalTaskStep { NOT_STARTED, ACCEPTED, FLOWER_PICKED, COMPLETE }

var player: CharacterBody2D

var _actors: Node2D
var _effects_director: Node2D
var _focus_ring: Line2D
var _atmosphere_audio: RefCounted
var _world_built := false
var _npc_nodes: Dictionary = {}
var _npc_visuals: Dictionary = {}
var _npc_name_labels: Dictionary = {}
var _npc_activity_labels: Dictionary = {}
var _npc_specs: Dictionary = {}
var _npc_routines: Dictionary = {}
var _npc_activities: Dictionary = {}
var _object_nodes: Dictionary = {}
var _object_specs: Dictionary = {}
var _object_available: Dictionary = {}
var _talked_to: Dictionary = {}
var _inventory: Array[String] = []
var _focused_target_id := ""
var _last_prompt := ""
var _last_message := ""
var _dialogue_count := 0
var _main_task_step := MainTaskStep.NOT_STARTED
var _optional_task_step := OptionalTaskStep.NOT_STARTED
var _peaceful_finish := false
var _finish_signal_sent := false

var _time_of_day := 6.0
var _daypart := "morning"
var _weather_state := "clear"
var _weather_index := 0
var _weather_elapsed := 0.0
var _weather_transition_count := 0
var _last_clock_minute := -1
var _reduced_motion := false
var _evening_cue_sent := false
var _window_glows_active := false
var _visual_hook_calls: Dictionary = {}
var _visual_state: Dictionary = {}


func _ready() -> void:
	name = "Village"
	_build_world()


func _exit_tree() -> void:
	shutdown_atmosphere_audio()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_update_tuning()
	_advance_clock(delta)
	_advance_weather(delta)
	_update_npc_routines(delta)
	_update_interaction_prompt()


func start_run(audio_opt_in: bool = false) -> void:
	if not _world_built:
		_build_world()
	_reset_run_state()
	_configure_visuals()
	_configure_audio(audio_opt_in)
	_update_tuning(true)
	_set_message("Desa menyambutmu dengan tenang. Sapa warga, bantu jika berkenan, dan nikmati waktu sesuai suasana.")
	_emit_status()
	_update_interaction_prompt(true)


func shutdown_atmosphere_audio() -> void:
	if _atmosphere_audio != null and is_instance_valid(_atmosphere_audio):
		_atmosphere_audio.call("shutdown")
	_atmosphere_audio = null


func set_atmosphere_audio_enabled(enabled: bool) -> bool:
	if _atmosphere_audio == null or not is_instance_valid(_atmosphere_audio):
		if not enabled:
			return true
		_configure_audio(false)
	if _atmosphere_audio == null or not is_instance_valid(_atmosphere_audio):
		return false
	var changed := bool(_atmosphere_audio.call("set_enabled", enabled))
	if changed and enabled:
		_sync_audio_conditions(true)
	return changed


func interact_nearest() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var target := _find_nearest_interaction()
	if target.is_empty():
		_set_message("Dekati warga atau objek kecil untuk berinteraksi.")
		return false
	if str(target.get("type", "")) == "npc":
		_talk_to_npc(str(target.get("id", "")))
	else:
		_interact_with_object(str(target.get("id", "")))
	_update_interaction_prompt(true)
	return true


func npc_ids_for_testing() -> Array[String]:
	return VillageCatalog.villager_ids()


func object_ids_for_testing() -> Array[String]:
	return VillageCatalog.world_object_ids()


func npc_position_for_testing(npc_id: String) -> Vector2:
	if not _npc_nodes.has(npc_id):
		return Vector2.ZERO
	return (_npc_nodes[npc_id] as Node2D).global_position


func npc_routine_target_for_testing(npc_id: String) -> Vector2:
	if not _npc_routines.has(npc_id):
		return npc_position_for_testing(npc_id)
	var routine: Dictionary = _npc_routines[npc_id]
	var points: Array = routine.get("points", [])
	if points.is_empty():
		return npc_position_for_testing(npc_id)
	var index := int(routine.get("index", 0)) % points.size()
	var target: Vector2 = points[index]
	return target


func object_position_for_testing(object_id: String) -> Vector2:
	if not _object_nodes.has(object_id):
		return Vector2.ZERO
	return (_object_nodes[object_id] as Node2D).global_position


func interact_with_npc_for_testing(npc_id: String) -> bool:
	if player == null or not _npc_nodes.has(npc_id):
		return false
	player.global_position = npc_position_for_testing(npc_id)
	return interact_nearest()


func interact_with_object_for_testing(object_id: String) -> bool:
	if player == null or not _object_nodes.has(object_id):
		return false
	player.global_position = object_position_for_testing(object_id)
	return interact_nearest()


func advance_simulation_for_testing(seconds: float) -> void:
	if get_tree().paused or seconds <= 0.0:
		return
	_update_tuning()
	_advance_clock(seconds)
	_advance_weather(seconds)
	_update_npc_routines(seconds)
	_update_interaction_prompt()


func advance_time_for_testing(seconds: float) -> void:
	if get_tree().paused or seconds <= 0.0:
		return
	_advance_clock(seconds)


func set_time_for_testing(hour24: float) -> void:
	if not is_finite(hour24):
		return
	_time_of_day = fposmod(hour24, 24.0)
	_last_clock_minute = -1
	_apply_time_visual(true)


func set_weather_for_testing(kind: String) -> bool:
	for index: int in WEATHER_CYCLE.size():
		if str(WEATHER_CYCLE[index].kind) == kind:
			_weather_index = index
			_weather_elapsed = 0.0
			_apply_weather_state(WEATHER_CYCLE[index], false)
			return true
	return false


func snapshot_for_testing() -> Dictionary:
	return {
		"npc_count": _npc_nodes.size(),
		"npc_ids": VillageCatalog.villager_ids(),
		"focused_target_id": _focused_target_id,
		"talked_to": _talked_to.keys(),
		"dialogue_count": _dialogue_count,
		"routine_count": _npc_routines.size(),
		"npc_activities": _npc_activities.duplicate(true),
		"main_task_step": _main_task_step,
		"optional_task_step": _optional_task_step,
		"main_objective": _main_objective_text(),
		"optional_objective": _optional_objective_text(),
		"inventory": _inventory.duplicate(),
		"peaceful_finish": _peaceful_finish,
		"free_exploration": _peaceful_finish,
		"time_of_day": _time_of_day,
		"time_label": _format_time(),
		"daypart": _daypart,
		"weather_state": _weather_state,
		"weather_label": _weather_label(),
		"weather_elapsed": _weather_elapsed,
		"weather_transition_count": _weather_transition_count,
		"reduced_motion": _reduced_motion,
		"visual_state": _visual_state.duplicate(true),
		"visual_hook_calls": _visual_hook_calls.duplicate(true),
		"visual_api": visual_api_for_testing(),
		"audio_configured": _atmosphere_audio != null and is_instance_valid(_atmosphere_audio),
		"audio_enabled": _atmosphere_audio != null and bool(_atmosphere_audio.call("is_enabled")),
		"last_message": _last_message,
	}


func visual_api_for_testing() -> Dictionary:
	if _effects_director == null or not is_instance_valid(_effects_director):
		return {}
	return {
		"time": _effects_director.has_method("set_time_of_day"),
		"weather": _effects_director.has_method("set_weather"),
		"conditions": _effects_director.has_method("set_village_conditions"),
		"dusk": _effects_director.has_method("set_dusk_strength"),
		"fireflies": _effects_director.has_method("set_fireflies_enabled"),
		"window_glow": _effects_director.has_method("add_window_glow") and _effects_director.has_method("clear_window_glows"),
		"reduced_motion": _effects_director.has_method("set_reduced_motion"),
	}


func _build_world() -> void:
	if _world_built:
		return
	var background := Sprite2D.new()
	background.name = "VillageBackground"
	background.texture = VILLAGE_BACKGROUND
	background.centered = true
	background.position = WORLD_SIZE * 0.5
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.z_index = -20
	add_child(background)

	_actors = Node2D.new()
	_actors.name = "Actors"
	_actors.y_sort_enabled = true
	add_child(_actors)

	player = PlayerScript.new() as CharacterBody2D
	player.name = "Mika"
	player.position = PLAYER_START
	_actors.add_child(player)

	for spec: Dictionary in VillageCatalog.all_villagers():
		_build_villager(spec)
	for spec: Dictionary in VillageCatalog.all_world_objects():
		_build_world_object(spec)

	_effects_director = EffectsScript.new() as Node2D
	_effects_director.name = "VillageEffects"
	_effects_director.z_index = 5
	add_child(_effects_director)

	_focus_ring = Line2D.new()
	_focus_ring.name = "InteractionFocus"
	_focus_ring.width = 2.0
	_focus_ring.default_color = Color(1.0, 0.84, 0.48, 0.82)
	_focus_ring.z_index = 12
	_focus_ring.visible = false
	var ring_points := PackedVector2Array()
	for index: int in 25:
		var angle := TAU * float(index) / 24.0
		ring_points.append(Vector2(cos(angle), sin(angle)) * 29.0)
	_focus_ring.points = ring_points
	_focus_ring.closed = true
	add_child(_focus_ring)
	_world_built = true


func _build_villager(spec: Dictionary) -> void:
	var villager_id := str(spec.get("id", ""))
	var actor := Node2D.new()
	actor.name = "Villager_%s" % villager_id
	actor.position = spec.get("position", Vector2.ZERO)
	actor.set_meta("villager_id", villager_id)

	var shadow := Polygon2D.new()
	shadow.name = "GroundShadow"
	shadow.color = Color(0.025, 0.035, 0.055, 0.36)
	shadow.polygon = PackedVector2Array([
		Vector2(-17.0, -4.0), Vector2(-11.0, -7.0), Vector2(0.0, -8.0), Vector2(11.0, -7.0),
		Vector2(17.0, -4.0), Vector2(11.0, -1.0), Vector2(0.0, 0.0), Vector2(-11.0, -1.0),
	])
	shadow.position = Vector2(0.0, 4.0)
	shadow.z_index = -2
	actor.add_child(shadow)

	var texture := NPC_TEXTURES.get(villager_id) as Texture2D
	var visual := CharacterVisualScript.new() as Node2D
	visual.name = "CharacterVisual"
	visual.call("configure", texture, str(spec.get("species", "")), Color.WHITE, 0.18, str(spec.get("name", "Warga")), str(spec.get("tagline", "")))
	actor.add_child(visual)

	_actors.add_child(actor)
	_npc_nodes[villager_id] = actor
	_npc_visuals[villager_id] = visual
	_npc_name_labels[villager_id] = visual.get_node("NameTag/TextStack/Name") as Label
	_npc_activity_labels[villager_id] = visual.get_node("NameTag/TextStack/Activity") as Label
	_npc_specs[villager_id] = spec


func _build_world_object(spec: Dictionary) -> void:
	var object_node := VillageObjectScript.new() as Node2D
	object_node.call("configure", spec)
	_actors.add_child(object_node)
	var object_id := str(spec.get("id", ""))
	_object_nodes[object_id] = object_node
	_object_specs[object_id] = spec
	_object_available[object_id] = true


func _reset_run_state() -> void:
	_main_task_step = MainTaskStep.NOT_STARTED
	_optional_task_step = OptionalTaskStep.NOT_STARTED
	_peaceful_finish = false
	_finish_signal_sent = false
	_talked_to.clear()
	_inventory.clear()
	_dialogue_count = 0
	_last_message = ""
	_last_prompt = ""
	_focused_target_id = ""
	_time_of_day = 6.0
	_daypart = ""
	_weather_state = ""
	_weather_index = 0
	_weather_elapsed = 0.0
	_weather_transition_count = 0
	_last_clock_minute = -1
	_evening_cue_sent = false
	_window_glows_active = false
	_visual_hook_calls.clear()
	_visual_state.clear()
	_reduced_motion = false
	player.global_position = PLAYER_START
	player.call("set_reduced_motion", false)

	for villager_id: String in _npc_nodes:
		var actor := _npc_nodes[villager_id] as Node2D
		var spec: Dictionary = _npc_specs[villager_id]
		actor.position = spec.get("position", Vector2.ZERO)
		_npc_activities[villager_id] = ""
		_npc_routines.erase(villager_id)
	for object_id: String in _object_nodes:
		_object_available[object_id] = true
		(_object_nodes[object_id] as Node2D).call("set_focused", false)
		(_object_nodes[object_id] as Node2D).call("set_available", true)


func _configure_visuals() -> void:
	_call_visual("configure", [WORLD_SIZE])
	_apply_time_visual(true)
	_apply_weather_state(WEATHER_CYCLE[0], true)
	_refresh_npc_activities()
	_sync_dusk_and_fireflies(true)
	_sync_window_glows(true)
	_apply_reduced_motion(_active_tune_bool("ui.reduced_motion", false), true)


func _configure_audio(audio_opt_in: bool = false) -> void:
	shutdown_atmosphere_audio()
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director == null:
		return
	var helper: RefCounted = AtmosphereAudioScript.new()
	if bool(helper.call("configure", audio_director, audio_opt_in)):
		_atmosphere_audio = helper
		_sync_audio_conditions(true)
	else:
		helper.call("shutdown")


func _sync_visual_conditions(force: bool = false) -> void:
	if _daypart.is_empty() or _weather_state.is_empty():
		return
	var last_daypart := str(_visual_state.get("visual_daypart", ""))
	var last_weather := str(_visual_state.get("visual_weather", ""))
	var last_intensity := float(_visual_state.get("visual_intensity", -1.0))
	var last_wind := float(_visual_state.get("visual_wind", -1.0))
	var intensity := float(_visual_state.get("weather_intensity", 0.0))
	var wind := float(_visual_state.get("wind", 0.0))
	if not force and last_daypart == _daypart and last_weather == _weather_state \
			and is_equal_approx(last_intensity, intensity) and is_equal_approx(last_wind, wind):
		return
	if _call_visual("set_village_conditions", [_daypart, _weather_state, intensity, wind]):
		# set_village_conditions applies a representative daypart; restore the exact core clock.
		_call_visual("set_time_of_day", [_time_of_day])
	else:
		_call_visual("set_day_phase", [_daypart])
		_call_visual("set_weather", [_weather_state, intensity, wind])
		_call_visual("set_time_of_day", [_time_of_day])
	_visual_state["visual_daypart"] = _daypart
	_visual_state["visual_weather"] = _weather_state
	_visual_state["visual_intensity"] = intensity
	_visual_state["visual_wind"] = wind


func _sync_audio_conditions(force: bool = false) -> void:
	if _atmosphere_audio == null or not is_instance_valid(_atmosphere_audio):
		return
	if _daypart.is_empty() or _weather_state.is_empty():
		return
	var last_daypart := str(_visual_state.get("audio_daypart", ""))
	var last_weather := str(_visual_state.get("audio_weather", ""))
	if not force and last_daypart == _daypart and last_weather == _weather_state:
		return
	_atmosphere_audio.call("set_village_conditions", _daypart, _weather_state)
	_visual_state["audio_daypart"] = _daypart
	_visual_state["audio_weather"] = _weather_state


func _update_tuning(force: bool = false) -> void:
	if player == null or not is_instance_valid(player):
		return
	player.call("set_move_speed", _active_tune("player.move.max_speed", 170.0))
	player.call("set_visual_scale", _active_tune("player.visual.scale", 1.0))
	var reduced := _active_tune_bool("ui.reduced_motion", false)
	if force or reduced != _reduced_motion:
		_apply_reduced_motion(reduced, force)


func _apply_reduced_motion(enabled: bool, force: bool = false) -> void:
	if not force and _reduced_motion == enabled:
		return
	_reduced_motion = enabled
	if player != null and is_instance_valid(player):
		player.call("set_reduced_motion", enabled)
	for visual_value: Variant in _npc_visuals.values():
		var visual := visual_value as Node
		if visual != null and is_instance_valid(visual):
			visual.call("set_reduced_motion", enabled)
			if enabled:
				visual.call("set_moving", false)
	_call_visual("set_reduced_motion", [enabled])
	_visual_state["reduced_motion"] = enabled


func _advance_clock(delta: float) -> void:
	if delta <= 0.0:
		return
	_time_of_day = fposmod(_time_of_day + delta * GAME_HOURS_PER_REAL_SECOND, 24.0)
	_apply_time_visual(false)


func _apply_time_visual(force: bool) -> void:
	var minute_of_day := int(floor(_time_of_day * 60.0))
	if not force and minute_of_day == _last_clock_minute:
		return
	_last_clock_minute = minute_of_day
	_call_visual("set_time_of_day", [_time_of_day])
	_visual_state["time_of_day"] = _time_of_day

	var next_daypart := _daypart_for_hour(_time_of_day)
	if next_daypart != _daypart:
		var previous_daypart := _daypart
		_daypart = next_daypart
		_refresh_npc_activities()
		_sync_visual_conditions()
		_sync_audio_conditions()
		if _daypart == "evening" and previous_daypart != "evening":
			_audio_event("entered_evening_village")
	_sync_dusk_and_fireflies(force)
	_sync_window_glows(false)
	if _time_of_day < 5.0:
		_evening_cue_sent = false
	if _daypart == "evening" and not _evening_cue_sent:
		_audio_event("entered_evening_village")
		_evening_cue_sent = true
	_emit_status()


func _advance_weather(delta: float) -> void:
	if delta <= 0.0:
		return
	_weather_elapsed += delta
	while _weather_elapsed >= float(WEATHER_CYCLE[_weather_index].duration):
		_weather_elapsed -= float(WEATHER_CYCLE[_weather_index].duration)
		_weather_index = (_weather_index + 1) % WEATHER_CYCLE.size()
		_apply_weather_state(WEATHER_CYCLE[_weather_index], false)


func _apply_weather_state(state: Dictionary, force: bool) -> void:
	var next_weather := str(state.get("kind", "clear"))
	var changed := next_weather != _weather_state
	if not changed and not force:
		return
	_weather_state = next_weather
	_visual_state["weather"] = _weather_state
	_visual_state["weather_intensity"] = float(state.get("intensity", 0.0))
	_visual_state["wind"] = float(state.get("wind", 0.0))
	if changed and not force:
		_weather_transition_count += 1
	_sync_visual_conditions(force)
	_sync_dusk_and_fireflies(force)
	_sync_window_glows(false)
	_refresh_npc_activities()
	_sync_audio_conditions(force)
	_emit_status()


func _daypart_for_hour(hour24: float) -> String:
	if hour24 < 6.0 or hour24 >= 20.0:
		return "night"
	if hour24 < 11.0:
		return "morning"
	if hour24 < 16.0:
		return "day"
	return "evening"


func _sync_dusk_and_fireflies(force: bool) -> void:
	var hour := _time_of_day
	var dusk := 0.0
	if hour < 7.0:
		dusk = 1.0 - smoothstep(4.0, 7.0, hour)
	elif hour >= 15.0 and hour < 19.0:
		dusk = smoothstep(15.0, 18.5, hour)
	elif hour >= 19.0:
		dusk = 1.0
	if _weather_state == "cloudy":
		dusk += 0.05
	elif _weather_state == "rain":
		dusk += 0.11
	elif _weather_state == "wind":
		dusk += 0.035
	dusk = clampf(dusk, 0.0, 0.88)
	var previous_dusk := float(_visual_state.get("dusk_strength", -1.0))
	if force or not is_equal_approx(previous_dusk, dusk):
		_call_visual("set_dusk_strength", [dusk])
		_visual_state["dusk_strength"] = dusk

	var fireflies := _daypart in ["evening", "night"]
	var previous_fireflies := bool(_visual_state.get("fireflies", not fireflies))
	if force or fireflies != previous_fireflies:
		_call_visual("set_fireflies_enabled", [fireflies])
		_visual_state["fireflies"] = fireflies


func _sync_window_glows(force: bool) -> void:
	var should_glow := _daypart in ["evening", "night"]
	if not force and should_glow == _window_glows_active:
		return
	_window_glows_active = should_glow
	_call_visual("clear_window_glows", [])
	if not should_glow:
		return
	_call_visual("add_window_glow", ["kedai_pagi", Vector2(286.0, 255.0), 0.58, 68.0])
	_call_visual("add_window_glow", ["rumah_tengah", Vector2(503.0, 167.0), 0.42, 56.0])
	_call_visual("add_window_glow", ["rumah_timur", Vector2(1143.0, 215.0), 0.42, 56.0])


func _refresh_npc_activities() -> void:
	if _npc_nodes.is_empty():
		return
	for villager_id: String in ["pak_ranu", "lio"]:
		if not _npc_nodes.has(villager_id):
			continue
		var profile := _activity_profile(villager_id)
		_npc_activities[villager_id] = str(profile.get("label", ""))
		var activity_label := _npc_activity_labels[villager_id] as Label
		activity_label.text = str(profile.get("label", ""))
		var visual := _npc_visuals[villager_id] as Node
		visual.call("set_activity_text", activity_label.text)
		var points: Array = profile.get("points", [])
		var actor := _npc_nodes[villager_id] as Node2D
		var closest_index := 0
		var closest_distance := INF
		for index: int in points.size():
			var distance := actor.position.distance_to(points[index])
			if distance < closest_distance:
				closest_distance = distance
				closest_index = index
		_npc_routines[villager_id] = {
			"points": points.duplicate(),
			"index": closest_index,
			"speed": float(_npc_specs[villager_id].get("routine_speed", 14.0)),
		}


func _activity_profile(villager_id: String) -> Dictionary:
	if villager_id == "pak_ranu":
		if _weather_state == "rain":
			return {"label": "berteduh dekat kedai", "points": [Vector2(408.0, 414.0), Vector2(438.0, 426.0)]}
		if _weather_state == "wind":
			return {"label": "mengikat tanaman", "points": [Vector2(912.0, 418.0), Vector2(946.0, 435.0)]}
		if _daypart == "day":
			return {"label": "menimbang hasil panen", "points": [Vector2(862.0, 442.0), Vector2(898.0, 458.0)]}
		if _daypart in ["evening", "night"]:
			return {"label": "merapikan keranjang", "points": [Vector2(421.0, 414.0), Vector2(449.0, 430.0)]}
		if _weather_state == "cloudy":
			return {"label": "menata keranjang", "points": [Vector2(880.0, 450.0), Vector2(910.0, 466.0)]}
		return {"label": "memeriksa kebun", "points": [Vector2(925.0, 420.0), Vector2(958.0, 438.0)]}

	if _weather_state == "rain":
		return {"label": "membaca di teras", "points": [Vector2(350.0, 448.0), Vector2(378.0, 458.0)]}
	if _weather_state == "wind":
		return {"label": "mengamati daun", "points": [Vector2(600.0, 530.0), Vector2(636.0, 545.0)]}
	if _daypart == "day":
		return {"label": "menyusuri jembatan", "points": [Vector2(618.0, 548.0), Vector2(654.0, 563.0)]}
	if _daypart in ["evening", "night"]:
		return {"label": "membantu di kedai", "points": [Vector2(360.0, 444.0), Vector2(390.0, 456.0)]}
	if _weather_state == "cloudy":
		return {"label": "menjelajah jalan tengah", "points": [Vector2(560.0, 520.0), Vector2(592.0, 535.0)]}
	return {"label": "mengamati bunga", "points": [Vector2(520.0, 555.0), Vector2(550.0, 542.0)]}


func _update_npc_routines(delta: float) -> void:
	if _reduced_motion or delta <= 0.0:
		return
	for villager_id: String in _npc_routines:
		var routine: Dictionary = _npc_routines[villager_id]
		var points: Array = routine.get("points", [])
		if points.size() < 2:
			continue
		var actor := _npc_nodes[villager_id] as Node2D
		var index := int(routine.get("index", 0)) % points.size()
		var target: Vector2 = points[index]
		if actor.position.distance_to(target) <= 3.0:
			index = (index + 1) % points.size()
			target = points[index]
		var previous_position := actor.position
		actor.position = actor.position.move_toward(target, float(routine.get("speed", 14.0)) * delta)
		var visual := _npc_visuals[villager_id] as Node
		var moved := actor.position.distance_to(previous_position) > 0.001
		visual.call("set_moving", moved)
		if absf(actor.position.x - previous_position.x) > 0.001:
			visual.call("set_facing_left", actor.position.x < previous_position.x)
		routine["index"] = index
		_npc_routines[villager_id] = routine


func _update_interaction_prompt(force: bool = false) -> void:
	var target := _find_nearest_interaction()
	var prompt := ""
	var target_id := ""
	if not target.is_empty():
		target_id = str(target.get("id", ""))
		if str(target.get("type", "")) == "npc":
			prompt = "E / SPASI · Bicara dengan %s" % str(target.get("name", "warga"))
		else:
			prompt = "E / SPASI · %s" % str(target.get("action", "Lihat"))
	if force or prompt != _last_prompt:
		_last_prompt = prompt
		prompt_changed.emit(prompt)
	if target_id != _focused_target_id:
		_set_target_focus(_focused_target_id, false)
		_focused_target_id = target_id
		_set_target_focus(_focused_target_id, true)
	if _focus_ring != null:
		_focus_ring.visible = not target.is_empty()
		if not target.is_empty():
			_focus_ring.position = target.get("position", Vector2.ZERO)
			_focus_ring.scale = Vector2.ONE * (1.0 if str(target.get("type", "")) == "npc" else 1.12)


func _set_target_focus(target_id: String, focused: bool) -> void:
	if target_id.is_empty():
		return
	if _object_nodes.has(target_id):
		(_object_nodes[target_id] as Node2D).call("set_focused", focused)
	elif _npc_nodes.has(target_id):
		var actor := _npc_nodes[target_id] as Node2D
		var visual := actor.get_node_or_null("CharacterVisual") as Node
		var body_sprite := actor.get_node_or_null("CharacterVisual/BodySprite") as Sprite2D
		if visual != null and body_sprite != null:
			visual.call("set_scale_factor", 1.15 if focused else 1.0)


func _find_nearest_interaction() -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {}
	var nearest: Dictionary = {}
	var nearest_distance := INF
	for villager_id: String in _npc_nodes:
		var actor := _npc_nodes[villager_id] as Node2D
		var distance := player.global_position.distance_to(actor.global_position)
		if distance <= NPC_INTERACTION_RADIUS and distance < nearest_distance:
			nearest_distance = distance
			var spec: Dictionary = _npc_specs[villager_id]
			nearest = {
				"type": "npc",
				"id": villager_id,
				"name": str(spec.get("name", "Warga")),
				"position": actor.position,
				"distance": distance,
			}
	for object_id: String in _object_nodes:
		if not bool(_object_available.get(object_id, false)):
			continue
		var node := _object_nodes[object_id] as Node2D
		var distance := player.global_position.distance_to(node.global_position)
		if distance <= OBJECT_INTERACTION_RADIUS and distance < nearest_distance:
			nearest_distance = distance
			var spec: Dictionary = _object_specs[object_id]
			var action := "Ambil %s" % str(spec.get("name", "objek"))
			nearest = {
				"type": "object",
				"id": object_id,
				"name": str(spec.get("name", "Objek")),
				"action": action,
				"position": node.position,
				"distance": distance,
			}
	return nearest


func _talk_to_npc(villager_id: String) -> void:
	if not _npc_nodes.has(villager_id):
		return
	var first_conversation := not bool(_talked_to.get(villager_id, false))
	_talked_to[villager_id] = true
	_dialogue_count += 1
	_audio_event("greeted_npc" if first_conversation else "finished_npc_chat")
	var dialogue := ""
	match villager_id:
		"pak_ranu":
			dialogue = _dialogue_pak_ranu()
		"bu_sari":
			dialogue = _dialogue_bu_sari()
		"nara":
			dialogue = _dialogue_nara()
		"pak_jati":
			dialogue = _dialogue_pak_jati()
		"lio":
			dialogue = _dialogue_lio()
	_set_message(dialogue)
	_emit_status()


func _contextual_greeting() -> String:
	var weather_note := "Langit cerah."
	match _weather_state:
		"cloudy":
			weather_note = "Langit agak mendung."
		"rain":
			weather_note = "Hujan turun pelan."
		"wind":
			weather_note = "Angin menyusuri jalan."
	return "Halo, Mika. %s" % weather_note


func _dialogue_pak_ranu() -> String:
	match _main_task_step:
		MainTaskStep.NOT_STARTED:
			_main_task_step = MainTaskStep.ACCEPTED
			return "%s Sayur kebunku siap dibawa ke kedai Bu Sari. Kalau berkenan, ambil keranjang di sisi kebun lalu antarkan padanya. Tidak perlu buru-buru." % _contextual_greeting()
		MainTaskStep.ACCEPTED:
			return "Keranjang sayur ada di tepi kebun. Bu Sari senang kalau ada yang mampir, apa pun cuacanya."
		MainTaskStep.BASKET_PICKED:
			return "Terima kasih sudah membawa keranjang. Kedai Bu Sari ada di sisi barat lapangan; jalan tengah selalu terbuka."
		MainTaskStep.DELIVERED:
			_main_task_step = MainTaskStep.COMPLETE
			_peaceful_finish = true
			_audio_event("helped_neighbor")
			_set_message("Pak Ranu tersenyum lebar. “Terima kasih, Mika. Hari ini terasa lebih ringan karena kita saling membantu.”")
			_emit_status()
			if not _finish_signal_sent:
				_finish_signal_sent = true
				game_finished.emit("selesai_damai")
			return _last_message
		_:
			return "Pak Ranu mengangguk hangat. “Nikmati saja waktumu di desa, Mika. Pekerjaan kecil pun terasa berarti kalau dikerjakan bersama.”"


func _dialogue_bu_sari() -> String:
	match _main_task_step:
		MainTaskStep.NOT_STARTED:
			return "%s Aku sedang menyiapkan kedai. Pak Ranu biasanya membawa sayur segar dari kebun." % _contextual_greeting()
		MainTaskStep.ACCEPTED:
			return "Pak Ranu bilang akan mengantar sayur. Kedai ini tetap buka saat langit berubah; santai saja."
		MainTaskStep.BASKET_PICKED:
			if not _inventory.has("keranjang_sayur"):
				return "Aku belum melihat keranjang sayur. Mungkin masih tertinggal di dekat kebun Pak Ranu."
			_inventory.erase("keranjang_sayur")
			_set_object_available("keranjang_sayur", false)
			_main_task_step = MainTaskStep.DELIVERED
			return "Sayurnya segar sekali! Terima kasih, Mika. Sampaikan salamku kepada Pak Ranu—kedai kecil ini terasa hidup lagi."
		_:
			return "Terima kasih sudah membantu. Sayur segar ini cukup untuk menyiapkan hidangan bagi tetangga yang mampir."


func _dialogue_nara() -> String:
	match _optional_task_step:
		OptionalTaskStep.NOT_STARTED:
			_optional_task_step = OptionalTaskStep.ACCEPTED
			return "Hai, Mika. Lio ingin menghias meja kecil di dekat jembatan. Kalau mau, petik satu bunga di jalan tengah lalu berikan padanya. Tidak ada yang dikejar."
		OptionalTaskStep.ACCEPTED:
			return "Bunga kecil tumbuh di dekat jalan tengah. Lio biasanya berada tak jauh dari jembatan."
		OptionalTaskStep.FLOWER_PICKED:
			return "Bunganya cantik, Mika. Lio pasti senang menerimanya."
		_:
			if _main_task_step == MainTaskStep.COMPLETE:
				return "Aku dengar kedai Bu Sari sudah mendapat sayur. Desa terasa lebih ramai kalau kita saling bantu."
			return "Terima kasih sudah menemani Lio. Hal kecil seperti itu membuat suasana lebih cerah."


func _dialogue_pak_jati() -> String:
	if _main_task_step >= MainTaskStep.DELIVERED:
		return "Anyaman keranjang perlu waktu, tapi hasilnya kuat. Tadi aku melihat sayur Pak Ranu sudah sampai ke kedai—kerja sama yang bagus."
	if _weather_state == "rain":
		return "Hujan membuat jalan berkilau. Jalur batu di tengah desa tetap nyaman dilalui, dan semua warga masih mudah ditemui."
	if _weather_state == "wind":
		return "Angin membawa bau daun dari kebun. Aku sedang memperkuat pegangan keranjang supaya panen berikutnya aman."
	return "Aku sedang merapikan anyaman. Dari sini terlihat kedai di barat, kebun di timur, dan jembatan kecil di selatan."


func _dialogue_lio() -> String:
	if _optional_task_step == OptionalTaskStep.FLOWER_PICKED and _inventory.has("bunga_kecil"):
		_inventory.erase("bunga_kecil")
		_set_object_available("bunga_kecil", false)
		_optional_task_step = OptionalTaskStep.COMPLETE
		_audio_event("helped_neighbor")
		return "Wah, bunga ini cantik sekali! Terima kasih, Mika. Akan kutaruh di meja Nara."
	if _optional_task_step == OptionalTaskStep.COMPLETE:
		return "Bunganya masih menghiasi meja. Aku senang sekali, Mika!"
	if _optional_task_step == OptionalTaskStep.ACCEPTED:
		return "Nara bilang ada bunga kecil dekat jalan tengah. Aku membayangkan meja kami jadi lebih ceria."
	if _daypart in ["evening", "night"]:
		return "Aku suka duduk di teras saat langit berubah warna. Suara hujan atau angin juga enak didengar dari sini."
	return "Aku sedang mengamati daun dan bunga. Setiap cuaca membuat desa terlihat sedikit berbeda."


func _interact_with_object(object_id: String) -> void:
	if not _object_nodes.has(object_id):
		return
	if object_id == "keranjang_sayur":
		if _main_task_step == MainTaskStep.NOT_STARTED:
			_set_message("Keranjang sayur ini milik Pak Ranu. Temui dia dulu agar tahu ke mana harus mengantarkannya.")
		elif _main_task_step == MainTaskStep.ACCEPTED:
			_inventory.append("keranjang_sayur")
			_main_task_step = MainTaskStep.BASKET_PICKED
			_set_object_available("keranjang_sayur", false)
			_audio_event("found_something")
			_set_message("Kamu mengangkat keranjang sayur. Tujuan berikutnya: kedai Bu Sari di sisi barat desa.")
		else:
			_set_message("Keranjang sayur sudah sampai di kedai. Kamu bisa melanjutkan jalan santai.")
	elif object_id == "bunga_kecil":
		if _optional_task_step == OptionalTaskStep.NOT_STARTED:
			_set_message("Bunga kecil tumbuh di pinggir jalan. Nara mungkin tahu siapa yang ingin menerimanya.")
		elif _optional_task_step == OptionalTaskStep.ACCEPTED:
			_inventory.append("bunga_kecil")
			_optional_task_step = OptionalTaskStep.FLOWER_PICKED
			_set_object_available("bunga_kecil", false)
			_audio_event("found_something")
			_set_message("Kamu memetik satu bunga tanpa merusak rumpunnya. Lio ada di sekitar jembatan atau kedai.")
		else:
			_set_message("Bunga itu sudah kamu petik. Kamu dapat mengantarkannya kepada Lio kapan saja.")
	_emit_status()


func _set_object_available(object_id: String, available: bool) -> void:
	_object_available[object_id] = available
	if _object_nodes.has(object_id):
		(_object_nodes[object_id] as Node2D).call("set_available", available)


func _main_objective_text() -> String:
	return str(MAIN_OBJECTIVE_BY_STEP.get(_main_task_step, MAIN_OBJECTIVE_BY_STEP[0]))


func _optional_objective_text() -> String:
	return str(OPTIONAL_OBJECTIVE_BY_STEP.get(_optional_task_step, OPTIONAL_OBJECTIVE_BY_STEP[0]))


func _inventory_text() -> String:
	if _inventory.is_empty():
		return "Bawaan: kosong"
	var labels: Array[String] = []
	for item_id: String in _inventory:
		match item_id:
			"keranjang_sayur": labels.append("keranjang sayur")
			"bunga_kecil": labels.append("bunga kecil")
			_: labels.append(item_id)
	return "Bawaan: %s" % ", ".join(labels)


func _emit_status() -> void:
	status_changed.emit({
		"main_task_step": _main_task_step,
		"main_objective": _main_objective_text(),
		"main_complete": _main_task_step == MainTaskStep.COMPLETE,
		"optional_task_step": _optional_task_step,
		"optional_objective": _optional_objective_text(),
		"optional_complete": _optional_task_step == OptionalTaskStep.COMPLETE,
		"inventory_text": _inventory_text(),
		"npc_count": _npc_nodes.size(),
		"routine_count": _npc_routines.size(),
		"time_of_day": _time_of_day,
		"time_label": _format_time(),
		"daypart": _daypart,
		"weather_state": _weather_state,
		"weather_label": _weather_label(),
		"peaceful_finish": _peaceful_finish,
	})


func _format_time() -> String:
	var total_minutes := int(floor(_time_of_day * 60.0)) % (24 * 60)
	var hour := int(floor(float(total_minutes) / 60.0))
	var minute := total_minutes % 60
	return "%02d:%02d" % [hour, minute]


func _weather_label() -> String:
	for state: Dictionary in WEATHER_CYCLE:
		if str(state.kind) == _weather_state:
			return str(state.label)
	return "CERAH"


func _set_message(text: String) -> void:
	_last_message = text
	message_changed.emit(text)


func _audio_event(method_name: String) -> void:
	if _atmosphere_audio != null and is_instance_valid(_atmosphere_audio) and _atmosphere_audio.has_method(method_name):
		_atmosphere_audio.call(method_name)


func _call_visual(method_name: String, arguments: Array) -> bool:
	if _effects_director == null or not is_instance_valid(_effects_director) or not _effects_director.has_method(method_name):
		return false
	_effects_director.callv(method_name, arguments)
	_visual_hook_calls[method_name] = int(_visual_hook_calls.get(method_name, 0)) + 1
	return true


func _label_settings(font_size: int, font_color: Color) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = font_color
	settings.outline_size = 3
	settings.outline_color = Color(0.08, 0.11, 0.08, 0.94)
	return settings


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
