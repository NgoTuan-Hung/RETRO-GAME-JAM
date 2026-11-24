class_name Bartender
extends CharacterBody2D

@onready var animation: AnimationPlayer = $AnimationPlayer

# Movement and A* pathfinding
@export var speed: float = 100
var path_to_destination: PackedVector2Array # List of checkpoints along the path
var direction_this_physics_tick: Vector2   # Movement direction for the current physics tick
var current_path_index: int = 0            # Current target checkpoint index
@export var min_distance_for_index_change: float = 0.5 # Distance threshold to advance to the next checkpoint

var orders: Array[Order] = []
var current_table: Table = null
var table_serving_distance: float = 15.0
var this_round_orders: Array[Order] = []
var current_order_index: int = 0

var origin: Vector2

enum ServingState {ROUND_SERVING, RETURN, ROUND_CLEANING, IDLE}
var current_serving_state: ServingState = ServingState.IDLE

var clean_requests: Array[CleanTableRequest] = []
var current_cleaning_table: Table = null
var table_cleaning_distance: float = 15.0
var this_round_clean_requests: Array[CleanTableRequest] = []
var current_request_index: int = 0

@onready var body_collision: BodyCollision = $BodyCollision

func _ready() -> void:
	origin = global_position

func _process(delta: float) -> void:
	select_next_checkpoint_on_path()
	check_reached_destination()
	serve_this_round()
		
func _physics_process(delta: float) -> void:
	calculate_direction_this_physics_tick()
	handle_movement(direction_this_physics_tick)

#region Movement
func handle_movement(direction: Vector2) -> void:
	var body_collision_vector = body_collision.get_push_vector()
	if direction:
		velocity = direction.normalized() * speed + body_collision_vector
		# animation.play("walk")
	else:
		velocity = body_collision_vector
		# animation.play("idle")

	# if moving left — flip the sprite horizontally
	if velocity.x:
		$Sprite2D.flip_h = velocity.x < 0

	move_and_slide()
#endregion

#region A* Pathfinding
## Ask the pathfinding manager for a path from current position to a table.
func construct_a_path_to_table(table: Table) -> void:
	# The path is a list of Vector2 points
	path_to_destination = PathfindingManager.instance.find_path(global_position, table.global_position)
	current_path_index = 0

func construct_a_path_to_origin() -> void:
	path_to_destination = PathfindingManager.instance.find_path(global_position, origin)
	current_path_index = 0

## If the bartender is close enough to a checkpoint on the path, move to the next checkpoint
func select_next_checkpoint_on_path() -> void:
	if !path_to_destination or path_to_destination.size() <= 1:
		return

	if (current_path_index < path_to_destination.size() - 1):
		if (global_position.distance_to(path_to_destination[current_path_index]) < min_distance_for_index_change):
			current_path_index += 1

## Move the bartender in the direction of the next checkpoint.
func calculate_direction_this_physics_tick() -> void:
	if !path_to_destination or path_to_destination.size() <= 1:
		return

	if current_path_index == path_to_destination.size() - 1:
		direction_this_physics_tick = Vector2.ZERO
	else:
		direction_this_physics_tick = path_to_destination[current_path_index] - global_position
#endregion

#region Serving & Cleaning
func take_order(order: Order):
	for o in orders:
		if o.table == order.table:
			if order.order_from_left:
				o.order_from_left = true
			if order.order_from_right:
				o.order_from_right = true
			return

	orders.append(order)

func check_reached_destination() -> void:
	if current_serving_state == ServingState.ROUND_SERVING:
		if current_table and global_position.distance_to(current_table.global_position) < table_serving_distance:
			current_table.place_drink_for_customer(this_round_orders[current_order_index])
			current_table = null

			current_order_index += 1
			if current_order_index < this_round_orders.size():
				current_table = this_round_orders[current_order_index].table
				construct_a_path_to_table(current_table)
			else:
				# If there are any table need cleaning, go for cleaning, otherwise, go back.
				if clean_requests.size() > 0:
					clean_this_round()
				else:
					current_serving_state = ServingState.RETURN
					construct_a_path_to_origin()
	elif current_serving_state == ServingState.ROUND_CLEANING:
		if current_cleaning_table and global_position.distance_to(current_cleaning_table.global_position) < table_cleaning_distance:
			current_cleaning_table.clean_table(this_round_clean_requests[current_request_index])
			current_cleaning_table = null

			current_request_index += 1
			if current_request_index < this_round_clean_requests.size():
				current_cleaning_table = this_round_clean_requests[current_request_index].table
				construct_a_path_to_table(current_cleaning_table)
			else:
				current_serving_state = ServingState.RETURN
				construct_a_path_to_origin()
	elif current_serving_state == ServingState.RETURN:
		if global_position.distance_to(origin) < 15:
			current_serving_state = ServingState.IDLE

func serve_this_round() -> void:
	if current_serving_state == ServingState.IDLE:
		if orders.size() > 0:
			this_round_orders = orders.duplicate()
			orders.clear()
			current_order_index = 0
			current_serving_state = ServingState.ROUND_SERVING
			current_table = this_round_orders[0].table
			construct_a_path_to_table(current_table)
		elif clean_requests.size() > 0:
			clean_this_round()

func clean_this_round() -> void:
	this_round_clean_requests = clean_requests.duplicate()
	clean_requests.clear()
	current_request_index = 0
	current_serving_state = ServingState.ROUND_CLEANING
	current_cleaning_table = this_round_clean_requests[0].table
	construct_a_path_to_table(current_cleaning_table)

func note_clean_table(clean_table_request: CleanTableRequest):
	for cr in clean_requests:
		if cr.table == clean_table_request.table:
			if clean_table_request.request_from_left:
				cr.request_from_left = true
			if clean_table_request.request_from_right:
				cr.request_from_right = true
			return

	clean_requests.append(clean_table_request)
#endregion