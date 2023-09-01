class_name Player
extends Area2D

signal life_lost

@export var speed = 500
@export var shoot_cooldown = 0.5
@export var projectile_scene: PackedScene

var paddle_length
var screen_size
var last_shot = 0
var _firing_enabled: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	shoot_cooldown *= 1000
	screen_size = get_viewport_rect().size
	paddle_length = $CollisionShape2D.shape.size.x / 2

func _process(delta):
	if(Input.is_action_pressed("shoot") && (Time.get_ticks_msec() - last_shot) > shoot_cooldown
			&& _firing_enabled):
		_shoot()
		last_shot = Time.get_ticks_msec()
		
	var velocity = Vector2.ZERO # Player's movement vector
									
	if(Input.is_action_pressed("left")):
		velocity.x -= 1
	if(Input.is_action_pressed("right")):
		velocity.x += 1
				
	position += velocity * delta * speed
	position.x = clamp(position.x, 0 + paddle_length, screen_size.x - paddle_length)

func _shoot():
	var rocket = projectile_scene.instantiate()
	rocket.position = Vector2(position.x, position.y - 130)
	rocket.set_direction(1)
	get_parent().add_child(rocket)

func enable_shooting():
	_firing_enabled = true
	
func disable_shooting():
	_firing_enabled = false

func _on_area_entered(_area):
	life_lost.emit()
