class_name Ghost
extends CharacterBody2D

## Controls Ghost NPC behavior, pathfinding to Target using PathfindingManager.
## Communicates with movement and physics components through its parent NodeHub.

@export var target: Node2D
@export var pathfinding_interval: float = 0.5
@export var min_distance_for_index_change: float = 1.5

var path_to_target: PackedVector2Array = PackedVector2Array()
var current_checkpoint_index: int = 0
var time_since_last_pathfinding: float = 0.0
var wait_for_next_pathfinding: bool = false
var direction_this_physics_tick: Vector2 = Vector2.ZERO

@onready var animation: AnimationPlayer = $AnimationPlayer
@export var speed: float = 40

func _ready() -> void:
	target = GameManager.instance.get_a_random_target_for_ghost()

	# Stagger initial path search
	time_since_last_pathfinding = randf_range(0.0, pathfinding_interval)

func _process(delta: float) -> void:
	# Path following logic
	if not path_to_target.is_empty() and not wait_for_next_pathfinding:
		select_next_checkpoint_on_path()
		decide_where_to_go_next()
	else:
		direction_this_physics_tick = Vector2.ZERO

	# Periodic path recalculation
	time_since_last_pathfinding += delta
	if time_since_last_pathfinding >= pathfinding_interval:
		time_since_last_pathfinding = 0.0
		update_path()

	handle_movement(direction_this_physics_tick)

func handle_movement(direction: Vector2) -> void:
	if direction:
		velocity = direction.normalized() * speed
		animation.play("walk")
	else:
		velocity = Vector2.ZERO
		# if not moving — play the idle animation
		animation.play("idle")

	# if moving left — flip the sprite horizontally
	if velocity.x:
		$Sprite2D.flip_h = velocity.x < 0

	move_and_slide()

func decide_where_to_go_next() -> void:
	if current_checkpoint_index >= path_to_target.size():
		direction_this_physics_tick = Vector2.ZERO
		return

	var next_position := path_to_target[current_checkpoint_index]
	var diff := next_position - global_position
	if diff.length_squared() > 1.0:
		direction_this_physics_tick = diff.normalized()
	else:
		direction_this_physics_tick = Vector2.ZERO

func select_next_checkpoint_on_path() -> void:
	if current_checkpoint_index >= path_to_target.size():
		return

	var dist := global_position.distance_to(path_to_target[current_checkpoint_index])
	if dist < min_distance_for_index_change:
		if current_checkpoint_index < path_to_target.size() - 1:
			current_checkpoint_index += 1

func decide_waiting_or_not() -> void:
	if path_to_target.size() <= 1:
		wait_for_next_pathfinding = true
	else:
		wait_for_next_pathfinding = false

func update_path() -> void:
	if target == null:
		return

	# Query PathfindingManager singleton or autoload
	var manager := PathfindingManager.instance
	if manager == null:
		# Try to find PathfindingManager in scene
		manager = get_tree().root.find_child("PathfindingManager", true, false) as PathfindingManager

	if manager:
		path_to_target = manager.find_path(global_position, target.global_position)
	else:
		push_warning("[GhostController] PathfindingManager not found in scene tree!")
		path_to_target.clear()

	decide_waiting_or_not()
	current_checkpoint_index = 0
