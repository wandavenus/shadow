extends StaticBody2D
class_name LorongInteractiveProp

var prop_id := ""
var display_name := ""
var definition: Dictionary = {}
var _sprite: Sprite2D
var _base_scale := 1.0
var _focused := false
var _state: Dictionary = {}


func configure(spec: Dictionary, atlas: Texture2D) -> void:
	definition = spec.duplicate(true)
	prop_id = str(definition.get("id", ""))
	display_name = str(definition.get("name", "Benda"))
	name = "Prop_%s" % prop_id
	position = definition.get("position", Vector2.ZERO)
	_base_scale = float(definition.get("scale", 1.0))
	collision_layer = 1
	collision_mask = 0
	input_pickable = false

	var region_values: Array = definition.get("region", [0, 0, 32, 32])
	var region := Rect2(
		float(region_values[0]), float(region_values[1]),
		float(region_values[2]), float(region_values[3])
	)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = atlas
	_sprite.region_enabled = true
	_sprite.region_rect = region
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * _base_scale
	# The Node2D origin is the prop's ground contact point for Y-sorting and collision.
	_sprite.position = Vector2(0.0, -region.size.y * _base_scale * 0.5)
	add_child(_sprite)

	var radius := float(definition.get("collision_radius", 0.0))
	if radius > 0.0:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = radius
		collision.shape = circle
		add_child(collision)
	_refresh_look()


func set_focused(value: bool) -> void:
	if _focused == value:
		return
	_focused = value
	_refresh_look()


func set_visual_state(new_state: Dictionary) -> void:
	_state = new_state.duplicate(true)
	_refresh_look()


func set_world_position(world_position: Vector2) -> void:
	position = world_position


func _refresh_look() -> void:
	if _sprite == null:
		return
	var target_region: Array = definition.get("region", [0, 0, 32, 32])
	if bool(_state.get("open", false)) and definition.has("open_region"):
		target_region = definition.open_region
	_sprite.region_rect = Rect2(
		float(target_region[0]), float(target_region[1]),
		float(target_region[2]), float(target_region[3])
	)
	_sprite.scale = Vector2.ONE * _base_scale * (1.045 if _focused else 1.0)
	_sprite.position.y = -_sprite.region_rect.size.y * _sprite.scale.y * 0.5
	if bool(_state.get("door_open", false)):
		visible = false
	else:
		visible = true
	var tint := Color.WHITE
	if prop_id == "lampu" and bool(_state.get("lamp_on", false)):
		tint = Color(1.0, 0.74, 0.36, 1.0)
	if bool(_state.get("open", false)) and prop_id != "pintu":
		tint = tint.lerp(Color(0.84, 0.76, 0.65, 1.0), 0.22)
	if _focused:
		tint = tint.lerp(Color(1.0, 0.84, 0.56, 1.0), 0.28)
	_sprite.modulate = tint
