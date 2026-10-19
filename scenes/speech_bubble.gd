extends Node2D

signal clicked

const time_per_letter : float = 0.1
const min_time : float = 3.0

func _ready() -> void :
	visible = false
	say("I am the very model of a modern major general!")

func say(text: String) -> void :
	$Anchor/RichTextLabel.text = text
	$Anchor/RichTextLabel.set_size(Vector2(250,100))
	$Anchor/RichTextLabel.fit_content = true
	$Anchor/ColorRect.size = $Anchor/RichTextLabel.size
	visible = true
	$Timer.start(max(len(text) * time_per_letter, min_time))

func _on_timer_timeout() -> void:
	$Anchor/ColorRect.visible = false
	$Anchor/RichTextLabel.visible = false
