extends Node2D
class_name Talkable

@export var offset := 32					# display height above character

signal speech_bubble_clicked
signal speech_bubble_complete
signal speech_bubble_closed

# Delay time between characters
const letter_time := 0.03					# static typed float
const space_time := 0.06					# static typed float
const punctuation_time := 0.2				# static typed float

# How long does the speech bubble stay visible once displayed
const linger_time_per_character := 0.05		# static typed float
const minimum_linger_time := 3.0			# static typed float
var linger_time := 0.0						# static typed float
var lingering := false

# Maximum width for the speech bubble
# const max_width := 256		# static typed int - width of bubble

# Text to display
var speech := ""			# static typed String - text to display

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func say_text(text : String) -> void :
	speech = text
	lingering = false
	visible = true
	display_next_letter()

func display_next_letter() -> void :
	$SpeechBubble/MarginContainer/Speech.text += get_next_letter()
	position.x = -($SpeechBubble.size.x / 2)
	position.y = -($SpeechBubble.size.y + offset)
	$SpeechBubble/Timer.start(0.1)

func get_next_letter() -> String :
	var n := len($SpeechBubble/MarginContainer/Speech.text)
	return speech[n]

func _on_timer_timeout() -> void:
	if lingering:
		visible = false
		return
	if len($SpeechBubble/MarginContainer/Speech.text) < len(speech):
		display_next_letter()
	else:
		lingering = true
		$SpeechBubble/Timer.start(2)
