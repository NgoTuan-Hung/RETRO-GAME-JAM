class_name Player
extends CharacterBody2D

@onready var crosshair: Sprite2D = $Crosshair
@onready var sprite: Sprite2D = $PlayerSprite
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var my_talkable : Talkable = $Talkable

const SIGHT_MASK := 1 << 1

signal talked(talkable: Talkable)
signal resistance_changed(current_value: float, max_value: float)
signal resistance_depleted()

@export var max_resistance: float = 100.0
@export var current_resistance: float = 100.0

var is_aiming: bool = false

enum State { NORMAL, DRINK, SPRAY }
var current_state: State = State.NORMAL
var current_speed: float
var normal_speed: float = 100

func _ready() -> void:
	sync_resistance_ui.call_deferred()
	GameManager.instance.register_as_ghost_target(self)
	
func _physics_process(delta: float) -> void:
	handle_drink_input()
	handle_aim_and_spray_input()
	handle_movement()
	
	move_and_slide()

func handle_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	current_speed = normal_speed
	if current_state != State.NORMAL:
		current_speed = normal_speed * 0.1 # Slow down when drinking or spraying

	if direction:
		velocity = direction * current_speed
		# if  moving — play the walk animation
		# only play the walk animation if we are in the normal state
		if current_state == State.NORMAL:
			animation.play("walk")
	else:
		velocity = Vector2.ZERO
		# if not moving — play the idle animation
		# only play the idle animation if we are in the normal state
		if current_state == State.NORMAL:
			animation.play("idle")

	if is_aiming:
		var mouse_pos := get_global_mouse_position()
		sprite.flip_h = mouse_pos.x < global_position.x
	else:
		# if moving left — flip the sprite horizontally
		if velocity.x :
			$PlayerSprite.flip_h = velocity.x < 0

func handle_drink_input() -> void:
	if Input.is_action_just_pressed("drink") and current_state == State.NORMAL:
		start_drinking()

func start_drinking() -> void:
	current_state = State.DRINK
	animation.play("drink")

	# wait 0.5s for the animation to finish
	await get_tree().create_timer(0.5).timeout

	current_state = State.NORMAL

func handle_aim_and_spray_input() -> void:
	is_aiming = Input.is_action_pressed("aim")

	if is_aiming:
		crosshair.visible = true
		crosshair.global_position = get_global_mouse_position()
		
		if Input.is_action_just_pressed("spray") and current_state == State.NORMAL:
			spray_holy_water()
	else:
		crosshair.visible = false

func spray_holy_water() -> void:
	current_state = State.SPRAY
	animation.play("spray")

	# wait 0.5s for the animation to finish
	await get_tree().create_timer(0.5).timeout

	current_state = State.NORMAL

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Talk"):
		talk()

func talk() -> void :
	var closest : Node2D = null
	var distance : float = INF
	for body in $TalkArea.get_overlapping_bodies():
		if body == self:
			continue
		if has_line_of_sight(self, body) :
			print(body.name)
			var d := self.global_position.distance_to(body.global_position)
			if d < distance :
				closest = body
				distance = d
	$Talkable.say_text("Hello World!")
	if closest :
		print("closest = " + closest.name + " : distance : " + str(distance))
	talked.emit()

func has_line_of_sight(from: Node2D, to: Node2D) -> bool :
	var space_state = get_world_2d().direct_space_state
	# use global coordinates, not local to node
	var query = PhysicsRayQueryParameters2D.create(from.global_position, to.global_position)
	query.collision_mask = SIGHT_MASK
	query.exclude = [from.get_rid, to.get_rid]
	var result = space_state.intersect_ray(query)
	if len(result) == 0 :
		return true
	return false

#region Resistance Meter Handlers
func sync_resistance_ui() -> void:
	resistance_changed.emit(current_resistance, max_resistance)
	GameManager.instance.hud.update_resistance(current_resistance, max_resistance)

func reduce_resistance(amount: float) -> void:
	if current_resistance <= 0.0:
		return
	current_resistance = max(0.0, current_resistance - amount)
	sync_resistance_ui()
	if current_resistance <= 0.0:
		resistance_depleted.emit()

func restore_resistance(amount: float) -> void:
	current_resistance = min(max_resistance, current_resistance + amount)
	sync_resistance_ui()

func set_resistance(value: float) -> void:
	current_resistance = clamp(value, 0.0, max_resistance)
	sync_resistance_ui()
	if current_resistance <= 0.0:
		resistance_depleted.emit()
#endregion
