class_name Mothership
extends Area2D

signal mothership_destroyed

## Y value for mothership's spawn
@export var spawn_pos_y = 80

## Mothership's speed
@export var speed = 250

@onready var _screen_width =  get_viewport_rect().size.x
@onready var _collision_shape_half_length = $CollisionShape2D.shape.size.x / 2

# How far from the horizontal edge of the screen mothership will spawn,
# whether spawning on the left or right side
@onready var spawn_pos_x_offset = $CollisionShape2D.shape.size.x + 1

# Direction of mothership's movement (1 for right, -1 for left)
var _movement_direction

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if position.x - _collision_shape_half_length <= 0 or position.x + _collision_shape_half_length >= _screen_width:
		queue_free()
		
	position.x += delta * speed * _movement_direction


func spawn_left():
	_movement_direction = 1
	position = Vector2(spawn_pos_x_offset, spawn_pos_y)


func spawn_right():
	_movement_direction = -1
	position = Vector2(_screen_width - spawn_pos_x_offset, spawn_pos_y)
	

func _on_area_entered(_area):
	mothership_destroyed.emit()
	queue_free()
