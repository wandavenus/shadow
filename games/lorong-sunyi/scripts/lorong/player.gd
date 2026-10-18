extends CharacterBody2D
class_name LorongPlayer

const PLAYER_TEXTURE: Texture2D = preload("res://assets/characters/catalog-kenney/PNG/Round (outline)/rabbit.png")
const SPRITE_BASE_SCALE := 0.22

var move_speed := 170.0
var visual_scale := 1.0
var reduced_motion := false
var movement_enabled := true
var _walk_clock := 0.0
var _sprite: Sprite2D


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

	_sprite = Sprite2D.new()
	_sprite.name = "KelinciChibi"
	_sprite.texture = PLAYER_TEXTURE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.position.y = -float(PLAYER_TEXTURE.get_height()) * SPRITE_BASE_SCALE * 0.46
	add_child(_sprite)
	_refresh_scale()


func _physics_process(delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return

	var input_axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var oblique_axis := Vector2(input_axis.x, input_axis.y * 0.72)
	if oblique_axis.length_squared() > 0.001:
		oblique_axis = oblique_axis.normalized()
		velocity = oblique_axis * move_speed
		_walk_clock += delta
		if input_axis.x != 0.0:
			_sprite.flip_h = input_axis.x < 0.0
		_sprite.position.y = -float(PLAYER_TEXTURE.get_height()) * SPRITE_BASE_SCALE * visual_scale * 0.46
		if not reduced_motion:
			_sprite.position.y -= absf(sin(_walk_clock * 10.0)) * 1.6
	else:
		velocity = Vector2.ZERO
		_sprite.position.y = -float(PLAYER_TEXTURE.get_height()) * SPRITE_BASE_SCALE * visual_scale * 0.46

	move_and_slide()
	position.x = clampf(position.x, 76.0, 1204.0)
	position.y = clampf(position.y, 280.0, 665.0)


func set_move_speed(value: float) -> void:
	move_speed = clampf(value, 60.0, 360.0)


func set_visual_scale(value: float) -> void:
	visual_scale = clampf(value, 0.6, 1.8)
	_refresh_scale()


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value


func set_hidden(value: bool) -> void:
	visible = not value
	movement_enabled = not value
	velocity = Vector2.ZERO


func _refresh_scale() -> void:
	if _sprite == null:
		return
	_sprite.scale = Vector2.ONE * SPRITE_BASE_SCALE * visual_scale
	_sprite.position.y = -float(PLAYER_TEXTURE.get_height()) * SPRITE_BASE_SCALE * visual_scale * 0.46
