extends Node2D
class_name LorongCharacterVisual

const DEFAULT_SPRITE_SCALE := 0.18

var _texture: Texture2D
var _species := "fox"
var _tint := Color.WHITE
var _base_scale := DEFAULT_SPRITE_SCALE
var _scale_factor := 1.0
var _display_name := "Warga"
var _activity_text := ""
var _moving := false
var _reduced_motion := false
var _facing_left := false
var _clock := 0.0
var _sprite: Sprite2D
var _tail_root: Node2D
var _tail_shape: Polygon2D
var _limb_root: Node2D
var _limb_lines: Dictionary = {}
var _current_arm_swing := 0.0
var _current_leg_swing := 0.0
var _name_tag: PanelContainer
var _name_label: Label
var _activity_label: Label
var _base_sprite_y := 0.0
var _tail_base_angle := 0.0
var _tail_amplitude := 0.2


func configure(texture: Texture2D, species: String, tint: Color = Color.WHITE, base_scale: float = DEFAULT_SPRITE_SCALE, display_name: String = "Warga", activity_text: String = "") -> void:
	_texture = texture
	_species = species
	_tint = tint
	_base_scale = clampf(base_scale, 0.02, 0.5)
	_display_name = display_name
	_activity_text = activity_text
	_tail_base_angle = _tail_angle_for_species(species)
	_tail_amplitude = _tail_amplitude_for_species(species)


func _ready() -> void:
	if _texture == null:
		push_error("LorongCharacterVisual needs a full-body texture")
		return
	_build_tail()
	_sprite = Sprite2D.new()
	_sprite.name = "BodySprite"
	_sprite.texture = _texture
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.modulate = _tint
	add_child(_sprite)
	_build_limb_rig()
	_refresh_sprite_transform()
	_set_facing_left(_facing_left)
	_build_name_tag()


func _process(delta: float) -> void:
	if _sprite == null or delta <= 0.0:
		return
	if _reduced_motion:
		_sprite.position.y = _base_sprite_y
		_sprite.rotation = 0.0
		if _tail_root != null:
			_tail_root.rotation = _tail_base_angle
		_update_limb_pose(0.0, false)
		_sync_limb_transform()
		return
	_clock += delta
	if _moving:
		var stride := sin(_clock * 11.0)
		_sprite.position.y = _base_sprite_y - absf(stride) * 1.8
		_sprite.rotation = stride * 0.026
		if _tail_root != null:
			_tail_root.rotation = _tail_base_angle + sin(_clock * 7.0) * _tail_amplitude
		_update_limb_pose(stride, true)
	else:
		var breathe := sin(_clock * 2.8)
		_sprite.position.y = _base_sprite_y - (0.5 + 0.5 * breathe) * 0.8
		_sprite.rotation = breathe * 0.012
		if _tail_root != null:
			_tail_root.rotation = _tail_base_angle + sin(_clock * 2.3) * _tail_amplitude * 0.55
		_update_limb_pose(sin(_clock * 1.8), false)
	_sync_limb_transform()


func set_moving(value: bool) -> void:
	_moving = value


func set_reduced_motion(value: bool) -> void:
	_reduced_motion = value
	if value and _sprite != null:
		_sprite.position.y = _base_sprite_y
		_sprite.rotation = 0.0
		if _tail_root != null:
			_tail_root.rotation = _tail_base_angle
		_update_limb_pose(0.0, false)
		_sync_limb_transform()


func set_facing_left(value: bool) -> void:
	_facing_left = value
	_set_facing_left(value)


func set_scale_factor(value: float) -> void:
	_scale_factor = clampf(value, 0.6, 1.8)
	_refresh_sprite_transform()
	_sync_limb_transform()


func set_activity_text(value: String) -> void:
	_activity_text = value
	if _activity_label != null:
		_activity_label.text = value
		_activity_label.visible = not value.is_empty()


