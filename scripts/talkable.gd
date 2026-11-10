extends Node2D
class_name Talkable

signal speech_bubble_clicked
signal speech_bubble_complete
signal speech_bubble_closed

#region textbox display variables
@export var offset := 32					# display height above character
@export var character_id : String			# DialogueManager ID
const letter_time := 0.03					# delay after letters and numbers
const space_time := 0.06					# delay after spaces
const punctuation_time := 0.2				# delay after punctuation
const linger_time_per_character := 0.05		# time before textbox disappears
const minimum_linger_time := 2.0			# minimum display time when complete
var linger_time := 0.0						# accumulated linger time
var lingering := false						# becomes true when text complete
var speech := ""							# full text to be displayed
#endregion

#region textbox display functions
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

#endregion

#region DialogueManager functions
func talk_to(speaker: Talkable, listener: Talkable) -> void :
	pass

func use_dialogue_options(dialogue_options : Dictionary) -> void :
	pass

func show_dialogue_options(dialogue_options : Dictionary) -> void :
	pass

#endregion
