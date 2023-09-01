extends Node2D

@export var projectile_scene: PackedScene
@export var player_scene: PackedScene
@export var enemy_manager_scene: PackedScene
@export var mothership_scene: PackedScene

## How often (in seconds) the game rolls to spawn a mothership
@export var mothership_spawn_cooldown = 5

## Chance of mothership spawning on attempt
@export var mothership_spawn_chance = 0.25

# Statically typed enemy manager reference
var _Enemy_Manager: Enemy_Manager
var _Player: Player
var _Mothership: Mothership

var _lives = 3
var _score = 0
@onready var _high_score = _get_high_score()

# Tracks if the enemies were fully cleared by the player, rather than the player losing a life.
# This is important, as the player will be in play while the enemies respawns, so it shouldn't try
# to re-add the player to the tree, or allow the player to shoot until they are finished
var _enemies_were_cleared: bool = false

# Keeps time of latest mothership spawn attempt
var _last_mothership_spawn_attempt = 0

func _ready():
	set_process(false)
	
	# Transform the seconds to milliseconds
	mothership_spawn_cooldown *= 1000

func _process(_delta):
	# Handles randomly spawning the mothership. Rolls to do so after a set
	# amount of time
	if _Mothership == null and (Time.get_ticks_msec() - _last_mothership_spawn_attempt) > mothership_spawn_cooldown:
		_last_mothership_spawn_attempt = Time.get_ticks_msec()
		
		var random_number = randf()
		
		if random_number <= mothership_spawn_chance:
			var side = randf()
			
			if side > 0.5:
				_spawn_mothership(true)
			else:
				_spawn_mothership(false)


## Called by start button in main menu
func _start_game() -> void:
	_lives = 3
	_score = 0
	
	$HUD.change_score(_score)
	$HUD.set_high_score(_high_score)
	
	_Player = _instantiate_player()
	
	# Creates the enemy_manager_scene
	_instantiate_enemies(_Player, true)
	
	return


func _instantiate_player() -> Player:
	var player = player_scene.instantiate()
	
	player.position = Vector2(490, 900)
	
	player.life_lost.connect(_on_player_life_lost)
	
	return player


# Finishes preparing the player for the game round by either adding it to the scene
# or enabling its shooting, and is called after the enemies finish spawning
# the 
func _initialize_player(player: Player) -> void:
	if _enemies_were_cleared == false:
		add_child(player)
	else:
		player.enable_shooting()
		
		_enemies_were_cleared == false
		
	

# Create enemy_manager to handle all enemy behavior
func _instantiate_enemies(player: Player, is_first_life) -> void:
	_Enemy_Manager = enemy_manager_scene.instantiate()
	
	_Enemy_Manager.enemy_destroyed.connect(_on_enemy_destroyed)
	# If enemy reaches bottom, player loses a life
	_Enemy_Manager.enemy_reached_bottom.connect(_on_player_life_lost)
	_Enemy_Manager.all_enemies_destroyed.connect(on_all_enemies_cleared)
	_Enemy_Manager.enemies_spawned.connect(enemies_spawned)
	
	add_child(_Enemy_Manager)
	
	await _Enemy_Manager.init(player, is_first_life) # Give player reference and start enemy spawn and motion
	
	_initialize_player(player)
	
	return


# Starts the rolling for mothership spawn when
# all the enemies have been spawned
func enemies_spawned():
	
	
	# Move time up so it doesn't try to spawn
	# immediately
	_last_mothership_spawn_attempt = Time.get_ticks_msec()
	
	set_process(true)


func _spawn_mothership(side):
	_Mothership = mothership_scene.instantiate()
	
	_Mothership.mothership_destroyed.connect(on_mothership_destroyed)
	
	add_child(_Mothership)
	
	if side:
		_Mothership.spawn_left()
	else:
		_Mothership.spawn_right()


# Called when an enemy dies, telling main to decrease count of remaining enemies, increase score, and speed up enemies
func _on_enemy_destroyed() -> void:
	_score += 100
	$HUD.change_score(_score)


func on_mothership_destroyed() -> void:
	_score += 1000
	$HUD.change_score(_score)


func _on_player_life_lost() -> void:
	# Might be a race condition if a player gets shot at the same time that the enemies hit the bottom
	_lives -= 1

	_Enemy_Manager.queue_free()
	
	_clear_entities()
	_destroy_player()
	
	# Do not spawn mothership while round is not
	# active
	set_process(false)

	if(_lives <= 0):
		_end_game()
		return

	_reset_round()


func _reset_round() -> void:
	_Player = _instantiate_player()
	_instantiate_enemies(_Player, false)


func _end_game() -> void:
	$HUD.game_over()
	
	if(_score > _high_score):
		_high_score = _score
		_save_high_score(_high_score)
		
	# Stops the rolling for mothership spawn
	set_process(false)


func on_all_enemies_cleared() -> void:
	_enemies_were_cleared = true
	_Player.disable_shooting()
	
	_Enemy_Manager.queue_free()
		
	# Do not spawn mothership while round is not active
	set_process(false)
		
	_instantiate_enemies(_Player, false)


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
