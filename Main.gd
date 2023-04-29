extends Node2D

@onready var block = preload("res://Block.tscn")
@onready var blueBlock = preload("res://BlueBlock.tscn")
@onready var lightBlueBlock = preload("res://LightBlueBlock.tscn")
@onready var greenBlock = preload("res://GreenBlock.tscn")
@onready var orangeBlock = preload("res://OrangeBlock.tscn")
@onready var redBlock = preload("res://RedBlock.tscn")
@onready var yellowBlock = preload("res://YellowBlock.tscn")
@onready var purpleBlock = preload("res://PurpleBlock.tscn")


const game_field_width = 10
const game_field_height = 20

const cell_size = 64

const left_border = -cell_size * game_field_width / 2
const right_border = cell_size * (game_field_width / 2 - 1)
const bottom_border = cell_size * (game_field_height / 2 - 1)
const matrix_center = Vector2(-cell_size, -cell_size * (game_field_height / 2))

@onready var tetromino_I = [lightBlueBlock, Vector2(-cell_size, 0), Vector2(0, 0), Vector2(cell_size, 0), Vector2(cell_size * 2, 0)]
@onready var tetromino_O = [yellowBlock, Vector2(0, 0), Vector2(cell_size, 0), Vector2(cell_size, cell_size), Vector2(0, cell_size)]
@onready var tetromino_T = [purpleBlock, Vector2(-cell_size, 0), Vector2(0, 0), Vector2(0, cell_size), Vector2(cell_size, 0)]
@onready var tetromino_L = [orangeBlock, Vector2(-cell_size, cell_size), Vector2(-cell_size, 0), Vector2(0, 0), Vector2(cell_size, 0)]
@onready var tetromino_J = [blueBlock, Vector2(-cell_size, 0), Vector2(0, 0), Vector2(cell_size, 0), Vector2(cell_size, cell_size)]
@onready var tetromino_S = [greenBlock, Vector2(-cell_size, cell_size), Vector2(0, cell_size), Vector2(0, 0), Vector2(cell_size, 0)]
@onready var tetromino_Z = [redBlock, Vector2(-cell_size, 0), Vector2(0, 0), Vector2(0, cell_size), Vector2(cell_size, cell_size)]
@onready var tetromino_coords = [tetromino_I, tetromino_O, tetromino_T, tetromino_L, tetromino_J, tetromino_S, tetromino_Z]

const speed_multiplier = 0.95
const max_speed = 0.01
const pressed_timer_speed = 0.01
const max_pressed_ticks = 30

var left_button_pressed
var left_button_pressed_ticks
var down_button_pressed
var down_button_pressed_ticks
var right_button_pressed
var right_button_pressed_ticks

var speed
var no_pause

var points

var matrix_coords
var blocks
var blocks_relative_coords
var fallen_blocks
var fallen_blocks_coords

var next_tetromino

func _on_ready():
	speed = 1
	no_pause = false

	$GameTimer.wait_time = speed
	$PressedTimer.wait_time = pressed_timer_speed

	points = 0

	matrix_coords = matrix_center
	blocks = []
	blocks_relative_coords = []
	fallen_blocks = []
	fallen_blocks_coords = []

	next_tetromino = randi_range(0, len(tetromino_coords) - 1)

	left_button_pressed = false
	left_button_pressed_ticks = 0
	down_button_pressed = false
	down_button_pressed_ticks = 0
	right_button_pressed = false
	right_button_pressed_ticks = 0

	change_interface_size()
	
	$PointsLable.text = "Points: " + str(points)
	$SpeedLable.text = "Speed: " + str(snapped(1 / speed, 0.001))

	$PauseButton.visible = false
	$GameOverPanel.visible = false