func animation_snapshot_for_testing() -> Dictionary:
	return {
		"species": _species,
		"state": "walk" if _moving else "idle",
		"has_tail": _tail_shape != null and is_instance_valid(_tail_shape),
		"tail_rotation": _tail_root.rotation if _tail_root != null else 0.0,
		"body_y": _sprite.position.y if _sprite != null else 0.0,
		"body_rotation": _sprite.rotation if _sprite != null else 0.0,
		"limb_count": _limb_lines.size(),
		"arm_swing": _current_arm_swing,
		"leg_swing": _current_leg_swing,
		"reduced_motion": _reduced_motion,
		"texture_size": _texture.get_size() if _texture != null else Vector2.ZERO,
		"name_text": _name_label.text if _name_label != null else "",
		"name_tag_size": _name_tag.size if _name_tag != null else Vector2.ZERO,
		"name_font_size": _name_label.label_settings.font_size if _name_label != null and _name_label.label_settings != null else 0,
		"activity_text": _activity_label.text if _activity_label != null else "",
	}


func advance_animation_for_testing(delta: float) -> void:
	_process(delta)


func _build_tail() -> void:
	_tail_root = Node2D.new()
	_tail_root.name = "AnimatedTail"
	_tail_root.position = Vector2(-8.0, -30.0)
	_tail_root.z_index = -1
	add_child(_tail_root)

	var points := _tail_polygon_for_species(_species)
	_tail_shape = Polygon2D.new()
	_tail_shape.name = "TailShape"
	_tail_shape.polygon = points
	_tail_shape.color = _tail_color_for_species(_species)
	_tail_root.add_child(_tail_shape)

	var outline := Line2D.new()
	outline.name = "TailOutline"
	outline.points = points
	outline.closed = true
	outline.width = 2.4
	outline.default_color = Color(0.10, 0.105, 0.12, 0.98)
	_tail_root.add_child(outline)

	var tip_points := _tail_tip_for_species(_species)
	if not tip_points.is_empty():
		var tip := Polygon2D.new()
		tip.name = "TailTip"
		tip.polygon = tip_points
		tip.color = Color(0.94, 0.85, 0.69, 1.0)
		_tail_root.add_child(tip)


func _build_limb_rig() -> void:
	_limb_root = Node2D.new()
	_limb_root.name = "LimbRig"
	_limb_root.z_index = 1
	add_child(_limb_root)
	var sleeve_color := _limb_color_for_species(_species, false)
	var pants_color := _limb_color_for_species(_species, true)
	for limb_name: String in ["left_arm", "right_arm", "left_leg", "right_leg"]:
		var limb_color := pants_color if limb_name.ends_with("leg") else sleeve_color
		var outline := _make_limb_line(limb_name.capitalize() + "Outline", Color(0.075, 0.085, 0.105, 0.98), 6.0)
		var fill := _make_limb_line(limb_name.capitalize(), limb_color, 3.8)
		_limb_root.add_child(outline)
		_limb_root.add_child(fill)
		_limb_lines[limb_name] = [outline, fill]
	_update_limb_pose(0.0, false)


func _make_limb_line(line_name: String, color: Color, line_width: float) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.width = line_width
	line.default_color = color
	line.antialiased = false
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	return line


