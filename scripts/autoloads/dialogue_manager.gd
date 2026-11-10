extends Node

@export var dialogue_file := "res://dialog/retro_game_dialogue.txt"
var _dialogue_dict := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_dialogue_file()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func load_dialogue_file() -> void :
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	var content = file.get_as_text()
	var content_array : PackedStringArray = content.split("\n")
	for line in content_array.slice(1):
		line = line.strip_edges()
		if len(line) > 0 :
			var columns = line.split("\t")
			var key : String = columns[0]
			var linedict := {}
			linedict["speaker"] = columns[1]
			linedict["listener"] = columns[2]
			linedict["condition"] = columns[4]
			linedict["dialogue"] = columns[5]
			_dialogue_dict[key] = linedict
	for key in _dialogue_dict.keys():
		print(key, " ", _dialogue_dict[key]["dialogue"])




	

func get_dialogue(listener : String, speaker := "player") -> Dictionary :
	return {}
