extends CanvasLayer

@export var game_path: NodePath

@onready var score_label: Label = %ScoreValue
@onready var level_label: Label = %LevelValue
@onready var lines_label: Label = %LinesValue
@onready var next_label: Label = %NextValue
@onready var hold_label: Label = %HoldValue
@onready var pause_label: Label = %PauseLabel
@onready var game_over_label: Label = %GameOverLabel

var game: Game

func _ready() -> void:
	game = get_node_or_null(game_path)
	if game == null:
		return
	game.score_changed.connect(_on_score_changed)
	game.level_changed.connect(_on_level_changed)
	game.lines_changed.connect(_on_lines_changed)
	game.next_updated.connect(_on_next_updated)
	game.hold_updated.connect(_on_hold_updated)
	game.game_over.connect(_on_game_over)

func _process(_delta: float) -> void:
	if game == null:
		return
	pause_label.visible = game.is_paused
	game_over_label.visible = game.is_game_over
	if game.is_game_over:
		game_over_label.text = "GAME OVER\nEnter: Retry"

func _on_score_changed(value: int) -> void:
	score_label.text = str(value)

func _on_level_changed(value: int) -> void:
	level_label.text = str(value)

func _on_lines_changed(value: int) -> void:
	lines_label.text = str(value)

func _on_next_updated(queue: Array) -> void:
	var names: Array[String] = []
	for item in queue:
		names.append(str(item))
	next_label.text = "\n".join(names)

func _on_hold_updated(piece_type: int) -> void:
	hold_label.text = game.get_piece_name_from_id(piece_type)

func _on_game_over(_final_score: int) -> void:
	game_over_label.visible = true
