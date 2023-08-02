extends Area2D

@export var speed = 500

var paddle_length
var screen_size

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	paddle_length = $CollisionShape2D.shape.size.x / 2

func _process(delta):
	var velocity = Vector2.ZERO # Player's movement vector
									
	if(Input.is_action_pressed("left")):
		velocity.x -= 1
	if(Input.is_action_pressed("right")):
		velocity.x += 1
				
	position += velocity * delta * speed
	position.x = clamp(position.x, 0 + paddle_length, screen_size.x - paddle_length)
