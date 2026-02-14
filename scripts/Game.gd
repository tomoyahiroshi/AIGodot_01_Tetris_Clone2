extends Node2D
class_name Game

signal score_changed(score: int)
signal level_changed(level: int)
signal lines_changed(lines: int)
signal next_updated(queue: Array)
signal hold_updated(piece_type: int)
signal game_over(final_score: int)

const BOARD_WIDTH := 10
const BOARD_HEIGHT := 20
const CELL_SIZE := 32
const BOARD_OFFSET := Vector2i(40, 40)

const EMPTY := -1
const BASE_FALL_INTERVAL := 0.8
const FALL_INTERVAL_DECAY := 0.07
const MIN_FALL_INTERVAL := 0.05
const LOCK_DELAY := 0.5
const MAX_LOCK_RESETS := 15
const SOFT_DROP_STEP := 0.03

const PIECE_TYPES := ["I", "O", "T", "S", "Z", "J", "L"]
const PIECE_COLORS := {
	"I": Color("#49dbe9"),
	"O": Color("#f2d13d"),
	"T": Color("#a75de3"),
	"S": Color("#61db6b"),
	"Z": Color("#e45858"),
	"J": Color("#4d72e2"),
	"L": Color("#e79847")
}

const SCORE_TABLE := {
	1: 100,
	2: 300,
	3: 500,
	4: 800
}

const PIECE_SHAPES := {
	"I": [
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
		[Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)],
		[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]
	],
	"O": [
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)]
	],
	"T": [
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
	],
	"S": [
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)],
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
	],
	"Z": [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]
	],
	"J": [
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]
	],
	"L": [
		[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
	]
}

const KICKS_JLSTZ := {
	"0_1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"1_0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"1_2": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"2_1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"2_3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	"3_2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	"3_0": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"0_3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)]
}

const KICKS_I := {
	"0_1": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(1, 2)],
	"1_0": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, 1), Vector2i(-1, -2)],
	"1_2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(2, -1)],
	"2_1": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, -2), Vector2i(-2, 1)],
	"2_3": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, 1), Vector2i(-1, -2)],
	"3_2": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(1, 2)],
	"3_0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, -2), Vector2i(-2, 1)],
	"0_3": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(2, -1)]
}

var board: Array = []
var bag: Array[String] = []
var next_queue: Array[String] = []

var current_piece := ""
var current_rotation := 0
var current_pos := Vector2i.ZERO
var hold_piece := ""
var hold_used := false

var score := 0
var level := 1
var lines_cleared := 0
var high_score := 0

var is_paused := false
var is_game_over := false

var gravity_timer := 0.0
var soft_drop_timer := 0.0
var lock_timer := 0.0
var is_locking := false
var lock_reset_count := 0

func _ready() -> void:
	set_process(true)
	load_high_score()
	reset_game()

func _process(delta: float) -> void:
	if is_game_over:
		if Input.is_action_just_pressed("retry"):
			reset_game()
		return

	if Input.is_action_just_pressed("pause"):
		is_paused = !is_paused
		queue_redraw()
		return

	if is_paused:
		return

	handle_input(delta)

	gravity_timer += delta
	var interval := get_fall_interval()
	if gravity_timer >= interval:
		gravity_timer = 0.0
		step_fall(false)

	if is_locking:
		lock_timer += delta
		if lock_timer >= LOCK_DELAY or lock_reset_count >= MAX_LOCK_RESETS:
			lock_piece()

func handle_input(delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):
		try_move(Vector2i.LEFT)
	if Input.is_action_just_pressed("move_right"):
		try_move(Vector2i.RIGHT)
	if Input.is_action_just_pressed("rotate_cw"):
		try_rotate(1)
	if Input.is_action_just_pressed("rotate_ccw"):
		try_rotate(-1)
	if Input.is_action_just_pressed("hold"):
		hold_current_piece()
	if Input.is_action_just_pressed("hard_drop"):
		hard_drop()
		return

	if Input.is_action_pressed("soft_drop"):
		soft_drop_timer += delta
		if soft_drop_timer >= SOFT_DROP_STEP:
			soft_drop_timer = 0.0
			if step_fall(true):
				score += 1
				emit_signal("score_changed", score)
	else:
		soft_drop_timer = 0.0