func _update_limb_pose(phase: float, walking: bool) -> void:
	if _limb_root == null:
		return
	var arm_swing := phase * 5.2 if walking and not _reduced_motion else (sin(_clock * 1.8) * 0.28 if not _reduced_motion else 0.0)
	var leg_swing := -phase * 4.4 if walking and not _reduced_motion else 0.0
	_current_arm_swing = arm_swing
	_current_leg_swing = leg_swing
	_set_limb_points("left_arm", PackedVector2Array([
		Vector2(-9.0, -61.0), Vector2(-14.0 + arm_swing * 0.58, -49.0), Vector2(-15.0 + arm_swing, -37.0),
	]))
	_set_limb_points("right_arm", PackedVector2Array([
		Vector2(9.0, -61.0), Vector2(14.0 - arm_swing * 0.58, -49.0), Vector2(15.0 - arm_swing, -37.0),
	]))
	_set_limb_points("left_leg", PackedVector2Array([
		Vector2(-5.0, -33.0), Vector2(-7.0 + leg_swing * 0.66, -18.0), Vector2(-8.0 + leg_swing, -4.0),
	]))
	_set_limb_points("right_leg", PackedVector2Array([
		Vector2(5.0, -33.0), Vector2(7.0 - leg_swing * 0.66, -18.0), Vector2(8.0 - leg_swing, -4.0),
	]))


func _set_limb_points(limb_name: String, points: PackedVector2Array) -> void:
	var pair: Array = _limb_lines.get(limb_name, [])
	for line_value: Variant in pair:
		var line := line_value as Line2D
		if line != null:
			line.points = points


func _sync_limb_transform() -> void:
	if _limb_root != null:
		_limb_root.position.y = _sprite.position.y - _base_sprite_y if _sprite != null else 0.0
		_limb_root.scale = Vector2(-_scale_factor if _facing_left else _scale_factor, _scale_factor)
	if _tail_root != null:
		_tail_root.scale = Vector2(-_scale_factor if _facing_left else _scale_factor, _scale_factor)


func _limb_color_for_species(species: String, legs: bool) -> Color:
	if legs:
		return Color(0.22, 0.24, 0.29, 1.0)
	match species:
		"fox":
			return Color(0.19, 0.37, 0.40, 1.0)
		"goat":
			return Color(0.34, 0.39, 0.28, 1.0)
		"cat":
			return Color(0.67, 0.39, 0.43, 1.0)
		"rabbit":
			return Color(0.29, 0.39, 0.27, 1.0)
		"bear":
			return Color(0.68, 0.59, 0.47, 1.0)
		"dog":
			return Color(0.74, 0.48, 0.16, 1.0)
		_:
			return Color(0.38, 0.40, 0.34, 1.0)


func _build_name_tag() -> void:
	_name_tag = PanelContainer.new()
	_name_tag.name = "NameTag"
	_name_tag.position = Vector2(-92.0, -150.0)
	_name_tag.size = Vector2(184.0, 42.0)
	_name_tag.custom_minimum_size = _name_tag.size
	_name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_tag.z_index = 10
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.048, 0.063, 0.94)
	panel_style.border_color = Color(0.78, 0.68, 0.49, 0.96)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(4.0)
	_name_tag.add_theme_stylebox_override("panel", panel_style)

	var stack := VBoxContainer.new()
	stack.name = "TextStack"
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	_name_tag.add_child(stack)

	_name_label = Label.new()
	_name_label.name = "Name"
	_name_label.text = _display_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.label_settings = _tag_label_settings(15, Color(0.99, 0.95, 0.82), 2)
	stack.add_child(_name_label)

	_activity_label = Label.new()
	_activity_label.name = "Activity"
	_activity_label.text = _activity_text
	_activity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_activity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_activity_label.label_settings = _tag_label_settings(10, Color(0.83, 0.88, 0.82), 1)
	_activity_label.visible = not _activity_text.is_empty()
	stack.add_child(_activity_label)
	add_child(_name_tag)


func _tag_label_settings(font_size: int, font_color: Color, outline_size: int) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = font_color
	settings.outline_size = outline_size
	settings.outline_color = Color(0.04, 0.055, 0.07, 1.0)
	return settings


func _refresh_sprite_transform() -> void:
	if _sprite == null or _texture == null:
		return
	var scale_value := _base_scale * _scale_factor
	_sprite.scale = Vector2.ONE * scale_value
	_base_sprite_y = -float(_texture.get_height()) * scale_value * 0.46
	_sprite.position.y = _base_sprite_y


