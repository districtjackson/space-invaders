extends Node2D

@export var projectile_scene: PackedScene
@export var player_scene: PackedScene
@export var enemy_manager_scene: PackedScene

# Statically typed enemy manager reference
var _Enemy_Manager: Enemy_Manager
var _Player: Player

var _lives = 3
var _score = 0
@onready var _high_score = _get_high_score()


## Called by start button in main menu
func _start_game() -> void:
	_lives = 3
	_score = 0
	
	$HUD.change_score(_score)
	$HUD.set_high_score(_high_score)
	
	_Player = _spawn_player()
	# Creates the enemy_manager_scene
	_instantiate_enemies(_Player)
	
	return


func _spawn_player() -> Player:
	var player = player_scene.instantiate()
	
	player.position = Vector2(490, 900)
	
	player.life_lost.connect(_on_player_life_lost)
	
	call_deferred("add_child", player)
	
	return player


# Create enemy_manager to handle all enemy behavior
func _instantiate_enemies(player: Player) -> void:
	_Enemy_Manager = enemy_manager_scene.instantiate()
	
	_Enemy_Manager.enemy_destroyed.connect(_on_enemy_destroyed)
	# If enemy reaches bottom, player loses a life
	_Enemy_Manager.enemy_reached_bottom.connect(_on_player_life_lost)
	_Enemy_Manager.all_enemies_destroyed.connect(on_all_enemies_cleared)
	
	add_child(_Enemy_Manager)
	
	_Enemy_Manager.init(player) # Give player reference and start enemy spawn and motion
	
	return

# Called when an enemy dies, telling main to decrease count of remaining enemies, increase score, and speed up enemies
func _on_enemy_destroyed() -> void:
	_score += 100
	$HUD.change_score(_score)
	
	return


func _on_player_life_lost() -> void:
	# Might be a race condition if a player gets shot at the same time that the enemies hit the bottom
	_lives -= 1

	_Enemy_Manager.queue_free()
	_clear_entities()
	_destroy_player()

	if(_lives <= 0):
		_end_game()
		return

	_reset_round()


func _reset_round() -> void:
	_Player = _spawn_player()
	_instantiate_enemies(_Player)


func _end_game() -> void:
	$HUD.game_over()
	
	if(_score > _high_score):
		_high_score = _score
		_save_high_score(_high_score)


func on_all_enemies_cleared() -> void:
		_Enemy_Manager.queue_free()
		_instantiate_enemies(_Player)


func _clear_entities() -> void:
	# Delete all remaining enemies and projectiles
	for i in self.get_children():
		if(i.has_method("destroy")):
			i.destroy()


func _destroy_player() -> void:
	_Player.queue_free()


# Saves provided high score at user://space_invaders.save
func _save_high_score(high_score) -> void:
	print("Saving game...")
	
	var save_dict = {
		"score" : high_score
	}
	
	var save = FileAccess.open("user://space_invaders.save", FileAccess.WRITE)
	
	var json_string = JSON.stringify(save_dict)
	
	save.store_line(json_string)
	
	print("High score saved")


func _get_high_score():
	# See if a save high score even exists
	if not FileAccess.file_exists("user://space_invaders.save"):
		print("Save game file does not exist")
		return 0 # Error! We don't have a save to load.

	# Open save file
	var save = FileAccess.open("user://space_invaders.save", FileAccess.READ)
	
	# Get JSON line
	var json_string = save.get_line()
	
	# Helper class to interact with JSON
	var json = JSON.new()
	
	# Error checking
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
	
	# Get data from JSON object
	var node_data = json.get_data()
	
	return node_data["score"]