func reset_game() -> void:
	board.clear()
	for y in BOARD_HEIGHT:
		var row: Array[int] = []
		row.resize(BOARD_WIDTH)
		row.fill(EMPTY)
		board.append(row)

	bag.clear()
	next_queue.clear()
	for _i in 5:
		next_queue.append(pull_from_bag())

	score = 0
	level = 1
	lines_cleared = 0
	hold_piece = ""
	hold_used = false
	is_paused = false
	is_game_over = false
	gravity_timer = 0.0
	soft_drop_timer = 0.0
	lock_timer = 0.0
	is_locking = false
	lock_reset_count = 0

	emit_signal("score_changed", score)
	emit_signal("level_changed", level)
	emit_signal("lines_changed", lines_cleared)
	emit_signal("hold_updated", -1)
	emit_signal("next_updated", next_queue.duplicate())
	spawn_piece()
	queue_redraw()

func get_fall_interval() -> float:
	return max(MIN_FALL_INTERVAL, BASE_FALL_INTERVAL - float(level - 1) * FALL_INTERVAL_DECAY)

func fill_bag_if_needed() -> void:
	if bag.is_empty():
		bag = PIECE_TYPES.duplicate()
		bag.shuffle()

func pull_from_bag() -> String:
	fill_bag_if_needed()
	return bag.pop_back()

func spawn_piece(piece_type: String = "") -> void:
	if piece_type == "":
		current_piece = next_queue.pop_front()
		next_queue.append(pull_from_bag())
		emit_signal("next_updated", next_queue.duplicate())
	else:
		current_piece = piece_type
	current_rotation = 0
	current_pos = Vector2i(3, 0)
	hold_used = false
	is_locking = false
	lock_timer = 0.0
	lock_reset_count = 0

	if not can_place(current_pos, current_rotation):
		set_game_over()
	queue_redraw()

func hold_current_piece() -> void:
	if hold_used:
		return
	hold_used = true
	if hold_piece == "":
		hold_piece = current_piece
		emit_signal("hold_updated", PIECE_TYPES.find(hold_piece))
		spawn_piece()
	else:
		var next_piece := hold_piece
		hold_piece = current_piece
		emit_signal("hold_updated", PIECE_TYPES.find(hold_piece))
		spawn_piece(next_piece)

func step_fall(is_soft_drop: bool) -> bool:
	if try_move(Vector2i.DOWN):
		if not is_soft_drop:
			queue_redraw()
		return true
	if not is_locking:
		is_locking = true
		lock_timer = 0.0
	return false

func hard_drop() -> void:
	if is_game_over or is_paused:
		return
	var distance := 0
	while try_move(Vector2i.DOWN):
		distance += 1
	score += distance * 2
	emit_signal("score_changed", score)
	lock_piece()

func try_move(delta: Vector2i) -> bool:
	var target := current_pos + delta
	if can_place(target, current_rotation):
		current_pos = target
		if is_locking:
			lock_timer = 0.0
			lock_reset_count += 1
		queue_redraw()
		return true
	return false

func try_rotate(direction: int) -> void:
	var from := current_rotation
	var to := (current_rotation + direction + 4) % 4
	var key := "%d_%d" % [from, to]
	var kick_table = KICKS_I if current_piece == "I" else KICKS_JLSTZ
	var kicks: Array = kick_table.get(key, [Vector2i.ZERO])

	for offset: Vector2i in kicks:
		var target_pos: Vector2i = current_pos + offset
		if can_place(target_pos, to):
			current_pos = target_pos
			current_rotation = to
			if is_locking:
				lock_timer = 0.0
				lock_reset_count += 1
			queue_redraw()
			return

func can_place(pos: Vector2i, rotation: int) -> bool:
	for cell: Vector2i in PIECE_SHAPES[current_piece][rotation]:
		var board_pos: Vector2i = pos + cell
		if board_pos.x < 0 or board_pos.x >= BOARD_WIDTH:
			return false
		if board_pos.y < 0 or board_pos.y >= BOARD_HEIGHT:
			return false
		if board[board_pos.y][board_pos.x] != EMPTY:
			return false
	return true

func lock_piece() -> void:
	for cell: Vector2i in PIECE_SHAPES[current_piece][current_rotation]:
		var board_pos: Vector2i = current_pos + cell
		if board_pos.y >= 0 and board_pos.y < BOARD_HEIGHT:
			board[board_pos.y][board_pos.x] = PIECE_TYPES.find(current_piece)
	clear_lines()
	spawn_piece()
	queue_redraw()

