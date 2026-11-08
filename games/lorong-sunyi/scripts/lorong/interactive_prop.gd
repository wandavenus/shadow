extends Node2D
class_name LorongVillageObject

var object_id := ""
var display_name := "Objek"
var kind := ""
var _art: Node2D
var _title: Label
var _focused := false
var _available := true


func configure(spec: Dictionary) -> void:
	object_id = str(spec.get("id", ""))
	display_name = str(spec.get("name", "Objek"))
	kind = str(spec.get("kind", ""))
	name = "VillageObject_%s" % object_id
	position = spec.get("position", Vector2.ZERO)

	_art = Node2D.new()
	_art.name = "Artwork"
	add_child(_art)
	if kind == "basket":
		_build_basket(spec.get("color", Color(0.62, 0.37, 0.20, 1.0)))
	elif kind == "flower":
		_build_flower(spec.get("color", Color(0.94, 0.72, 0.79, 1.0)))

	_title = Label.new()
	_title.name = "ObjectName"
	_title.text = display_name
	_title.position = Vector2(-72.0, -55.0)
	_title.size = Vector2(144.0, 20.0)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.label_settings = _label_settings(11, Color(0.98, 0.94, 0.82))
	add_child(_title)


func set_focused(value: bool) -> void:
	if _focused == value:
		return
	_focused = value
	if _art != null:
		_art.scale = Vector2.ONE * (1.08 if _focused else 1.0)
	if _title != null:
		_title.label_settings = _label_settings(11, Color(1.0, 0.82, 0.49) if _focused else Color(0.98, 0.94, 0.82))


func set_available(value: bool) -> void:
	_available = value
	visible = _available


func is_available() -> bool:
	return _available


func _build_basket(base_color: Color) -> void:
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-24.0, 0.0), Vector2(24.0, 0.0), Vector2(19.0, 8.0), Vector2(-19.0, 8.0)
	])
	shadow.color = Color(0.12, 0.12, 0.09, 0.30)
	_art.add_child(shadow)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-20.0, -23.0), Vector2(20.0, -23.0), Vector2(16.0, 2.0), Vector2(-16.0, 2.0)
	])
	body.color = base_color
	_art.add_child(body)

	var rim := Line2D.new()
	rim.points = PackedVector2Array([Vector2(-22.0, -23.0), Vector2(22.0, -23.0)])
	rim.width = 5.0
	rim.default_color = Color(0.79, 0.55, 0.31, 1.0)
	_art.add_child(rim)

	for y_offset: float in [-15.0, -7.0]:
		var slat := Line2D.new()
		slat.points = PackedVector2Array([Vector2(-18.0, y_offset), Vector2(18.0, y_offset)])
		slat.width = 2.0
		slat.default_color = Color(0.82, 0.58, 0.34, 0.92)
		_art.add_child(slat)

	for index: int in 3:
		var leaf := Polygon2D.new()
		var x_offset := float(index - 1) * 9.0
		leaf.polygon = PackedVector2Array([
			Vector2(x_offset - 7.0, -22.0), Vector2(x_offset, -37.0), Vector2(x_offset + 7.0, -22.0)
		])
		leaf.color = [Color(0.32, 0.55, 0.30), Color(0.46, 0.66, 0.34), Color(0.26, 0.47, 0.29)][index]
		_art.add_child(leaf)


func _build_flower(petal_color: Color) -> void:
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-15.0, 0.0), Vector2(15.0, 0.0), Vector2(11.0, 6.0), Vector2(-11.0, 6.0)
	])
	shadow.color = Color(0.12, 0.12, 0.09, 0.25)
	_art.add_child(shadow)

	var stem := Line2D.new()
	stem.points = PackedVector2Array([Vector2(0.0, -2.0), Vector2(0.0, -24.0)])
	stem.width = 3.0
	stem.default_color = Color(0.26, 0.53, 0.31, 1.0)
	_art.add_child(stem)

	for index: int in 5:
		var angle := TAU * float(index) / 5.0
		var center := Vector2(cos(angle), sin(angle)) * 9.0 + Vector2(0.0, -29.0)
		var petal := Polygon2D.new()
		petal.polygon = PackedVector2Array([
			center + Vector2(-4.0, -3.0), center + Vector2(4.0, -3.0),
			center + Vector2(6.0, 2.0), center + Vector2(0.0, 5.0), center + Vector2(-6.0, 2.0)
		])
		petal.color = petal_color
		_art.add_child(petal)

	var center_dot := Polygon2D.new()
	var center_points := PackedVector2Array()
	for index: int in 12:
		var angle := TAU * float(index) / 12.0
		center_points.append(Vector2(cos(angle), sin(angle)) * 4.0 + Vector2(0.0, -29.0))
	center_dot.polygon = center_points
	center_dot.color = Color(1.0, 0.81, 0.35, 1.0)
	_art.add_child(center_dot)


func _label_settings(font_size: int, font_color: Color) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = font_color
	settings.outline_size = 3
	settings.outline_color = Color(0.08, 0.11, 0.08, 0.94)
	return settings
