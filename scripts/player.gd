class_name Player
extends CharacterBody2D

@onready var crosshair: Sprite2D = $Crosshair
@onready var sprite: Sprite2D = $PlayerSprite
@onready var animation: AnimationPlayer = $AnimationPlayer

signal talked(talkable: Talkable)

var is_aiming: bool = false

enum State { NORMAL, DRINK, SPRAY }
var current_state: State = State.NORMAL
var current_speed: float
var normal_speed: float = 100

func _ready() -> void :
	pass
	
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
	for body in $TalkArea.get_overlapping_bodies():
		print(body.name)
	$Talkable.say_text("Hello World! I just wanted to take a few seconds to say how happy I am to be here playing this game.")
	talked.emit()
