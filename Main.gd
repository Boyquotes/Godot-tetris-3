extends Node2D

@onready var block = preload("res://Block.tscn")

var cell_size = 64
var bottom_border = 1280
var left_border = 0
var right_border = 576
var matrix_center = 256
var speed_factor = 0.97

# I, O, J, L, T, S, Z
var tetromino_coords = [	[Vector2(-64, 0),Vector2(0, 0),Vector2(64, 0),Vector2(128, 0)],
							[Vector2(0, -64),Vector2(64, -64),Vector2(64, 0),Vector2(0, 0)],
							[Vector2(-64, -64),Vector2(-64, 0),Vector2(0, 0),Vector2(64, 0)],
							[Vector2(-64, 0),Vector2(0, 0),Vector2(64, 0),Vector2(64, -64)],
							[Vector2(-64, 0),Vector2(0, 0),Vector2(0, -64),Vector2(64, 0)],
							[Vector2(-64, 0),Vector2(0, 0),Vector2(0, -64),Vector2(64, -64)],
							[Vector2(-64, -64),Vector2(0, -64),Vector2(0, 0),Vector2(64, 0)]]

var matrix_coords = Vector2(matrix_center, cell_size)
var blocks_relative_coords = []

var next_tetromino = randi_range(0, len(tetromino_coords) - 1)

var blocks = [0, 0, 0, 0]
var fallen_blocks = []
var fallen_blocks_coords = []

var points = 0

func restart_game():
	if blocks != [0, 0, 0, 0]:
		for i in blocks:
			i.queue_free()
	for i in fallen_blocks:
		i.queue_free()
	fallen_blocks = []
	fallen_blocks_coords = []
	next_tetromino = new_tetromino()
	points = 0
	$Panel/Points_lable.text = str(points)
	$Timer.wait_time = 1;
	$Timer.start()
	$Panel/Speed_lable.text = str($Timer.wait_time)
	new_move()
	$Panel/Game_over_lable.visible = false
	$Panel/Start_button.text = "Restart"

func check_game_over():
	for i in fallen_blocks:
		if i.position.y == cell_size:
			$Panel/Game_over_lable.visible = true
			$Timer.stop()

func new_move():
	blocks = [0, 0, 0 ,0]
	matrix_coords = Vector2(matrix_center, cell_size)

func _on_timer_timeout():			
	if blocks == [0, 0, 0, 0]:		
		blocks_relative_coords = tetromino_coords[new_tetromino()].duplicate()
		for i in 4:
			blocks[i] = block.instantiate()
			$Panel/Field.add_child(blocks[i])
		update_coords()
	else:
		move_down()

func new_tetromino():
	while true:
		var new_tetromino = randi_range(0, len(tetromino_coords) - 1)
		if new_tetromino != next_tetromino:
			var present_tetromino = next_tetromino
			next_tetromino = new_tetromino
			$Panel/Next_tetromino_texture.texture = load("res://assets/Tetromino%d.png" % next_tetromino)
			return present_tetromino

func update_coords():
	for i in 4:
		blocks[i].position = matrix_coords + blocks_relative_coords[i]

func add_points(number_full_lines):
	var new_points = 0
	for i in number_full_lines:
		new_points = new_points * 2 + 100
	points += new_points
	$Panel/Points_lable.text = str(points)

func change_speed(number_full_lines):
	$Timer.wait_time = $Timer.wait_time * (speed_factor ** number_full_lines)
	$Panel/Speed_lable.text = str($Timer.wait_time)

func check_lines():
	var new_dropped_blocks_coords_y = []
	var full_lines_indexes = []
	var full_lines_coords_y = []
	for i in blocks:
		if (i.position.y in new_dropped_blocks_coords_y) == false:
			new_dropped_blocks_coords_y.append(i.position.y)			
	for i in new_dropped_blocks_coords_y:
		var line_indexes =[]
		for e in 10:
			if fallen_blocks_coords.find(Vector2(e * 64, i)) != -1:
				line_indexes.append(fallen_blocks_coords.find(Vector2(e * 64, i)))
		if len(line_indexes) == 10:
			full_lines_indexes.append_array(line_indexes)
			full_lines_coords_y.append(i)
	remove_lines(full_lines_indexes)
	move_fallen_blocks_down(full_lines_coords_y)
	var number_full_lines = len(full_lines_coords_y)
	add_points(number_full_lines)
	change_speed(number_full_lines)

func remove_lines(full_lines_indexes):
	if full_lines_indexes != []:
		full_lines_indexes.sort()
		full_lines_indexes.reverse()
		for i in full_lines_indexes:
			fallen_blocks[i].queue_free()
			fallen_blocks.remove_at(i)
			fallen_blocks_coords.remove_at(i)

func move_fallen_blocks_down(full_lines_coords_y):
		full_lines_coords_y.sort()
		for i in full_lines_coords_y:
			for e in len(fallen_blocks):
				if fallen_blocks[e].position.y <= i:
					fallen_blocks[e].position.y += cell_size
					fallen_blocks_coords[e].y += cell_size

func check_move_down():
	for i in 4:		
		var next_coord = blocks[i].position
		next_coord.y += cell_size
		if next_coord.y >= bottom_border or next_coord in fallen_blocks_coords:
			return false		
	return true

func move_down():
		if check_move_down():
			matrix_coords.y += cell_size
			update_coords()
		else:
			for i in 4:
				fallen_blocks.append(blocks[i])
				fallen_blocks_coords.append(blocks[i].position)
			check_lines()
			new_move()
			check_game_over()

func check_turn():
	for i in 4:
		var next_coord = Vector2(-1 * blocks_relative_coords[i].y, blocks_relative_coords[i].x)
		next_coord += matrix_coords
		if next_coord.y > bottom_border or next_coord.x < left_border or next_coord.x > right_border or next_coord in fallen_blocks_coords:
			return false
	return true

func turn ():
	if check_turn():
		var x = 0
		for i in 4:
			x = blocks_relative_coords[i].x
			blocks_relative_coords[i].x = -1 * blocks_relative_coords[i].y
			blocks_relative_coords[i].y = x
		update_coords()

func check_move_right():
	for i in 4:
		var next_coord = blocks[i].position
		next_coord.x += cell_size
		if next_coord.x > right_border or next_coord in fallen_blocks_coords:
			return false
	return true

func move_right():
	if check_move_right():
		matrix_coords.x += cell_size
		update_coords()

func check_move_left():
	for i in 4:
		var next_coord = blocks[i].position
		next_coord.x -= cell_size
		if next_coord.x < left_border or next_coord in fallen_blocks_coords:
			return false
	return true

func move_left():
	if check_move_left():
		matrix_coords.x -= cell_size
		update_coords()

func _input(event):
	if  blocks != [0, 0, 0, 0]:
		if Input.is_action_just_pressed("right"):
			move_right()
		if Input.is_action_just_pressed("left"):
			move_left()
		if Input.is_action_just_pressed("down"):
			move_down()
		if Input.is_action_just_pressed("turn"):
			turn()

func _on_button_pressed():
	restart_game()
