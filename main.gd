extends Node2D

@export var enemy_scene: PackedScene

# Enemy grid settings
@export var enemy_row_count = 4 # Number of enemies per row
@export var enemy_col_count = 4 # Number of enemies per column
@export var enemy_pos_x = 20 # Starting x position for enemy grid
@export var enemy_pos_y = 20 # Starting y position for enemy grid
@export var enemy_hori_distance = 10 # Horizontal space between enemies
@export var enemy_vert_distance = 10 # Vertical space betweene enemies

# Enemy grid
var enemies = []

var remaining_enemies = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_spawn_enemies()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _spawn_enemies():	
	var y_tally = enemy_pos_y
	var x_tally = enemy_pos_x
	
	for i in range(enemy_col_count): # Rows
		enemies.append([])
		enemies[i].resize(enemy_row_count)
		
		for j in range(enemy_row_count):
			enemies[i][j] = enemy_scene.instantiate()
			
			enemies[i][j].position = Vector2(x_tally, y_tally)
			
			enemies[i][j].enemy_destroyed.connect(change_enemy_count)
			
			add_child(enemies[i][j])
			
			x_tally += enemy_hori_distance
		
		x_tally = enemy_pos_x
		y_tally += enemy_vert_distance
		
	remaining_enemies = enemy_row_count * enemy_col_count

# Called when an enemy dies, telling main to decrease count of remaining enemies
func change_enemy_count():
	remaining_enemies -= 1
