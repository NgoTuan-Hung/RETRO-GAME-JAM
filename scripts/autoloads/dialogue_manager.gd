extends Node

@export var dialogue_file := "res://dialog/retro_game_dialogue.txt"
var _dialogue_dict := {}
var _openings_list : PackedStringArray = []

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
			_dialogue_dict[key] = {}
			_dialogue_dict[key]["speaker"] = columns[1]
			_dialogue_dict[key]["listener"] = columns[2]
			_dialogue_dict[key]["condition"] = columns[4]
			_dialogue_dict[key]["dialogue"] = columns[5]
			_dialogue_dict[key]["usage_count"] = 0
			if columns[3] == "" :
				_openings_list.append(key)
			else:
				var follows = columns[3].split(",")
				for item in follows:
					if ! _dialogue_dict[item].has("continuations"):
						_dialogue_dict[item]["continuations"] = PackedStringArray()
					_dialogue_dict[item]["continuations"].append(key)
	for key in _dialogue_dict :
		print(key, " ", _dialogue_dict[key]["dialogue"])

func get_dialogue(key : String = "bm1") -> Dictionary :
	return _dialogue_dict[key]
