class_name NPC
extends CharacterBody2D

#region variables
## The [NPCSpriteSet] defining this NPC's appearance.
##
## Drag a Spriteset from [code]res://resources/NPCSpriteSets[/code] into the
## Spriteset property in the Inspector to give this NPC a specific skin.
## Or leave it blank to allow the scence to select a random skin on _ready().
@export var spriteset: NPCSpriteSet
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var talkable := $Talkable
@onready var random_dialogue_timer := $RandomDialogueTimer

@export var dancer_dialogue := "res://dialog/dancer_random_dialogue.txt"
@export var possessed_dancer_dialogue := "res://dialog/possessed_dancer_random_dialogue.txt"

# Ghost possession state
enum State { NORMAL, BEING_POSSESSED, WALK, DANCE}
var current_state: State = State.NORMAL
var possessed = false
var possessed_by: Node2D

# Movement and A* pathfinding
@export var speed: float = 100
var path_to_destination: PackedVector2Array # List of checkpoints along the path
var direction_this_physics_tick: Vector2   # Movement direction for the current physics tick
var current_path_index: int = 0            # Current target checkpoint index
@export var min_distance_for_index_change: float = 0.5 # Distance threshold to advance to the next checkpoint

# Anti-stuck mechanism (steering) when blocked by obstacles
var previous_position: Vector2 # Track previous position when steering
var time_since_resting: float = 0.0 # The ammount of time since we last moved
## The different in the distance between the position in this frame and last frame
## To be considered not moving at all.
var resting_distance: float = 0.5
var steering: bool = false # Should we steer
var resting_time: float = 0.5 # After not moving for this long, steering will happen
var time_since_last_steering: float = 0
var steering_duration: float = 0.5

## This will be used to decide the next action the dancer will take
enum Action {WALK, DANCE}
var current_action: Action = Action.WALK
var action_goal_finished: bool = true

#endregion

#region built-in functions
func _ready() -> void:
	# If no spriteset is assigned in Inspector, pick a random one from the folder
	if spriteset == null:
		var spritesetfolder : String = "res://resources/NPCSpriteSets/"
		var dir = DirAccess.open(spritesetfolder)
		var npcspritesetnames : Array[String] = []
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				npcspritesetnames.append(f)
			f = dir.get_next()
		dir.list_dir_end()
		spriteset= load(spritesetfolder + npcspritesetnames.pick_random())
	$Sprite2D.texture = spriteset.normal_sheet
	$AnimationPlayer.play("start_dancing")
	GameManager.instance.register_as_ghost_target(self) # Register as a ghost target so it can be picked by the ghost
	# random_dialogue_timer.start(randf_range(5.0, 20.0))
	print(FileAccess.open(dancer_dialogue, FileAccess.READ).get_as_text())
	print(FileAccess.open(possessed_dancer_dialogue, FileAccess.READ).get_as_text())

func _process(delta: float) -> void:
	# Stop actions while being possessed
	if current_state == State.BEING_POSSESSED:
		return

	# Advance to next checkpoint when walking
	if current_action == Action.WALK:
		select_next_checkpoint_on_path()
	
	# Pick a new action once the current goal is finished
	if action_goal_finished:
		choosing_next_action()
	
func _physics_process(delta: float) -> void:
	# Do not move while being possessed
	if current_state == State.BEING_POSSESSED:
		direction_this_physics_tick = Vector2.ZERO
		return

	if current_action == Action.WALK:
		decide_steering_or_not(delta)
		steering_counter(delta)
		# Follow the path directly if not steering
		if !steering:
			calculate_direction_this_physics_tick()

	handle_movement(direction_this_physics_tick)
#endregion

#region possession
## Starts the possession process for this NPC, making it switch to the "being possessed" state and play the corresponding animation. 
## The possession lasts for the specified duration, during which the NPC's sprite alternates between its normal and possessed appearances.
## The speed of the sprite switching accelerates over time, and a shaking effect is applied towards the end of the possession duration.
## TODO: Handle the case where the player sprays holy water on the ghost while it is possessing this NPC.
func start_possession(duration: float, possessed_by: Node2D) -> void:
	if current_state != State.BEING_POSSESSED:
		current_state = State.BEING_POSSESSED
		self.possessed_by = possessed_by
	else:
		return
	animation.play("being_possessed")

	var is_showing_possessed: bool = false
	var elapsed: float = 0.0

	var initial_interval: float = 0.28  # Initial interval (slow)
	var final_interval: float = 0.03    # Final interval (very fast)

	var original_offset: Vector2 = sprite.position

	while elapsed < duration:
		# Toggle between normal and possessed sprites
		is_showing_possessed = !is_showing_possessed
		sprite.texture = spriteset.possessed_sheet if is_showing_possessed else spriteset.normal_sheet

		var progress: float = clamp(elapsed / duration, 0.0, 1.0)

		# Quad In easing (progress^2) to accelerate towards the end
		# If you want to see some visualization, check this out: https://easings.net/#easeInQuad
		var eased_progress: float = progress * progress
		var current_interval: float = lerp(initial_interval, final_interval, eased_progress)

		# Some shaking effect towards the end of the possession duration
		if progress > 0.6:
			var shake_strength: float = lerp(0.0, 2.5, (progress - 0.6) / 0.4)
			sprite.position = original_offset + Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)

		await get_tree().create_timer(current_interval).timeout
		elapsed += current_interval

	sprite.texture = spriteset.possessed_sheet
	sprite.position = original_offset
	if current_state == State.BEING_POSSESSED:
		current_state = State.NORMAL
		possessed = true
