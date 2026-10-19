class_name BoogieWoogie
extends CharacterBody2D

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

var wait_time: float
var disappear_tween: Tween

@onready var animation: AnimationPlayer = $AnimationPlayer

@export var speed: float = 100
var can_move: bool = false
var path_to_dj: PackedVector2Array
var direction_this_physics_tick: Vector2
var current_path_index: int = 0
@export var min_distance_for_index_change: float = 0.5

func _ready() -> void:
	# call the on time changed function every tick in the hud
	GameManager.instance.hud.on_game_time_changed.connect(_on_time_changed)
	# Get tick duration from the game timer
	wait_time = GameManager.instance.hud.get_node("GameTimer").wait_time
	
	sync_energy_ui()

	construct_path_to_dj()

func _process(delta: float) -> void:
	if can_move:
		select_next_checkpoint_on_path()

func _physics_process(delta: float) -> void:
	if can_move:
		calculate_direction_this_physics_tick()
		handle_movement(direction_this_physics_tick)
	
func _on_time_changed(current_hours: int) -> void:
	generation_rate = base_generation_rate + current_hours * hourly_addition

	if filled < capacity:
		filled = clamp(filled + generation_rate, 0, capacity) # Clamp to capacity

	if (can_disappear):
		handle_disappearance()
	handle_appearance()
	
	sync_energy_ui()

func handle_appearance() -> void:
	if filled == capacity:
		visible = true
		animation.play("appear")
		# TODO: turn off collision
		# Manifestation cost starts on the next tick, not right after appearing
		wait_one_minute_before_disappearance()

		await animation.animation_finished
		can_move = true # Can only move after fully appearing

# Wait for one tick before manifestation cost takes effect
func wait_one_minute_before_disappearance() -> void:
	if disappear_tween && disappear_tween.is_running():
		disappear_tween.stop()
	
	disappear_tween = create_tween()
	disappear_tween.tween_interval(wait_time - 0.01)
	disappear_tween.tween_callback(func(): can_disappear = true)


func handle_disappearance() -> void:
	filled = clamp(filled - manifestation_cost, 0, capacity) # Cannot go below 0

	if filled < 1:
		can_move = false
		can_disappear = false
		animation.play("fade")
		await animation.animation_finished # Wait for the animation to finish
		visible = false

func sync_energy_ui() -> void:
	GameManager.instance.hud.update_boogie_woogie_energy(filled, capacity)

func handle_movement(direction: Vector2) -> void:
	if direction:
		velocity = direction.normalized() * speed
		animation.play("walk")
	else:
		velocity = Vector2.ZERO
		# if not moving — play the idle animation
		animation.play("dance")

	# if moving left — flip the sprite horizontally
	if velocity.x:
		$Sprite2D.flip_h = velocity.x < 0

	move_and_slide()

#region A* Pathfinding Code
## Ask the pathfinding manager for a path from current position to dj.
## Since the path is unchanged for boogie woogie, we only need to call this once
func construct_path_to_dj() -> void:
	# The path is a list of Vector2 points
	path_to_dj = PathfindingManager.instance.find_path(global_position, GameManager.instance.giving_track_point.global_position)

## If the boogie woogie is close enough to a checkpoint on the path, move to the next checkpoint
func select_next_checkpoint_on_path() -> void:
	if !path_to_dj or path_to_dj.size() <= 1:
		return

	if (current_path_index < path_to_dj.size() - 1):
		if (global_position.distance_to(path_to_dj[current_path_index]) < min_distance_for_index_change):
			current_path_index += 1

## Move the boogie woogie in the direction of the next checkpoint.
func calculate_direction_this_physics_tick() -> void:
	if !path_to_dj or path_to_dj.size() <= 1:
		return

	if current_path_index == path_to_dj.size() - 1:
		direction_this_physics_tick = Vector2.ZERO
	else:
		direction_this_physics_tick = path_to_dj[current_path_index] - global_position
#endregion