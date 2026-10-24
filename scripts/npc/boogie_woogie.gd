class_name BoogieWoogie
extends CharacterBody2D

const hourly_addition = 1
const disco_bonus = 3
const possessed_bonus = 1
const manifestation_cost = 5
const summoning_cost = 5

@export var capacity: int = 25
@export var filled: int = 15:
	set(value):
		filled = clamp(value, 0, capacity) # Clamp between 0 and capacity
		sync_energy_ui()
@export var base_generation_rate: int = 1
@export var generation_rate: int = base_generation_rate
var can_disappear: bool = false

var wait_time: float
var disappear_tween: Tween

@onready var animation: AnimationPlayer = $AnimationPlayer

@export var speed: float = 100
var path_to_dj: PackedVector2Array
var direction_this_physics_tick: Vector2
var current_path_index: int = 0
@export var min_distance_for_index_change: float = 0.5

@onready var push_area: Area2D = $PushArea
@export var push_force: float = 60

var summon_chance_per_frame: float = 0.01 # Has some chance of spawning a ghost every frame
@onready var summon_aura: Sprite2D = $Visual/SummonAura

@onready var visual: Node2D = $Visual
enum State { NORMAL, APPEAR, DISAPPEAR, SUMMON, HIBERNATE }
var current_state: State = State.HIBERNATE # Invisible at the start

var initial_position
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# call the on time changed function every tick in the hud
	GameManager.instance.hud.on_game_time_changed.connect(_on_time_changed)
	# Get tick duration from the game timer
	wait_time = GameManager.instance.hud.get_node("GameTimer").wait_time
	
	sync_energy_ui()
	construct_path_to_dj()
	initial_position = global_position

func _process(delta: float) -> void:
	if current_state == State.NORMAL:
		select_next_checkpoint_on_path()
		try_summon_ghost()

func _physics_process(delta: float) -> void:
	if current_state == State.NORMAL:
		calculate_direction_this_physics_tick()
		handle_movement(direction_this_physics_tick)
		push_overlapping_characters(delta)
	
func _on_time_changed(current_hours: int) -> void:
	generation_rate = base_generation_rate + current_hours * hourly_addition

	if filled < capacity:
		filled += generation_rate

	if (can_disappear):
		handle_disappearance()
	handle_appearance()

func handle_appearance() -> void:
	if filled == capacity:
		if current_state == State.HIBERNATE:
			current_state = State.APPEAR
		else: return
		visible = true
		animation.play("appear")
		global_position = initial_position # Reset his position to the basement upon appearing
		collision_shape.disabled = false
		# Manifestation cost starts on the next tick, not right after appearing
		wait_one_minute_before_disappearance()

		await animation.animation_finished
		if current_state == State.APPEAR:
			current_state = State.NORMAL

# Wait for one tick before manifestation cost takes effect
func wait_one_minute_before_disappearance() -> void:
	if disappear_tween && disappear_tween.is_running():
		disappear_tween.stop()
	
	disappear_tween = create_tween()
	disappear_tween.tween_interval(wait_time - 0.01)
	disappear_tween.tween_callback(func(): can_disappear = true)


func handle_disappearance() -> void:
	filled -= manifestation_cost

	if filled < 1:
		if current_state == State.NORMAL:
			current_state = State.DISAPPEAR
		else: return
		can_disappear = false
		animation.play("fade")
		collision_shape.disabled = true
		await animation.animation_finished # Wait for the animation to finish
		visible = false

		if current_state == State.DISAPPEAR:
			current_state = State.HIBERNATE

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
		visual.scale.x = -1 if velocity.x < 0 else 1

	move_and_slide()

#region A* Pathfinding
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

#region Shoving
## Push characters that go near the boogie woogie
func push_overlapping_characters(delta: float) -> void:
	for body in push_area.get_overlapping_bodies():
		if body.is_in_group("pushable") and body != self: # Only characters in the pushable group can be shoved
			var push_dir = (body.global_position - global_position).normalized()
			
			body.move_and_collide(push_dir * push_force * delta)
#endregion

#region Summoning Ghosts
func try_summon_ghost() -> void:
	if filled >= summoning_cost:
		if current_state == State.NORMAL:
			if randf() < summon_chance_per_frame:
				current_state = State.SUMMON
				animation.play("summon")
				show_summon_aura()
				place_a_ghost_near_me()
				filled -= summoning_cost
				await animation.animation_finished
				current_state = State.NORMAL
		else: return

func place_a_ghost_near_me() -> void:
	var ghost = GameManager.instance.ghost_scene.instantiate() # get the ghost_scene from game manager and instantiate it
	# place the ghost in a random direction 30 unit away from me
	ghost.global_position = global_position + Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 30
	get_tree().current_scene.add_child(ghost)
	ghost.appear()

func show_summon_aura() -> void:
	summon_aura.visible = true
	summon_aura.scale = Vector2.ZERO
	summon_aura.modulate.a = 0.8

	var tween = create_tween()
	# 1. Charge up: Expand gradually
	tween.tween_property(summon_aura, "scale", Vector2(0.5, 0.5), 0.7)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
	# 2. Shrink and disappear as the ghost appears
	tween.tween_property(summon_aura, "scale", Vector2.ZERO, 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await tween.finished
	summon_aura.visible = false
#endregion
