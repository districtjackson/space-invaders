extends CanvasLayer

signal start_game

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _start_game():
	_toggle_main_menu()
	start_game.emit()
	
func _quit_game():
	get_tree().queue_free()
	
func game_over():
	_toggle_main_menu()

func _toggle_main_menu():
	$StartGame.visible = !$StartGame.visible
	$QuitGame.visible = !$QuitGame.visible
