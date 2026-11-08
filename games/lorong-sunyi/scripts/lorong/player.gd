extends CharacterBody2D
class_name LorongPlayer

const PLAYER_TEXTURE: Texture2D = preload("res://assets/characters/desa-hewan/mika-fox-runtime-384x576.png")
const CharacterVisualScript = preload("res://scripts/lorong/character_visual.gd")
const SPRITE_BASE_SCALE := 0.18

var move_speed := 170.0
var visual_scale := 1.0
var reduced_motion := false
var facing_direction := Vector2.RIGHT
var _visual: Node2D


func _ready() -> void:
	name = "Mika"
	collision_layer = 1
	collision_mask = 1
	floor_stop_on_slope = false
	max_slides = 4

	var body_shape := CollisionShape2D.new()
	body_shape.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	body_shape.shape = circle
	add_child(body_shape)

	var shadow := Polygon2D.new()
	shadow.name = "GroundShadow"
	shadow.color = Color(0.025, 0.035, 0.055, 0.36)
	shadow.polygon = PackedVector2Array([
		Vector2(-17.0, -4.0), Vector2(-11.0, -7.0), Vector2(0.0, -8.0), Vector2(11.0, -7.0),
		Vector2(17.0, -4.0), Vector2(11.0, -1.0), Vector2(0.0, 0.0), Vector2(-11.0, -1.0),
	])
	shadow.position = Vector2(0.0, 4.0)
	shadow.z_index = -1
	add_child(shadow)

	_visual = CharacterVisualScript.new() as Node2D
	_visual.name = "CharacterVisual"
	_visual.call("configure", PLAYER_TEXTURE, "fox", Color.WHITE, SPRITE_BASE_SCALE, "Mika", "PENJELAJAH")
	add_child(_visual)


func _physics_process(_delta: float) -> void:
	var input_axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var oblique_axis := Vector2(input_axis.x, input_axis.y * 0.72)
	var is_moving := oblique_axis.length_squared() > 0.001
	if is_moving:
		oblique_axis = oblique_axis.normalized()
		facing_direction = oblique_axis
		velocity = oblique_axis * move_speed
		if input_axis.x != 0.0:
			_visual.call("set_facing_left", input_axis.x < 0.0)
	else:
		velocity = Vector2.ZERO
	_visual.call("set_moving", is_moving)

	move_and_slide()
	position.x = clampf(position.x, 76.0, 1204.0)
	position.y = clampf(position.y, 280.0, 665.0)


func set_move_speed(value: float) -> void:
	move_speed = clampf(value, 60.0, 360.0)


func set_visual_scale(value: float) -> void:
	visual_scale = clampf(value, 0.6, 1.8)
	if _visual != null:
		_visual.call("set_scale_factor", visual_scale)


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if _visual != null:
		_visual.call("set_reduced_motion", value)
