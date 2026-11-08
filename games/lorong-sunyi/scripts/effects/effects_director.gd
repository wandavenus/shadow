class_name EffectsDirector
extends Node2D

const MAX_BURST_EMITTERS := 12
const BASE_BURST_AMOUNT := 18
const ATMOSPHERE_SHADER: Shader = preload("res://shaders/lorong_atmosphere.gdshader")
const VILLAGE_LOWFI_SHADER: Shader = preload("res://shaders/village_lowfi.gdshader")
const DEFAULT_WORLD_SIZE := Vector2(1280.0, 720.0)
const OVERLAY_OVERSCAN := 1.6
const VALID_DAY_PHASES := ["morning", "day", "evening", "night"]
const VALID_WEATHER := ["clear", "cloudy", "rain", "wind"]
const PHASE_HOURS := {"morning": 8.0, "day": 13.0, "evening": 18.0, "night": 22.0}

var _burst_pool: Array[CPUParticles2D] = []
var _pool_cursor := 0
var _fireflies: CPUParticles2D
var _weather_particles: CPUParticles2D
var _overlay: ColorRect
var _overlay_material: ShaderMaterial
var _world_size := DEFAULT_WORLD_SIZE
var _atmosphere_enabled := false
var _time_of_day := 13.0
var _day_phase := "day"
var _dusk_strength := 0.0
var _night_strength := 0.0
var _weather := "clear"
var _weather_intensity := 0.0
var _wind_strength := 0.0
var _active_weather_particles_kind := ""
var _cloudiness := 0.0
var _fireflies_allowed := true
var _reduced_motion := false
var _window_glow_texture: ImageTexture
var _firefly_texture: ImageTexture
var _rain_texture: ImageTexture
var _leaf_texture: ImageTexture
var _additive_material: CanvasItemMaterial
var _window_glows: Dictionary = {}


func _ready() -> void:
	for index: int in MAX_BURST_EMITTERS:
		var emitter := CPUParticles2D.new()
		emitter.name = "Burst%d" % index
		emitter.one_shot = true
		emitter.emitting = false
		emitter.z_index = 10
		add_child(emitter)
		_burst_pool.append(emitter)

	_firefly_texture = _make_radial_texture(12)
	_window_glow_texture = _make_radial_texture(96)
	_rain_texture = _make_rain_texture()
	_leaf_texture = _make_leaf_texture()
	_additive_material = CanvasItemMaterial.new()
	_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_additive_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	_fireflies = CPUParticles2D.new()
	_fireflies.name = "Fireflies"
	_fireflies.amount = 30
	_fireflies.lifetime = 5.5
	_fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_fireflies.direction = Vector2.UP
	_fireflies.spread = 180.0
	_fireflies.gravity = Vector2(0.0, -0.4)
	_fireflies.initial_velocity_min = 1.0
	_fireflies.initial_velocity_max = 5.0
	_fireflies.scale_amount_min = 0.55
	_fireflies.scale_amount_max = 1.25
	_fireflies.texture = _firefly_texture
	_fireflies.color = Color(1.0, 0.78, 0.38, 0.72)
	_fireflies.material = _additive_material
	_fireflies.z_index = 2
	_fireflies.emitting = false
	add_child(_fireflies)

	_weather_particles = CPUParticles2D.new()
	_weather_particles.name = "VillageWeather"
	_weather_particles.one_shot = false
	_weather_particles.emitting = false
	_weather_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_weather_particles.z_index = 3
	add_child(_weather_particles)

	_overlay = ColorRect.new()
	_overlay.name = "VillageDuskGrade"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color.WHITE
	_overlay.visible = false
	_overlay.z_index = 0
	_overlay_material = ShaderMaterial.new()
	_overlay_material.shader = ATMOSPHERE_SHADER
	_overlay.material = _overlay_material
	add_child(_overlay)
	_sync_world_bounds()

	TuningStore.value_changed.connect(_on_tuning_changed)
	_apply_village_lowfi_style()
	_refresh_particles()
	_refresh_shader_parameters()


