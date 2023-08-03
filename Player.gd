extends Area2D

@export var speed = 500
@export var projectile_scene: PackedScene

var paddle_length
var screen_size

var rocket_sprite = load("res://icon.svg")

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	paddle_length = $CollisionShape2D.shape.size.x / 2

func _process(delta):
	if(Input.is_action_pressed("shoot")):
		_shoot()
		
	var velocity = Vector2.ZERO # Player's movement vector
									
	if(Input.is_action_pressed("left")):
		velocity.x -= 1
	if(Input.is_action_pressed("right")):
		velocity.x += 1
				
	position += velocity * delta * speed
	position.x = clamp(position.x, 0 + paddle_length, screen_size.x - paddle_length)

func _shoot():
	var rocket = projectile_scene.instantiate()
	rocket.get_child(0).texture = rocket_sprite
	rocket.position = Vector2(randf_range(0, 500), randf_range(0, 500))
	get_parent().add_child(rocket)