func clear_lines() -> void:
	var kept_rows: Array = []
	var cleared := 0
	for row in board:
		if EMPTY in row:
			kept_rows.append(row)
		else:
			cleared += 1

	while kept_rows.size() < BOARD_HEIGHT:
		var new_row: Array[int] = []
		new_row.resize(BOARD_WIDTH)
		new_row.fill(EMPTY)
		kept_rows.push_front(new_row)
	board = kept_rows

	if cleared > 0:
		lines_cleared += cleared
		score += SCORE_TABLE.get(cleared, 0) * level
		var new_level := int(lines_cleared / 10) + 1
		if new_level != level:
			level = new_level
			emit_signal("level_changed", level)
		emit_signal("lines_changed", lines_cleared)
		emit_signal("score_changed", score)
		if score > high_score:
			high_score = score
			save_high_score()

func set_game_over() -> void:
	is_game_over = true
	is_paused = false
	if score > high_score:
		high_score = score
		save_high_score()
	emit_signal("game_over", score)
	queue_redraw()

func get_piece_cells(piece_type: String, rotation: int, pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in PIECE_SHAPES[piece_type][rotation]:
		result.append(pos + cell)
	return result

func get_ghost_cells() -> Array[Vector2i]:
	var ghost_pos := current_pos
	while can_place(ghost_pos + Vector2i.DOWN, current_rotation):
		ghost_pos += Vector2i.DOWN
	return get_piece_cells(current_piece, current_rotation, ghost_pos)

func _draw() -> void:
	draw_rect(Rect2(BOARD_OFFSET, Vector2(BOARD_WIDTH * CELL_SIZE, BOARD_HEIGHT * CELL_SIZE)), Color("#111111"), true)
	draw_rect(Rect2(BOARD_OFFSET, Vector2(BOARD_WIDTH * CELL_SIZE, BOARD_HEIGHT * CELL_SIZE)), Color("#404040"), false, 2.0)

	for y in BOARD_HEIGHT:
		for x in BOARD_WIDTH:
			var cell_id: int = board[y][x]
			if cell_id == EMPTY:
				draw_rect(Rect2(Vector2(BOARD_OFFSET) + Vector2(x * CELL_SIZE, y * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE)), Color("#1b1b1b"), false, 1.0)
				continue
			var piece_name: String = PIECE_TYPES[cell_id]
			draw_block(Vector2i(x, y), PIECE_COLORS[piece_name])

	if not is_game_over and current_piece != "":
		for ghost_cell in get_ghost_cells():
			draw_block(ghost_cell, PIECE_COLORS[current_piece].darkened(0.2).with_alpha(0.35))
		for cell in get_piece_cells(current_piece, current_rotation, current_pos):
			draw_block(cell, PIECE_COLORS[current_piece])

func draw_block(board_pos: Vector2i, color: Color) -> void:
	var pixel_pos: Vector2 = Vector2(BOARD_OFFSET) + Vector2(board_pos.x * CELL_SIZE, board_pos.y * CELL_SIZE)
	draw_rect(Rect2(pixel_pos, Vector2(CELL_SIZE, CELL_SIZE)), color, true)
	draw_rect(Rect2(pixel_pos, Vector2(CELL_SIZE, CELL_SIZE)), Color.BLACK, false, 1.0)

func get_piece_name_from_id(piece_id: int) -> String:
	if piece_id < 0 or piece_id >= PIECE_TYPES.size():
		return "-"
	return PIECE_TYPES[piece_id]

func load_high_score() -> void:
	if not FileAccess.file_exists("user://save_game.json"):
		high_score = 0
		return
	var file := FileAccess.open("user://save_game.json", FileAccess.READ)
	if file == null:
		high_score = 0
		return
	var content := file.get_as_text()
	var json := JSON.new()
	if json.parse(content) != OK:
		high_score = 0
		return
	var data: Variant = json.data
	if data is Dictionary and data.has("high_score"):
		high_score = int(data["high_score"])
	else:
		high_score = 0

func save_high_score() -> void:
	var file := FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file == null:
		return
	var payload := {"high_score": high_score}
	file.store_string(JSON.stringify(payload))
