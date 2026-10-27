extends Node

@export var dialogue_file := "res://dialog/dialog.csv"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# load_dialogue()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func load_dialogue() -> void :
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	var content = file.get_as_text()
	print(content)