func change_interface_size():
	const intrface_width = 16
	const intrface_height = 26
	const button_size = 2
	
	var window_size = get_viewport().size
	var window_center = Vector2(window_size.x / 2, window_size.y / 2)
	var interface_scale = float(min(window_size.x / intrface_width, window_size.y / intrface_height)) / cell_size

	$GameField.position = window_center
	$GameField.scale /= $GameField.scale 
	$GameField.scale *= interface_scale

	$SpeedLable.position = Vector2(window_center.x - cell_size * interface_scale * 5, window_center.y - cell_size * interface_scale * 11.5)
	$SpeedLable.size = Vector2(cell_size * interface_scale * button_size, cell_size * interface_scale * button_size / 2)

	$PointsLable.position = Vector2(window_center.x + cell_size * interface_scale * 2, window_center.y - cell_size * interface_scale * 11.5)
	$PointsLable.size = Vector2(cell_size * interface_scale * button_size, cell_size * interface_scale * button_size / 2)

	$NextTetrominoPicture.position = Vector2(window_center.x - cell_size * interface_scale * button_size / 2, window_center.y - cell_size * interface_scale * (intrface_height - 1) / 2)
	$NextTetrominoPicture.size = Vector2(cell_size * interface_scale * button_size, cell_size * interface_scale * button_size)

	$StartButton.position = Vector2(window_center.x - cell_size * interface_scale * (intrface_width - 1) / 2, window_center.y - cell_size * interface_scale * (intrface_height - 1) / 2)
	$StartButton.size = Vector2(cell_size * interface_scale * button_size, cell_size * interface_scale * button_size)

	$PauseButton.position = Vector2(window_center.x - cell_size * interface_scale * (intrface_width - 1) / 2, window_center.y - cell_size * interface_scale * ((intrface_height - 1) / 2 - button_size))
	$PauseButton.size = Vector2(cell_size * interface_scale * button_size, cell_size * interface_scale * button_size)

	$LeftButton.position = Vector2(window_center.x - cell_size * interface_scale * 7, window_center.y + cell_size * interface_scale * 10.5)
	$LeftButton.size = Vector2(cell_size * interface_scale * button_size, cell_size * interface_scale * button_size)

	$TurnButton.position = Vector2(window_center.x - cell_size * interface_scale * 3, window_center.y + cell_size * interface_scale * 10.5)
	$TurnButton.size = Vector2(cell_size * interface_scale * button_size, cell_size * interface_scale * button_size)

	$DownButton.position = Vector2(window_center.x + cell_size * interface_scale, window_center.y + cell_size * interface_scale * 10.5)
	$DownButton.size = Vector2(cell_size * interface_scale * button_size, cell_size * interface_scale * button_size)

	$RightButton.position = Vector2(window_center.x + cell_size * interface_scale * 5, window_center.y + cell_size * interface_scale * 10.5)
	$RightButton.size = Vector2(cell_size * interface_scale * button_size, cell_size * interface_scale * button_size)

	$GameOverPanel.position = Vector2(window_center.x - cell_size * interface_scale * 2, window_center.y - cell_size * interface_scale * 2)
	$GameOverPanel.size = Vector2(cell_size * interface_scale * 4, cell_size * interface_scale * 4)

	$GameOverPanel/GameOverLable.position = Vector2(0, 0)
	$GameOverPanel/GameOverLable.size = Vector2(cell_size * interface_scale * 4, cell_size * interface_scale * 4)

func _on_game_timer_timeout():
	if blocks == []:
		left_button_pressed_ticks = 0
		down_button_pressed_ticks = 0
		right_button_pressed_ticks = 0

		var block_descr = tetromino_coords[new_tetromino()]
		blocks_relative_coords = block_descr.slice(-4).duplicate()

		var b = block_descr[0];
		blocks = [b.instantiate(), b.instantiate(), b.instantiate(), b.instantiate()]
		for i in len(blocks_relative_coords):
			$GameField.add_child(blocks[i])

		update_coords()

	elif down_button_pressed_ticks < max_pressed_ticks:
		move_down()

func _on_pressed_timer_timeout():
	if down_button_pressed:
		if down_button_pressed_ticks >= max_pressed_ticks:
			move_down()
		else:
			down_button_pressed_ticks += 1

	if left_button_pressed:
		if left_button_pressed_ticks >= max_pressed_ticks:
			move_left()
		else:
			left_button_pressed_ticks += 1

	if right_button_pressed:
		if right_button_pressed_ticks >= max_pressed_ticks:
			move_right()
		else:
			right_button_pressed_ticks += 1

func restart():
	if blocks != []:
		for block in blocks:
			block.queue_free()

	for fallen_block in fallen_blocks:
		fallen_block.queue_free()

	_on_ready()

	$PauseButton.visible = true

	$StartButton.text = "Restart"

	no_pause = true
	$GameTimer.start()
	$PressedTimer.start()

func pause():
	if $GameTimer.is_stopped():
		no_pause = true
		$GameTimer.start()
		$PressedTimer.start()
		$PauseButton.text = "Pause"

	else:
		no_pause = false
		$GameTimer.stop()
		$PressedTimer.stop()
		$PauseButton.text = "Start"

func new_tetromino():
	var new_tetromino
	var present_tetromino
	
	while true:
		new_tetromino = randi_range(0, len(tetromino_coords) - 1)

		if new_tetromino != next_tetromino:
			present_tetromino = next_tetromino
			next_tetromino = new_tetromino

			$NextTetrominoPicture.texture = load("res://assets/Tetromino%d.png" % next_tetromino)

			return present_tetromino

func add_points(number_filled_lines):
	var extra_points = 0

	for i in number_filled_lines:
		extra_points = extra_points * 2 + 100

	points += extra_points

	$PointsLable.text = "Points: " + str(points)

func change_speed(number_filled_lines):
	speed *= speed_multiplier ** number_filled_lines

	if speed < max_speed:
		speed = max_speed

	$GameTimer.wait_time = speed
	$SpeedLable.text = "Speed: " + str(snapped(1 / speed, 0.001))

func update_coords():
	for i in len(blocks):
		blocks[i].position = matrix_coords + blocks_relative_coords[i]

func check_game_over():
	for fallen_block in fallen_blocks:
		if fallen_block.position.y == -1 * cell_size * (game_field_height / 2 - 1):
			$PauseButton.visible = false
			$GameOverPanel.visible = true

			no_pause = false
			$GameTimer.stop()
			$PressedTimer.stop()

