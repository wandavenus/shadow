extends Node

const EffectsType = preload("res://scripts/effects/effects_director.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var effects: Node = EffectsType.new()
	add_child(effects)
	await get_tree().process_frame
	effects.call("configure", Vector2(1280.0, 720.0))

	_check(effects.call("set_day_phase", "evening"), "evening phase is accepted")
	var state: Dictionary = effects.call("debug_snapshot")
	_check(state.get("day_phase") == "evening", "evening phase is reflected in debug state")
	_check(float(state.get("dusk_strength", 0.0)) > 0.0, "evening raises dusk grade")
	_check(bool(state.get("fireflies_active", false)), "fireflies can appear in calm evening")

	_check(effects.call("set_weather", "cloudy", 0.5), "cloudy weather is accepted")
	_check(not effects.call("set_weather", "fog", 0.5), "unknown weather is rejected")
	state = effects.call("debug_snapshot")
	_check(state.get("weather") == "cloudy", "invalid weather does not replace valid weather")
	_check(effects.call("set_weather", "rain", 0.7, 0.4), "rain state is accepted")
	state = effects.call("debug_snapshot")
	_check(bool(state.get("rain_active", false)), "rain enables its particle layer")
	_check(not bool(state.get("fireflies_active", true)), "rain suppresses fireflies")
	_check(state.get("weather_particles_kind") == "rain", "rain uses the rain particle system")
	_check(effects.call("set_weather", "wind", 0.8, -0.6), "wind state is accepted")
	state = effects.call("debug_snapshot")
	_check(bool(state.get("wind_particles_active", false)), "wind enables drifting leaf particles")
	_check(state.get("weather_particles_kind") == "wind", "wind replaces rain with leaf particles")

	_check(effects.call("add_window_glow", "shop", Vector2(380.0, 190.0), 1.0, 80.0), "window glow is added")
	_check(effects.call("add_window_glow", "shop", Vector2(400.0, 190.0), 0.8, 72.0), "window glow ID updates in place")
	state = effects.call("debug_snapshot")
	_check(int(state.get("window_glow_count", 0)) == 1, "updating a glow does not duplicate it")
	_check(effects.call("remove_window_glow", "shop"), "window glow is removed by ID")
	_check(not effects.call("remove_window_glow", "shop"), "removing an absent glow returns false")
	_check(effects.call("add_window_glow", "home", Vector2(620.0, 180.0)), "second window glow is added")
	effects.call("clear_window_glows")
	state = effects.call("debug_snapshot")
	_check(int(state.get("window_glow_count", -1)) == 0, "all window glows can be cleared")

	_check(effects.call("set_village_conditions", "evening", "clear", 0.0, 0.0), "shared day/weather state pair is accepted")
	state = effects.call("debug_snapshot")
	_check(state.get("day_phase") == "evening" and state.get("weather") == "clear", "shared state pair is applied")
	_check(state.get("weather_particles_kind") == "", "clear weather stops the old particle system")
	_check(not effects.call("set_village_conditions", "noon", "wind", 1.0, 0.5), "invalid shared state pair is rejected")
	state = effects.call("debug_snapshot")
	_check(state.get("day_phase") == "evening" and state.get("weather") == "clear", "invalid shared pair leaves both values unchanged")

	effects.call("set_reduced_motion", true)
	state = effects.call("debug_snapshot")
	_check(bool(state.get("reduced_motion", false)), "reduced motion is reflected in state")
	_check(not bool(state.get("wind_particles_active", true)), "reduced motion disables weather particles")
	effects.call("set_time_of_day", 13.0)
	state = effects.call("debug_snapshot")
	_check(state.get("day_phase") == "day", "the continuous clock maps to the shared day phase")

	if _failures.is_empty():
		print("[village-effects-test] PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		print("[village-effects-test] FAIL (%d/%d checks)" % [_failures.size(), _checks])
		get_tree().quit(1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
