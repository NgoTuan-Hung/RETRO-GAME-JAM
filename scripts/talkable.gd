extends Node2D
class_name Talkable

@export var offset := 32					# display height above character
@export var character_id : String

signal get_Dialogue(speaker : Talkable, listener : Talkable)
signal used_dialog(dialogue_id : String)

signal speech_bubble_clicked
signal speech_bubble_complete
signal speech_bubble_closed

# Delay time between characters
const letter_time := 0.03					# static typed float
const space_time := 0.06					# static typed float
const punctuation_time := 0.2				# static typed float

# How long does the speech bubble stay visible once displayed
const linger_time_per_character := 0.05		# static typed float
const minimum_linger_time := 2.0			# static typed float
var linger_time := 0.0						# static typed float
var lingering := false

# Maximum width for the speech bubble
# const max_width := 256		# static typed int - width of bubble

# Text to display
var speech := ""			# static typed String - text to display

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if character_id == "" :
		character_id = "dancer"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func say_text(text : String) -> void :
	$SpeechBubble/MarginContainer/Speech.text = ""
	speech = text
	linger_time = 0.0
	lingering = false
	visible = true
	_display_next_letter()

func _display_next_letter() -> void :
	var next_letter = _get_next_letter()
	var pause_time := 0.0
	$SpeechBubble/MarginContainer/Speech.text += next_letter
	_adjust_size()

	match next_letter:
		" ", "\n" :
			pause_time = space_time

		".", ",", "!", "?", ";", ":", "-":
			pause_time = punctuation_time

		_:
			pause_time = letter_time

	linger_time += linger_time_per_character
	$SpeechBubble/Timer.start(pause_time)

func _get_next_letter() -> String :
	var n := len($SpeechBubble/MarginContainer/Speech.text)
	return speech[n]

func _adjust_size() -> void :
	position.x = -($SpeechBubble.size.x / 2)
	position.y = -($SpeechBubble.size.y + offset)

func _on_timer_timeout() -> void:
	if lingering:
		visible = false
		return
	if len($SpeechBubble/MarginContainer/Speech.text) < len(speech):
		_display_next_letter()
	else:
		lingering = true
		$SpeechBubble/Timer.start(max(linger_time, minimum_linger_time))