#endregion

#region movement
func handle_movement(direction: Vector2) -> void:
	if direction:
		velocity = direction.normalized() * speed
		if current_state == State.NORMAL:
			current_state = State.WALK
			animation.play("walk")
	else:
		velocity = Vector2.ZERO
		# if not moving — play the idle animation
		if current_state == State.WALK:
			current_state = State.NORMAL
			animation.play("idle")

	# if moving left — flip the sprite horizontally
	if velocity.x:
		$Sprite2D.flip_h = velocity.x < 0

	move_and_slide()
#endregion

#region A* Pathfinding
## Ask the pathfinding manager for a path from current position to a random point on main floor.
func construct_a_path_on_mainfloor() -> void:
	var destination = GameManager.instance.dancer_walkable_area_scene.get_random_point()
	# The path is a list of Vector2 points
	path_to_destination = PathfindingManager.instance.find_path(global_position, destination)
	current_path_index = 0

## If the dancer is close enough to a checkpoint on the path, move to the next checkpoint
func select_next_checkpoint_on_path() -> void:
	if !path_to_destination or path_to_destination.size() <= 1:
		return

	if (current_path_index < path_to_destination.size() - 1):
		if (global_position.distance_to(path_to_destination[current_path_index]) < min_distance_for_index_change):
			current_path_index += 1
	else:
		action_goal_finished = true

## Move the dancer in the direction of the next checkpoint.
func calculate_direction_this_physics_tick() -> void:
	if !path_to_destination or path_to_destination.size() <= 1:
		return

	if current_path_index == path_to_destination.size() - 1:
		direction_this_physics_tick = Vector2.ZERO
	else:
		direction_this_physics_tick = path_to_destination[current_path_index] - global_position
#endregion

#region Steering
## If stuck (not moving for too long), steer towards a random angle to get unstuck
func decide_steering_or_not(delta: float) -> void:
	if global_position.distance_to(previous_position) < resting_distance:
		time_since_resting += delta
	else:
		time_since_resting = 0

	# Steer in a random direction if idle for longer than resting_time
	if time_since_resting > resting_time:
		steering = true
		var random_angle = deg_to_rad(randf_range(10, 350.0))
		direction_this_physics_tick = Vector2.RIGHT.rotated(random_angle)
		time_since_last_steering = 0
		time_since_resting = 0

	previous_position = global_position

## Steer for steering_duration, then return to normal pathfinding
func steering_counter(delta: float) -> void:
	time_since_last_steering += delta
	
	if time_since_last_steering >= steering_duration:
		steering = false
		time_since_last_steering = 0
#endregion

#region Decision Maker
## Start dancing
func start_dancing() -> void:
	current_state = State.DANCE
	animation.play("dance")

## Stop dancing and return to idle
func stop_dancing() -> void:
	if current_state == State.DANCE:
		current_state = State.NORMAL
		animation.play("idle")

## Randomly pick the next action (walk or start_dancing)
func choosing_next_action() -> void:
	current_action = Action.WALK if randi_range(0, 1) == 0 else Action.DANCE
	action_goal_finished = false
	if current_action == Action.DANCE:
		direction_this_physics_tick = Vector2.ZERO
		start_dancing()
		dancing_timer()
	else:
		construct_a_path_on_mainfloor()

## Dance for a random duration (5-15s), then finish the action
func dancing_timer() -> void:
	await get_tree().create_timer(randf_range(5, 15)).timeout
	action_goal_finished = true
	stop_dancing()
#endregion

#region Random Dialogue
func say_random_dialogue() -> void :
	talkable.say_text("Hello World!")

func _on_random_dialogue_timer_timeout() -> void:
	say_random_dialogue()
	random_dialogue_timer.start(randf_range(5.0, 20.0))

#endregion
