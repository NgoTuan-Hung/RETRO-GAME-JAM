extends CanvasLayer

const gameMinutes : int = 900
var gameTime : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Talk"):
		print("Hello!")

func _on_game_timer_timeout() -> void:
	gameTime += 1
	var hour = floor(gameTime/60)
	var minutes = gameTime - (hour * 60)
	var timeString = "%d:%02d pm" % [8 + hour, minutes]
	$TopBar/Clock.text = timeString
