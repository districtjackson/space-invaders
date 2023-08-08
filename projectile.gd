extends Area2D

var speed = 40
var direction = 1 # 1 for Up and -1 for down

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += Vector2(0, direction * -speed) * delta


func _on_area_entered(area):
	queue_free()

func set_direction(d):
	direction = d