func configure(world_size: Vector2) -> void:
	_world_size = Vector2(maxf(1.0, world_size.x), maxf(1.0, world_size.y))
	_sync_world_bounds()
	_refresh_particles()


## Sets the visual day cycle from the gameplay-owned 24-hour clock.
## The core remains responsible for advancing or pausing the clock.
func set_time_of_day(hour24: float) -> void:
	if not is_finite(hour24):
		return
	_time_of_day = fposmod(hour24, 24.0)
	_day_phase = _phase_for_hour(_time_of_day)
	_apply_day_phase()


## Accepts the shared core state: morning, day, evening, or night.
func set_day_phase(phase: String) -> bool:
	var normalized := phase.strip_edges().to_lower()
	if not VALID_DAY_PHASES.has(normalized):
		return false
	_day_phase = normalized
	_time_of_day = float(PHASE_HOURS[normalized])
	_apply_day_phase()
	return true


## Allows scripted sunset or story lighting to override the computed dusk grade.
func set_dusk_strength(value: float) -> void:
	if not is_finite(value):
		return
	_dusk_strength = clampf(value, 0.0, 1.0)
	_enable_atmosphere()
	_refresh_shader_parameters()
	_refresh_window_glows()


## Accepts the shared core weather state: clear, cloudy, rain, or wind.
## Intensity and wind are clamped; unknown kinds leave the active weather unchanged.
func set_weather(kind: String, intensity: float = 1.0, wind_strength: float = 0.0) -> bool:
	var normalized := kind.strip_edges().to_lower()
	if not VALID_WEATHER.has(normalized) or not is_finite(intensity) or not is_finite(wind_strength):
		return false
	_weather = normalized
	_weather_intensity = clampf(intensity, 0.0, 1.0)
	_wind_strength = clampf(wind_strength, -1.0, 1.0)
	if _weather == "wind" and is_zero_approx(_wind_strength):
		_wind_strength = _weather_intensity
	_cloudiness = _cloudiness_for_weather(_weather, _weather_intensity)
	_enable_atmosphere()
	_refresh_particles()
	_refresh_shader_parameters()
	return true


## Applies one valid pair of shared core enums atomically.
func set_village_conditions(day_phase: String, weather: String, intensity: float = 1.0, wind_strength: float = 0.0) -> bool:
	var normalized_phase := day_phase.strip_edges().to_lower()
	var normalized_weather := weather.strip_edges().to_lower()
	if (
		not VALID_DAY_PHASES.has(normalized_phase)
		or not VALID_WEATHER.has(normalized_weather)
		or not is_finite(intensity)
		or not is_finite(wind_strength)
	):
		return false
	set_day_phase(normalized_phase)
	return set_weather(normalized_weather, intensity, wind_strength)


## Enables fireflies during dusk and nighttime; heavy rain suppresses them.
func set_fireflies_enabled(enabled: bool) -> void:
	_fireflies_allowed = enabled
	_refresh_particles()


func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	_refresh_particles()


## Adds or updates a soft amber glow at a window position in parent-world coordinates.
func add_window_glow(id: String, world_position: Vector2, intensity: float = 1.0, radius: float = 72.0) -> bool:
	var key := id.strip_edges()
	if key.is_empty() or not world_position.is_finite() or not is_finite(intensity) or not is_finite(radius):
		return false
	var clamped_intensity := clampf(intensity, 0.0, 2.0)
	var clamped_radius := clampf(radius, 4.0, 320.0)
	var glow: Sprite2D
	if _window_glows.has(key):
		glow = _window_glows[key]["node"] as Sprite2D
	else:
		glow = Sprite2D.new()
		glow.name = "WindowGlow_%s" % key.validate_node_name()
		glow.centered = true
		glow.texture = _window_glow_texture
		glow.material = _additive_material
		glow.z_index = 1
		add_child(glow)
		_window_glows[key] = {"node": glow, "intensity": clamped_intensity, "radius": clamped_radius}
	glow.position = world_position
	glow.scale = Vector2.ONE * clamped_radius / 48.0
	var entry: Dictionary = _window_glows[key]
	entry["intensity"] = clamped_intensity
	entry["radius"] = clamped_radius
	_window_glows[key] = entry
	_enable_atmosphere()
	_refresh_window_glows()
	return true


