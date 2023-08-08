extends Node2D

signal direction_switched

@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene

var rocket_sprite = load("res://icon.svg")

# Enemy grid settings
@export var enemy_row_count = 4 # Number of enemies per row
@export var enemy_col_count = 4 # Number of enemies per column
@export var enemy_pos_x = 20 # Starting x position for enemy grid
@export var enemy_pos_y = 20 # Starting y position for enemy grid
@export var enemy_hori_distance = 10 # Horizontal space between enemies
@export var enemy_vert_distance = 10 # Vertical space betweene enemies

@export var enemy_hori_movement_distance = 10 # How far the enemies move each time they move left or right
@export var enemy_vert_movement_distance = 50 # How far the enemies move each time they go down
@export var left_bound = 20
@export var right_bound = 940

# Enemy settings
@export var enemy_movement_speed = 1
@export var enemy_shooting_cooldown = 3

# Enemy grid
var enemies = []

var remaining_enemies = 0
var enemy_hori_movement_direction = 1 # Should be 1 or -1
var enemy_row_movement_timer
var direction_change_last_move = false
var last_enemy_shot = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_spawn_enemies()
	enemy_row_movement_timer = float(enemy_movement_speed) / float(enemy_col_count) # All rows should move before the cycle restarts
	enemy_shooting_cooldown *= 1000
	_move_enemies()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(Time.get_ticks_msec() - last_enemy_shot > enemy_shooting_cooldown):
		_shoot_enemies()
		last_enemy_shot = Time.get_ticks_msec()

func _spawn_enemies():	
	var y_tally = enemy_pos_y
	var x_tally = enemy_pos_x
	
	for i in range(enemy_col_count): # Rows
		enemies.append([])
		enemies[i].resize(enemy_row_count)
		
		for j in range(enemy_row_count): # Columns
			enemies[i][j] = enemy_scene.instantiate()
			
			enemies[i][j].position = Vector2(x_tally, y_tally)
			
			enemies[i][j].enemy_destroyed.connect(change_enemy_count)
			
			add_child(enemies[i][j])
			
			x_tally += enemy_hori_distance
		
		x_tally = enemy_pos_x
		y_tally += enemy_vert_distance
		
	remaining_enemies = enemy_row_count * enemy_col_count

func _move_enemies():
	
	var move_vector = enemy_hori_movement_distance * enemy_hori_movement_direction
	var enemy_reached_bound = false
	
	for i in range(enemy_col_count - 1, -1, -1): # Rows. Works backwards because the bottom rows should move first
		
		for j in range(enemy_row_count): # Columns
			if(enemies[i][j] == null):
				continue
			
			enemies[i][j].position.x += move_vector
			
			# Once one enemy reaches the end, they wait for the current movement cycle to end, and then shift down and start moving the other direction
			if(enemies[i][j].position.x <= left_bound or enemies[i][j].position.x >= right_bound and direction_change_last_move == false):
				enemy_reached_bound = true
			
		await get_tree().create_timer(enemy_row_movement_timer).timeout # Pause between rows to recreate the staggered effect of enemy movement
	
	direction_change_last_move = false
	
	if(enemy_reached_bound == true):
		print("changing direction")
		await _enemies_change_direction() # Make sure the direction switch is completed before moving laterally again. Had issues with race conditions
		
	enemy_reached_bound = false
	
	# Recursive movement, that way the only thing keeping time is the await timers in between row shifts
	_move_enemies()

func _enemies_change_direction():
	# Shift enemies down
	for i in range(enemy_col_count): # Rows
		
		for j in range(enemy_row_count): # Columns
			if(enemies[i][j] == null):
				continue
			
			enemies[i][j].position.y += enemy_vert_movement_distance
			
	# Reverse enemy horizontal direction
	enemy_hori_movement_direction = -enemy_hori_movement_direction
	
	direction_change_last_move = true
	
	direction_switched.emit()
	
	return

func _shoot_enemies():
	# Game randomly chooses between shooting wide and having the closest enemy shoot at player
	
	# If shooting at player, go through each column and see which has an alive enemy closest to the player (column priority)
	# Then instaniate rocket right below alien
	
	# If shooting randomly, generate a random number, and then iterate through the columns, ticking
	# off the count with each one (if a column has zero aliens, it doesn't count)
	# Once the counter is chosen, find the lowest alien and shoot.
	
	if(randf() > 0.8):
		_shoot_randomly()
	else:
		_shoot_at_player()

# Finds the closest enemy to shoot
func _shoot_at_player():
	var player_x = $Player.position.x
	var x_difference = 2000 # Minimum difference in x value's between player and any enemy
	var closest_column = 0
	
	# Find column with existing enemies closest to player
	for j in range(enemy_row_count): # Columns
		
		for i in range(enemy_col_count): # Rows
			if(enemies[i][j] == null):
				continue
			else:
				if(abs(enemies[i][j].position.x - player_x) < x_difference):
					x_difference = abs(enemies[i][j].position.x - player_x)
					closest_column = j
					break
	
	# Find lowest enemy
	for i in range(enemy_col_count -1, -1, -1): # Start from the bottom
		if(enemies[i][closest_column] != null):
			_shoot_projectile(enemies[i][closest_column])
			return
	
# Chooses a random enemy to shoot
func _shoot_randomly():
	var random_counter = randi_range(1, enemy_row_count)
	var chosen_column = 0
	
	# Choose random column
	for j in range(enemy_row_count): # Columns
		
		for i in range(enemy_col_count): # Rows
			if(enemies[i][j] == null):
				continue
			elif(random_counter <= 0): # If counter is finished and this column has an enemy, choose it
				chosen_column = j
			else: # If column has an enemy, decrement the counter and move on
				random_counter -= 1
				break
				
	# Find lowest enemy
	for i in range(enemy_col_count -1, -1, -1): # Start from the bottom
		if(enemies[i][chosen_column] != null):
			_shoot_projectile(enemies[i][chosen_column])
			return
	
# Once the enemy to shoot is chosen, actually do the firing
func _shoot_projectile(enemy):
	var rocket = projectile_scene.instantiate()
	rocket.get_child(0).texture = rocket_sprite # Choose enemy rocket texture
	rocket.position = Vector2(enemy.position.x, enemy.position.y + 130) # Spawn beneath enemy
	rocket.set_direction(-1)
	add_child(rocket)
	
# Called when an enemy dies, telling main to decrease count of remaining enemies
func change_enemy_count():
	remaining_enemies -= 1
