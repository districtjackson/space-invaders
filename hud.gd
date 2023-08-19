extends CanvasLayer

signal start_game

func _start_game():
	_toggle_main_menu()
	start_game.emit()
	_toggle_in_game()
	
func change_score(score):
	$Score.set_text(str(score))
	
func set_high_score(high_score):
	$HighScore.set_text(str(high_score))
	
func _quit_game():
	get_tree().quit()
	
func game_over():
	_toggle_in_game()
	_toggle_main_menu()

func _toggle_main_menu():
	$StartGame.visible = !$StartGame.visible
	$QuitGame.visible = !$QuitGame.visible

func _toggle_in_game():
	$Score.visible = !$Score.visible
	$HighScore.visible = !$HighScore.visible
