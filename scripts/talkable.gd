class_name Talkable
extends Node2D

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

# Maximum width for the speech bubble
# const max_width := 256		# static typed int - width of bubble

# Text to display
var speech := ""			# static typed String - text to display
var letter_index := -1		# static typed int - where are we up to?

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func say_text(text : String) -> void :
	$SpeechBubble/MarginContainer/Label.text = text
	position.x = -($SpeechBubble.size.x / 2)
	position.y = -($SpeechBubble.size.y + offset)
	visible = true
	$SpeechBubble/Timer.start(5.0)

func display_next_letter() -> void :
	pass

func _on_timer_timeout() -> void:
	visible = false
