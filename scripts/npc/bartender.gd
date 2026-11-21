class_name Bartender
extends CharacterBody2D

@onready var animation: AnimationPlayer = $AnimationPlayer

# Movement and A* pathfinding
@export var speed: float = 100
var path_to_destination: PackedVector2Array # List of checkpoints along the path
var direction_this_physics_tick: Vector2   # Movement direction for the current physics tick
var current_path_index: int = 0            # Current target checkpoint index
@export var min_distance_for_index_change: float = 0.5 # Distance threshold to advance to the next checkpoint

var current_table: Table = null
var table_serving_distance: float = 10.0

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    select_next_checkpoint_on_path()
    check_reached_table()
    
func _physics_process(delta: float) -> void:
    calculate_direction_this_physics_tick()
    handle_movement(direction_this_physics_tick)

func take_order(table: Table):
    current_table = table
    construct_a_path_to_table(table)
    pass

#region Movement
func handle_movement(direction: Vector2) -> void:
    if direction:
        velocity = direction.normalized() * speed
        # animation.play("walk")
    else:
        velocity = Vector2.ZERO
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

#region Serving
func check_reached_table() -> void:
    if current_table and global_position.distance_to(current_table.global_position) < table_serving_distance:
        current_table.place_drink_for_customer()
        current_table = null
#endregion