func check_filled_lines():
	var last_blocks_coords_y = []
	var tested_line_indexes
	var block_index_in_tested_line
	var filled_lines_indexes = []
	var filled_lines_coords_y = []
	var number_filled_lines

	for block in blocks:
		if (block.position.y in last_blocks_coords_y) == false:
			last_blocks_coords_y.append(block.position.y)

	for block_coord_y in last_blocks_coords_y:
		tested_line_indexes = []

		for cell in game_field_width:
			block_index_in_tested_line = fallen_blocks_coords.find(Vector2(left_border + cell * cell_size, block_coord_y))
			if block_index_in_tested_line != -1:
				tested_line_indexes.append(block_index_in_tested_line)

		if len(tested_line_indexes) == game_field_width:
			filled_lines_indexes.append_array(tested_line_indexes)
			filled_lines_coords_y.append(block_coord_y)

	number_filled_lines = len(filled_lines_coords_y)

	if number_filled_lines != 0:
		remove_filled_lines(filled_lines_indexes)
		move_fallen_blocks_down(filled_lines_coords_y)

		add_points(number_filled_lines)
		change_speed(number_filled_lines)

func remove_filled_lines(filled_lines_indexes):
	filled_lines_indexes.sort()
	filled_lines_indexes.reverse()

	for block_index in filled_lines_indexes:
		fallen_blocks[block_index].queue_free()
		fallen_blocks.remove_at(block_index)
		fallen_blocks_coords.remove_at(block_index)

func move_fallen_blocks_down(filled_lines_coords_y):
	filled_lines_coords_y.sort()

	for full_line_coord_y in filled_lines_coords_y:
		for i in len(fallen_blocks):
			if fallen_blocks[i].position.y <= full_line_coord_y:
				fallen_blocks[i].position.y += cell_size
				fallen_blocks_coords[i].y += cell_size

func move_left():
	if blocks != [] and no_pause:
		if check_move_left():
			matrix_coords.x -= cell_size

			update_coords()

func check_move_left():
	var next_coords

	for block in blocks:
		next_coords = block.position
		next_coords.x -= cell_size

		if next_coords.x < left_border or next_coords in fallen_blocks_coords:
			return false

	return true

func turn ():
	if blocks != [] and no_pause:
		var next_coords

		if check_turn():
			for i in len(blocks_relative_coords):
				next_coords = blocks_relative_coords[i].x
				blocks_relative_coords[i].x = -1 * blocks_relative_coords[i].y
				blocks_relative_coords[i].y = next_coords

		update_coords()

func check_turn():
	var next_coords

	for block_relative_coord in blocks_relative_coords:
		next_coords = matrix_coords + Vector2(block_relative_coord.y * -1, block_relative_coord.x)

		if next_coords.x < left_border or next_coords.x > right_border or next_coords.y > bottom_border or next_coords in fallen_blocks_coords:
			return false

	return true

func move_down():
	if blocks != [] and no_pause:
		if check_move_down():
			matrix_coords.y += cell_size

			update_coords()

		else:
			fallen_blocks.append_array(blocks)
			for block in blocks:
				fallen_blocks_coords.append(block.position)

			check_filled_lines()
			check_game_over()

			matrix_coords = matrix_center
			blocks = []

func check_move_down():
	var next_coords

	for block in blocks:
		next_coords = block.position
		next_coords.y += cell_size

		if next_coords.y > bottom_border or next_coords in fallen_blocks_coords:
			return false	

	return true

func move_right():
	if blocks != [] and no_pause:
		if check_move_right():
			matrix_coords.x += cell_size

			update_coords()

func check_move_right():
	var next_coords

	for block in blocks:
		next_coords = block.position
		next_coords.x += cell_size
		
		if next_coords.x > right_border or next_coords in fallen_blocks_coords:
			return false

	return true

func _on_start_button_pressed():
	restart()

func _on_pause_button_pressed():
	pause()

func _on_turn_button_pressed():
	if blocks != [] and no_pause:
		turn()

func _on_left_button_button_down():
	if blocks != [] and no_pause:
		move_left()

	left_button_pressed = true

func _on_left_button_button_up():
	left_button_pressed = false
	left_button_pressed_ticks = 0

func _on_down_button_button_down():
	if blocks != [] and no_pause:
		move_down()

	down_button_pressed = true

func _on_down_button_button_up():
	down_button_pressed = false
	down_button_pressed_ticks = 0

func _on_right_button_button_down():
	if blocks != [] and no_pause:
		move_right()

	right_button_pressed = true

func _on_right_button_button_up():
	right_button_pressed = false
	right_button_pressed_ticks = 0

func _input(event):
	if blocks != [] and no_pause:
		if Input.is_action_just_pressed("left"):
			move_left()

		if Input.is_action_just_pressed("turn"):
			turn()

		if Input.is_action_just_pressed("down"):
			move_down()

		if Input.is_action_just_pressed("right"):
			move_right()
