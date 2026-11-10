extends CanvasLayer

const gameMinutes : int = 900
var gameTime : int = 0
signal on_game_time_changed(current_hours: int)

var _active_tweens: Dictionary = {}                                                                                                                                   
var _base_positions: Dictionary = {}        

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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

func update_resistance(current_val: float, max_val: float) -> void:
	%ResistanceBar.max_value = max_val
	%ResistanceBar.value = current_val

func update_resource(water_count: int, drink_count: int, rock_count: int, gears: int) -> void:
	%HolyWaterLabel.text = "W: %d" % water_count
	%DrinkLabel.text = "D: %d" % drink_count
	# %RockDiscLabel.text = "R: %d" % rock_count
	
	# %GearLabel.text = "[G: %d]" % gears.size()

func feedback_on_resource_depletion(resource_name: String) -> void:
	match resource_name:
		"Holy Water":
			flash_empty_label(%HolyWaterLabel)
		"Drink":
			flash_empty_label(%DrinkLabel)
		"Rock Disc":
			flash_empty_label(%RockDiscLabel)                                                                                                                          
                                                                                                                                                                          
func flash_empty_label(label: Control) -> void:                                                                                                                       
	# 1. Reset to the original state if a tween is already running (prevents spam clicking from misaligning the UI)
	if _active_tweens.has(label) and is_instance_valid(_active_tweens[label]):                                                                                           
		_active_tweens[label].kill()                                                                                                                                         
		label.position.x = _base_positions.get(label, label.position.x)                                                                                                      
		label.modulate = Color.WHITE                                                                                                                                         
	else:
		_base_positions[label] = label.position.x                                                                                                                            
																																										
	var base_x = _base_positions[label]                                                                                                                                  

	# 2. Flash Red (Flashes red then fades back to original/white color)
	var color_tween = create_tween()                                                                                                                                     
	label.modulate = Color(2.5, 0.3, 0.3) # Glowing red tone (overbright)                                                                                               
	color_tween.tween_property(label, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Horizontal shake (Quick 4-5 shakes within 0.2s)
	var shake_tween = create_tween()                                                                                                                                     
	_active_tweens[label] = shake_tween # Store to kill if spammed                                                                                                    
	
	var shake_offset: float = 4.0 # Shake intensity (pixels)                                                                                                                      
	shake_tween.tween_property(label, "position:x", base_x - shake_offset, 0.04)
	shake_tween.tween_property(label, "position:x", base_x + shake_offset, 0.04)                                                                                         
	shake_tween.tween_property(label, "position:x", base_x - shake_offset * 0.5, 0.04)                                                                                   
	shake_tween.tween_property(label, "position:x", base_x + shake_offset * 0.5, 0.04)
	shake_tween.tween_property(label, "position:x", base_x, 0.04)                                                                                                        