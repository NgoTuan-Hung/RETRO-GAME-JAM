class_name Ghost
extends CharacterBody2D

## Controls Ghost NPC behavior, pathfinding to Target using PathfindingManager.

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

@onready var sprite: Sprite2D = $Sprite2D
@export var possession_range: float = 10 # The minimum range in which the ghost is allowed to posses dancers
@export var npc_possession_time: float = 2

enum State { NORMAL, APPEAR, DISAPPEAR, POSSESS }
var current_state: State = State.APPEAR # Also initial state

var chase_time: float = 0 # The ammount of time since we start chasing after the player if he is not in our possession range
@export var max_chase_time: float = 10 # The maximum ammount of time we are allowed to chase after the player if he is not in our possession range
@export var resistance_drained_persec: float = 10 # Resistance drained from the player per second
var time_since_last_drain: float = 0 # The ammount of time since the last drain ticked

func _ready() -> void:
	target = GameManager.instance.get_a_random_target_for_ghost()

	# Stagger initial path search
	time_since_last_pathfinding = randf_range(0.0, pathfinding_interval)

func _process(delta: float) -> void:
	if current_state == State.APPEAR:
		return

	update_target()

	if target == null:
		direction_this_physics_tick = Vector2.ZERO
		return

	possess_if_in_range(delta)

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

func _physics_process(delta: float) -> void:
	if current_state == State.APPEAR:
		return

	handle_movement(direction_this_physics_tick)

func handle_movement(direction: Vector2) -> void:
	if direction:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO

	if current_state == State.NORMAL: # only walk if the current state is normal
		animation.play("walk")

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

func update_path() -> void:
	if target == null:
		return

	path_to_target = PathfindingManager.instance.find_path(global_position, target.global_position)

	decide_waiting_or_not()
	current_checkpoint_index = 0

func decide_waiting_or_not() -> void:
	if path_to_target.size() <= 1:
		wait_for_next_pathfinding = true
	else:
		wait_for_next_pathfinding = false

## Play the appearance effect using shader
func appear() -> void:
	current_state = State.APPEAR
	# Need to make change on the copy of the material
	# Else editing one would affect others
	sprite.material = sprite.material.duplicate()
	var mat = sprite.material as ShaderMaterial
	mat.set_shader_parameter("progress", 0.0)
	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/progress", 1.0, 1.0) # play the effect for 1s
	await tween.finished
	if current_state == State.APPEAR:
		current_state = State.NORMAL
	

## Switch target if the current one is being possessed by another ghost or is already possessed.
func update_target() -> void:
	if target:
		if target is NPC && (target.possessed || (target.current_state == NPC.State.BEING_POSSESSED && target.possessed_by != self)):
			target = GameManager.instance.get_next_target_for_ghost()
		elif target is Player && chase_time > max_chase_time:
			target = GameManager.instance.get_next_target_for_ghost(true)


## Possess the target if in range (and not already possessed if it's NPC). If the target is out of range, abort possession.
## If the current target is NPC, possession will immobilize the target for the duration of npc_possession_time.
## If the current target is Player, possession will tick one per sec if the player is in possession_range of the ghost,
## , the ammount of resistance subtracted from the player is determined by resistance_drained_persec.
## TODO: Handle the case where we are possessing a target and the player spray holy water on us.
func possess_if_in_range(delta: float) -> void:
	var distance_to_target = global_position.distance_to(target.global_position)

	if target is NPC:
		if distance_to_target < possession_range && current_state == State.NORMAL:
			current_state = State.POSSESS
			animation.play("possess")

			await target.start_possession(npc_possession_time, self)
			if current_state == State.POSSESS:
				current_state = State.NORMAL
				temporary_disable()
		## Also abort if out of possession range
		elif distance_to_target > possession_range && current_state == State.POSSESS:
			current_state = State.NORMAL
	elif target is Player:
		chase_time += delta
		if distance_to_target < possession_range:
			if current_state == State.NORMAL:
				current_state = State.POSSESS
				animation.play("possess")
			elif current_state == State.POSSESS:
				if time_since_last_drain > 1:
					time_since_last_drain = 0
					target.reduce_resistance(resistance_drained_persec)

				time_since_last_drain += delta
			chase_time = 0
		elif distance_to_target > possession_range && current_state == State.POSSESS:
			current_state = State.NORMAL
			animation.play("idle")
			time_since_last_drain = 0
			

## Make the ghost invisible after the possession of a NPC by turning off visibility, collision.
func temporary_disable() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true

## Make the ghost visible again
func enable() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = false