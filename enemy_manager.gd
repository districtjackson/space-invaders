class_name Enemy_Manager
extends Node2D
## Controls all aspects of enemy behavior
##
## Will spawn enemies and have them start moving on instantiation, as well as
## have them shoot periodically. To erase the current batch of enemies and get new ones,
## free the current intialization of this class and instantiate a new one.

## Triggered when an enemy is killed
signal enemy_destroyed

## Triggered when the enemy reaches the designated y-value for the player to lose
signal enemy_reached_bottom

## Triggered when remaining enemies is equal to 0
signal all_enemies_destroyed

@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene

@export_category("Enemy Spawn Settings")

## Number of columns in enemy grid
@export 
var enemy_col_count: int = 11 

## Number of rows in enemy grid
@export 
var enemy_row_count: int = 5 

## Location in which enemy grid begins
@export 
var enemy_start = Vector2(10, 10)

## Horizontal space between enemies
@export 
var enemy_hori_distance = 50

## Vertical space betweene enemies
@export 
var enemy_vert_distance = 50 

@export_category("Enemy Movement Settings")

## How far the enemies move each time they move left or right
@export 
var enemy_hori_movement_distance = 10 

## How far the enemies move each time they go down
@export 
var enemy_vert_movement_distance = 50 

## How close to side of screen enemies should get before turning around
@export 
var lateral_bound = 20 

## How far down enemies need to get to make the player lose a life 
@export 
var bottom = 900 

## Time between rows of enemies moving
@export
var enemy_row_movement_timer = 0.2

## Delay between moving down and moving laterally again
@export
var enemy_move_downward_delay = 0.2

## Change in the enemies movement timer per enemy killed, moving to a percentage
## value set by final_enemy_movement_speed_percentage
@onready 
var enemy_row_movement_timer_interval \
		= float(enemy_row_movement_timer) * (1 - final_enemy_movement_speed_percentage) \
		/ (float(enemy_row_count) * float(enemy_col_count)) 
		

## Difficulty settings

## Target final value for enemy speed (as a percentage of base value)
@export var final_enemy_movement_speed_percentage = 0.000001

## Cooldown between shots
@export var enemy_shooting_cooldown = 3 

# Private variables
@onready var _remaining_enemies = enemy_row_count * enemy_col_count
@onready var _screen_size = get_viewport_rect().size

#keeps track if the enemies changed their direction in the last move cycle
#so that the signal to change direction again (as the enemies 
#var _direction_change_last_move = false

# Direction enemies are currently going
var _enemy_hori_movement_direction = 1

# Time since last enemy shot
var _last_enemy_shot = 0

# Passed through reference to player
var _Player

# Enemy grid
var _enemies = []


func init(player):
	_Player = player
	
	_spawn_enemies()
	_move_enemies()


func _ready():
	enemy_shooting_cooldown *= 1000


func _process(_delta):
	if(Time.get_ticks_msec() - _last_enemy_shot > enemy_shooting_cooldown):
		_shoot_enemies()
		_last_enemy_shot = Time.get_ticks_msec()


func _spawn_enemies():	
	var y_tally = enemy_start.y
	var x_tally = enemy_start.x
	_enemy_hori_movement_direction = 1 # Enemies should always start moving to the left
	
	for i in range(enemy_row_count): # Rows
		_enemies.append([])
		_enemies[i].resize(enemy_col_count) # Set size of 2nd array dimension
		
		for j in range(enemy_col_count): # Columns
			_enemies[i][j] = enemy_scene.instantiate()
			
			_enemies[i][j].position = Vector2(x_tally, y_tally)
			
			_enemies[i][j].enemy_destroyed.connect(on_enemy_destroyed)
			
			#add_child(_enemies[i][j])
			call_deferred("add_child", _enemies[i][j])
			
			x_tally += enemy_hori_distance
		
		x_tally = enemy_start.x
		y_tally += enemy_vert_distance
	
	return


func _move_enemies()-> void :
	var move_vector = enemy_hori_movement_distance * _enemy_hori_movement_direction
	var enemy_reached_bound = false
	
	# Timers seem to have a minimum wait time that is preventing the last
	# few blocks from moving as fast as I'd like, so this variable is used
	# to skip the timer for empty columns to somewhat alleviate this
	var _enemy_moved_in_column = false
	
	
	for i in range(enemy_row_count - 1, -1, -1): # Rows. Works backwards because the bottom rows should move first
		
		for j in range(enemy_col_count): # Columns
			
			# Will pass over dead enemies
			if(_enemies[i][j] == null):
				continue
			
			_enemy_moved_in_column = true
			
			_enemies[i][j].position.x += move_vector
			
			# Once one enemy reaches the end, they wait for the current
			# movement cycle to end, and then shift down and start moving 
			# the other direction
			if((_enemies[i][j].position.x <= lateral_bound \
					or _enemies[i][j].position.x \
					>= _screen_size.x - lateral_bound)):
				enemy_reached_bound = true
			
		if not _enemy_moved_in_column:
			continue
		else:
			_enemy_moved_in_column = false
		
		# Pause between rows to recreate the staggered effect of enemy movement
		await get_tree().create_timer(enemy_row_movement_timer).timeout 
		
	# Make sure the direction switch is completed before moving laterally 
	# again. Had issues with race conditions
	if(enemy_reached_bound == true):
		await _enemies_change_direction() 
		
	enemy_reached_bound = false
	
	# Recursive movement, that way the only thing keeping time is the 
	# await timers in between row shifts
	_move_enemies()


func _enemies_change_direction():
	# Shift enemies down
	for i in range(enemy_row_count): # Rows
		
		for j in range(enemy_col_count): # Columns
			if(_enemies[i][j] == null):
				continue
			
			_enemies[i][j].position.y += enemy_vert_movement_distance
			
			if _enemies[i][j].position.y >= bottom:
				enemy_reached_bottom.emit()
				return
			
	# Reverse enemy horizontal direction
	_enemy_hori_movement_direction = -_enemy_hori_movement_direction
	
	#_direction_change_last_move = true
	
	await get_tree().create_timer(enemy_move_downward_delay).timeout
	
	return


func _shoot_enemies():
	# Game randomly chooses between shooting wide and having the closest enemy shoot at player
	
	# If shooting at player, go through each column and see which has an alive enemy closest to the player (column priority)
	# Then instaniate rocket right below alien
	
	# If shooting randomly, generate a random number, and then iterate through the columns, ticking
	# off the count with each one (if a column has zero aliens, it doesn't count)
	# Once the counter is chosen, find the lowest alien and shoot.
	
	if(randf() < 0.2 and _Player != null):
		_shoot_at_player()
	else:
		_shoot_randomly()


# Finds the closest enemy to shoot
func _shoot_at_player():
	var player_x = _Player.position.x
	var x_difference = 2000 # Minimum difference in x value's between player and any enemy
	var closest_column = 0
	
	# Find column with existing enemies closest to player
	for j in range(enemy_col_count): # Columns
		
		for i in range(enemy_row_count): # Rows
			if(_enemies[i][j] == null):
				continue
			else:
				if(abs(_enemies[i][j].position.x - player_x) < x_difference):
					x_difference = abs(_enemies[i][j].position.x - player_x)
					closest_column = j
					break
	
	# Find lowest enemy
	for i in range(enemy_row_count -1, -1, -1): # Start from the bottom
		if(_enemies[i][closest_column] != null):
			_shoot_projectile(_enemies[i][closest_column])
			return


# Chooses a random enemy to shoot
func _shoot_randomly():
	var random_counter = randi_range(1, enemy_row_count)
	var chosen_column = 0
	
	# Choose random column
	for j in range(enemy_col_count): # Columns
		
		for i in range(enemy_row_count): # Rows
			if(_enemies[i][j] == null):
				continue
			elif(random_counter <= 0): # If counter is finished and this column has an enemy, choose it
				chosen_column = j
			else: # If column has an enemy, decrement the counter and move on
				random_counter -= 1
				break
	
	# Find lowest enemy
	for i in range(enemy_row_count -1, -1, -1): # Start from the bottom
		if(_enemies[i][chosen_column] != null):
			_shoot_projectile(_enemies[i][chosen_column])
			return


# Once the enemy to shoot is chosen, actually do the firing
func _shoot_projectile(enemy):
	var rocket = projectile_scene.instantiate()
	rocket.position = Vector2(enemy.position.x, enemy.position.y + 130) # Spawn beneath enemy
	rocket.set_direction(-1)
	add_child(rocket)
	
# Called when an enemy dies, telling main to decrease count of remaining enemies, increase score, and speed up enemies
func on_enemy_destroyed():
	_remaining_enemies -= 1
	
	enemy_row_movement_timer = enemy_row_movement_timer - enemy_row_movement_timer_interval
	
	enemy_destroyed.emit()
	
	if(_remaining_enemies <= 0):
		all_enemies_destroyed.emit()
	
