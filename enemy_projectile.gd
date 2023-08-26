extends Area2D

var speed = 600

var screen_size
var projectile_length

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set these for deleting the projectile automatically if it fully goes off screen
	screen_size = get_viewport_rect().size
	projectile_length = $CollisionShape2D.shape.size.x

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += Vector2(0, speed) * delta
	
	if(position.y <= 0 - projectile_length or position.y >= screen_size.y + projectile_length):
		queue_free()

func _on_area_entered(_area):
	queue_free()
	
func destroy():
	queue_free()