func remove_window_glow(id: String) -> bool:
	var key := id.strip_edges()
	if not _window_glows.has(key):
		return false
	var entry: Dictionary = _window_glows[key]
	var glow := entry.get("node") as Node2D
	if is_instance_valid(glow):
		glow.queue_free()
	_window_glows.erase(key)
	return true


func clear_window_glows() -> void:
	for key: Variant in _window_glows.keys():
		var entry: Dictionary = _window_glows[key]
		var glow := entry.get("node") as Node2D
		if is_instance_valid(glow):
			glow.queue_free()
	_window_glows.clear()


func burst(world_position: Vector2, color: Color, scale_multiplier: float = 1.0) -> void:
	var density := float(TuningStore.get_value("environment.particles.density", 1.0))
	if density <= 0.0:
		return
	var reduced_motion := _motion_is_reduced()
	var particles: CPUParticles2D = _burst_pool[_pool_cursor]
	_pool_cursor = (_pool_cursor + 1) % _burst_pool.size()
	particles.position = world_position
	particles.amount = 4 if reduced_motion else clampi(roundi(BASE_BURST_AMOUNT * density), 4, 48)
	particles.lifetime = 0.22 if reduced_motion else 0.52 * scale_multiplier
	particles.explosiveness = 1.0 if reduced_motion else 0.92
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO if reduced_motion else Vector2(0.0, 42.0)
	particles.initial_velocity_min = 0.0 if reduced_motion else 45.0 * scale_multiplier
	particles.initial_velocity_max = 8.0 if reduced_motion else 115.0 * scale_multiplier
	particles.scale_amount_min = 1.6
	particles.scale_amount_max = 2.4 if reduced_motion else 3.8 * scale_multiplier
	particles.color = color
	particles.restart()


func stage_clear(world_size: Vector2, color: Color) -> void:
	if _motion_is_reduced():
		burst(world_size * 0.5, color, 1.0)
		return
	for index: int in 8:
		var position := Vector2(
			world_size.x * (0.1 + 0.8 * float(index % 4) / 3.0),
			world_size.y * (0.25 + 0.5 * float(index / 4)),
		)
		burst(position, color, 1.35)


func debug_snapshot() -> Dictionary:
	return {
		"child_count": get_child_count(),
		"burst_capacity": _burst_pool.size(),
		"reduced_motion": _motion_is_reduced(),
		"atmosphere_enabled": _atmosphere_enabled,
		"time_of_day": _time_of_day,
		"day_phase": _day_phase,
		"dusk_strength": _dusk_strength,
		"night_strength": _night_strength,
		"weather": _weather,
		"weather_intensity": _weather_intensity,
		"wind_strength": _wind_strength,
		"fireflies_active": _fireflies != null and _fireflies.emitting,
		"rain_active": _weather_particles != null and _weather_particles.emitting and _weather == "rain",
		"wind_particles_active": _weather_particles != null and _weather_particles.emitting and _weather == "wind",
		"weather_particles_kind": _active_weather_particles_kind,
		"window_glow_count": _window_glows.size(),
	}


func _apply_day_phase() -> void:
	_dusk_strength = _dusk_for_hour(_time_of_day)
	_night_strength = _night_for_hour(_time_of_day)
	_enable_atmosphere()
	_refresh_particles()
	_refresh_shader_parameters()
	_refresh_window_glows()


