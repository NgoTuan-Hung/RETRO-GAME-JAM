extends CanvasLayer

const gameMinutes : int = 900
var gameTime : int = 0
signal on_game_time_changed(current_hours: int)

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
	var meridiem = "pm"
	if hour > 3 :
		meridiem = "am"
		if hour > 4 :
			hour -= 12
	var timeString = "%d:%02d %s" % [8 + hour, minutes, meridiem]
	on_game_time_changed.emit(hour)
	$TopBar/Clock.text = timeString

func update_boogie_woogie_energy(current_val: int, max_val: int) -> void:
	%EnergyBar.max_value = max_val
	%EnergyBar.value = current_val
