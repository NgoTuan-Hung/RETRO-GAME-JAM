class_name BoogieWoogieController
extends Node

const hourly_addition = 1
const disco_bonus = 3
const possessed_bonus = 1
const manifestation_cost = 5
const summoning_cost = 5

var capacity: int = 25
var filled: int = 0
var base_generation_rate: int = 1
var generation_rate: int = base_generation_rate
var can_disappear: bool = false

@onready var node_hub: NodeHub = get_parent() as NodeHub
var wait_time: float
var disappear_tween: Tween

func _ready() -> void:
	# call the on time changed function every tick in the hud
	GameManager.instance.hud.on_game_time_changed.connect(_on_time_changed)
	# Get tick duration from the game timer
	wait_time = GameManager.instance.hud.get_node("GameTimer").wait_time
	
func _on_time_changed(current_hours: int) -> void:
	generation_rate = base_generation_rate + current_hours * hourly_addition

	if filled < capacity:
		filled = clamp(filled + generation_rate, 0, capacity) # Clamp to capacity

	handle_appearance()
	if (can_disappear):
		handle_disappearance()

func handle_appearance() -> void:
	if filled == capacity:
		node_hub.visible = true
		# TODO: turn off collision
		# Manifestation cost starts on the next tick, not right after appearing
		wait_one_minute_before_disappearance()

# Wait for one tick before manifestation cost takes effect
func wait_one_minute_before_disappearance() -> void:
	if disappear_tween && disappear_tween.is_valid():
		disappear_tween.kill()
	disappear_tween = create_tween()
	disappear_tween.tween_interval(wait_time)
	disappear_tween.tween_callback(func(): can_disappear = true)


func handle_disappearance() -> void:
	filled -= manifestation_cost

	if filled < 1:
		node_hub.visible = false
		can_disappear = false