func _set_facing_left(value: bool) -> void:
	if _sprite != null:
		_sprite.flip_h = value
	_sync_limb_transform()


func _tail_polygon_for_species(species: String) -> PackedVector2Array:
	match species:
		"fox":
			return PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(-8.0, -8.0), Vector2(-18.0, -10.0), Vector2(-28.0, -5.0),
				Vector2(-33.0, 3.0), Vector2(-29.0, 11.0), Vector2(-19.0, 14.0), Vector2(-9.0, 8.0), Vector2(-2.0, 4.0),
			])
		"goat":
			return PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(-5.0, -4.0), Vector2(-11.0, -3.0), Vector2(-14.0, 1.0),
				Vector2(-12.0, 7.0), Vector2(-7.0, 8.0), Vector2(-3.0, 4.0),
			])
		"cat":
			return PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(-7.0, -6.0), Vector2(-16.0, -8.0), Vector2(-24.0, -5.0),
				Vector2(-30.0, 1.0), Vector2(-29.0, 6.0), Vector2(-24.0, 5.0), Vector2(-18.0, 0.0), Vector2(-10.0, 1.0), Vector2(-3.0, 5.0),
			])
		"rabbit":
			return PackedVector2Array([
				Vector2(-8.0, -7.0), Vector2(-2.0, -5.0), Vector2(1.0, 0.0), Vector2(-2.0, 6.0),
				Vector2(-8.0, 8.0), Vector2(-14.0, 6.0), Vector2(-17.0, 0.0), Vector2(-14.0, -5.0),
			])
		"bear":
			return PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(-5.0, -4.0), Vector2(-11.0, -3.0), Vector2(-14.0, 2.0),
				Vector2(-11.0, 7.0), Vector2(-5.0, 6.0),
			])
		"dog":
			return PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(-7.0, -5.0), Vector2(-15.0, -5.0), Vector2(-21.0, -1.0),
				Vector2(-22.0, 6.0), Vector2(-17.0, 11.0), Vector2(-10.0, 9.0), Vector2(-4.0, 4.0),
			])
		_:
			return PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(-7.0, -5.0), Vector2(-15.0, -4.0), Vector2(-18.0, 2.0),
				Vector2(-14.0, 8.0), Vector2(-7.0, 7.0),
			])


func _tail_tip_for_species(species: String) -> PackedVector2Array:
	if species == "fox":
		return PackedVector2Array([
			Vector2(-33.0, 3.0), Vector2(-28.0, 2.0), Vector2(-25.0, 7.0),
			Vector2(-29.0, 12.0), Vector2(-33.0, 9.0),
		])
	return PackedVector2Array()


func _tail_color_for_species(species: String) -> Color:
	match species:
		"fox":
			return Color(0.69, 0.34, 0.19, 1.0)
		"goat":
			return Color(0.78, 0.65, 0.45, 1.0)
		"cat":
			return Color(0.43, 0.34, 0.32, 1.0)
		"rabbit":
			return Color(0.90, 0.84, 0.73, 1.0)
		"bear":
			return Color(0.50, 0.36, 0.29, 1.0)
		"dog":
			return Color(0.70, 0.49, 0.31, 1.0)
		_:
			return Color(0.55, 0.44, 0.36, 1.0)


func _tail_angle_for_species(species: String) -> float:
	match species:
		"fox":
			return 0.20
		"cat":
			return -0.23
		"rabbit":
			return 0.0
		"goat":
			return 0.08
		"bear":
			return 0.12
		"dog":
			return 0.14
		_:
			return 0.0


func _tail_amplitude_for_species(species: String) -> float:
	match species:
		"fox":
			return 0.38
		"cat":
			return 0.56
		"rabbit":
			return 0.19
		"goat":
			return 0.22
		"bear":
			return 0.16
		"dog":
			return 0.48
		_:
			return 0.2