func _apply_village_lowfi_style() -> void:
	var village_root := get_parent()
	if village_root == null or village_root.name != "Village":
		return
	var background := village_root.get_node_or_null("VillageBackground") as Sprite2D
	if background != null and background.texture != null:
		background.material = _make_lowfi_material(background.texture, 4.0, 14.0, 0.56)
	var actors := village_root.get_node_or_null("Actors")
	if actors == null:
		return
	for sprite_node: Node in actors.find_children("*", "Sprite2D", true, false):
		var sprite := sprite_node as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		sprite.material = _make_lowfi_material(sprite.texture, 8.0, 12.0, 0.78)


func _make_lowfi_material(source_texture: Texture2D, pixel_block: float, color_steps: float, saturation: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = VILLAGE_LOWFI_SHADER
	material.set_shader_parameter("source_texture", source_texture)
	material.set_shader_parameter("pixel_block", pixel_block)
	material.set_shader_parameter("color_steps", color_steps)
	material.set_shader_parameter("saturation", saturation)
	return material


func _enable_atmosphere() -> void:
	_atmosphere_enabled = true
	_overlay.visible = true


func _sync_world_bounds() -> void:
	if _overlay != null:
		_overlay.position = _world_size * ((1.0 - OVERLAY_OVERSCAN) * 0.5)
		_overlay.size = _world_size * OVERLAY_OVERSCAN
	if _fireflies != null:
		_fireflies.position = _world_size * 0.5
		_fireflies.emission_rect_extents = _world_size * 0.48
	if _weather_particles != null:
		_weather_particles.position = _world_size * 0.5
		_weather_particles.emission_rect_extents = _world_size * 0.6


func _refresh_shader_parameters() -> void:
	if _overlay_material == null:
		return
	_overlay_material.set_shader_parameter("dusk_strength", _dusk_strength)
	_overlay_material.set_shader_parameter("night_strength", _night_strength)
	_overlay_material.set_shader_parameter("cloudiness", _cloudiness)


func _refresh_particles() -> void:
	if _fireflies == null or _weather_particles == null:
		return
	var density := maxf(0.0, float(TuningStore.get_value("environment.particles.density", 1.0)))
	var reduced := _motion_is_reduced()
	var nighttime := _time_of_day >= 17.0 or _time_of_day < 6.0
	var fireflies_active := (
		_fireflies_allowed
		and nighttime
		and _weather != "rain"
		and density > 0.0
		and not reduced
	)
	_fireflies.amount = clampi(roundi(30.0 * density), 1, 64)
	_fireflies.visible = fireflies_active
	_fireflies.gravity = Vector2(_wind_strength * 2.0 if _weather == "wind" else 0.0, -0.4)
	if _fireflies.emitting != fireflies_active:
		_fireflies.emitting = fireflies_active
		if fireflies_active:
			_fireflies.restart()

	var weather_active := (
		_weather in ["rain", "wind"]
		and _weather_intensity > 0.0
		and density > 0.0
		and not reduced
	)
	_weather_particles.visible = weather_active
	if not weather_active:
		_weather_particles.emitting = false
		_active_weather_particles_kind = ""
		return
	var weather_mode_changed := _weather != _active_weather_particles_kind
	_weather_particles.emitting = true
	if _weather == "rain":
		_weather_particles.texture = _rain_texture
		_weather_particles.amount = clampi(roundi(84.0 * density * _weather_intensity), 8, 160)
		_weather_particles.lifetime = 1.0
		_weather_particles.direction = Vector2(_wind_strength * 0.24, 1.0).normalized()
		_weather_particles.spread = 3.0
		_weather_particles.gravity = Vector2.ZERO
		_weather_particles.initial_velocity_min = 270.0 * _weather_intensity
		_weather_particles.initial_velocity_max = 390.0 * _weather_intensity
		_weather_particles.scale_amount_min = 0.75
		_weather_particles.scale_amount_max = 1.25
		_weather_particles.color = Color(0.72, 0.82, 0.96, 0.42)
	else:
		_weather_particles.texture = _leaf_texture
		_weather_particles.amount = clampi(roundi(18.0 * density * _weather_intensity), 3, 48)
		_weather_particles.lifetime = 5.0
		_weather_particles.direction = Vector2(signf(_wind_strength), 0.18).normalized()
		_weather_particles.spread = 18.0
		_weather_particles.gravity = Vector2(_wind_strength * 8.0, 4.0)
		_weather_particles.initial_velocity_min = 12.0 * _weather_intensity
		_weather_particles.initial_velocity_max = 38.0 * _weather_intensity
		_weather_particles.scale_amount_min = 0.75
		_weather_particles.scale_amount_max = 1.7
		_weather_particles.color = Color(0.89, 0.75, 0.48, 0.55)
	if weather_mode_changed:
		_active_weather_particles_kind = _weather
		_weather_particles.restart()


func _refresh_window_glows() -> void:
	var evening_factor := maxf(_dusk_strength, _night_strength)
	for entry_value: Variant in _window_glows.values():
		var entry: Dictionary = entry_value
		var glow := entry.get("node") as Sprite2D
		if not is_instance_valid(glow):
			continue
		var intensity := float(entry.get("intensity", 1.0))
		glow.visible = _atmosphere_enabled and evening_factor > 0.02 and intensity > 0.0
		glow.modulate = Color(1.0, 0.66, 0.34, clampf(evening_factor * intensity * 0.72, 0.0, 1.0))


func _phase_for_hour(hour24: float) -> String:
	if hour24 < 6.0 or hour24 >= 20.0:
		return "night"
	if hour24 < 11.0:
		return "morning"
	if hour24 < 16.0:
		return "day"
	if hour24 < 20.0:
		return "evening"
	return "night"


func _dusk_for_hour(hour24: float) -> float:
	if hour24 >= 15.0 and hour24 <= 19.0:
		return smoothstep(15.0, 18.5, hour24)
	if hour24 > 19.0:
		return 1.0
	if hour24 < 7.0:
		return 1.0 - smoothstep(4.0, 7.0, hour24)
	return 0.0


func _night_for_hour(hour24: float) -> float:
	if hour24 >= 18.0:
		return smoothstep(18.0, 22.0, hour24)
	if hour24 < 7.0:
		return 1.0 - smoothstep(4.0, 7.0, hour24)
	return 0.0


func _cloudiness_for_weather(kind: String, intensity: float) -> float:
	match kind:
		"cloudy":
			return intensity
		"rain":
			return 0.48 + intensity * 0.42
		_:
			return 0.0


func _motion_is_reduced() -> bool:
	return _reduced_motion or bool(TuningStore.get_value("ui.reduced_motion", false))


func _make_radial_texture(size: int) -> ImageTexture:
	var dimension := maxi(4, size)
	var center := Vector2.ONE * (dimension - 1) * 0.5
	var edge_radius := maxf(1.0, dimension * 0.5)
	var image := Image.create(dimension, dimension, false, Image.FORMAT_RGBA8)
	for y: int in dimension:
		for x: int in dimension:
			var radius := Vector2(x, y).distance_to(center) / edge_radius
			var alpha := 1.0 - smoothstep(0.04, 1.0, radius)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _make_rain_texture() -> ImageTexture:
	var image := Image.create(3, 20, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)


func _make_leaf_texture() -> ImageTexture:
	var image := Image.create(16, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	for y: int in 8:
		for x: int in 16:
			var dx := (float(x) - 7.5) / 7.5
			var dy := (float(y) - 3.5) / 3.5
			if dx * dx + dy * dy <= 1.0:
				image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)


func _on_tuning_changed(id: String, _requested: Variant, _active: Variant) -> void:
	if id in ["environment.particles.density", "ui.reduced_motion"]:
		_refresh_particles()
