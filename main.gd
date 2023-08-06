extends Node2D

signal direction_switched

@export var enemy_scene: PackedScene

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

@export var enemy_movement_speed = 1

# Enemy grid
var enemies = []

var remaining_enemies = 0
var enemy_hori_movement_direction = 1 # Should be 1 or -1
var last_enemy_movement = 0
var enemy_row_movement_timer
var direction_change_last_move = false

# Called when the node enters the scene tree for the first time.
func _ready():
	_spawn_enemies()
	enemy_row_movement_timer = float(enemy_movement_speed) / float(enemy_col_count) # All rows should move before the cycle restarts
	_move_enemies()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

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

# Called when an enemy dies, telling main to decrease count of remaining enemies
func change_enemy_count():
	remaining_enemies -= 1
