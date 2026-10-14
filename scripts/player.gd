extends CharacterBody2D

const SPEED = 100.0
@onready var crosshair: Sprite2D = $Crosshair
@onready var sprite: Sprite2D = $PlayerSprite

var is_aiming: bool = false
var is_spraying: bool = false

func _physics_process(delta: float) -> void:
	handle_drink_input()
	handle_aim_and_spray_input()
	handle_movement()
	
	move_and_slide()

func handle_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction * SPEED
		# if  moving — play the walk animation
		$AnimationPlayer.play("walk")
	else:
		velocity = Vector2.ZERO
		# if not moving — play the idle animation
		$AnimationPlayer.play("idle")

	if is_aiming:
		var mouse_pos := get_global_mouse_position()
		sprite.flip_h = mouse_pos.x < global_position.x
	else:
		# if moving left — flip the sprite horizontally
		if velocity.x :
			$PlayerSprite.flip_h = velocity.x < 0

func handle_drink_input() -> void:
	if Input.is_action_just_pressed("drink"):
		print("Drinking...")
		# TODO: actual logic for drinking

func handle_aim_and_spray_input() -> void:
	is_aiming = Input.is_action_pressed("aim")

	if is_aiming:
		crosshair.visible = true
		crosshair.global_position = get_global_mouse_position()
		
		if Input.is_action_just_pressed("spray") and not is_spraying:
			spray_holy_water()
	else:
		crosshair.visible = false

func spray_holy_water() -> void:
	is_spraying = true

	print("Spraying...")

	# TODO: actual logic for spraying
	# we should wait sometime for the animation to finish
	await get_tree().create_timer(0.5).timeout
	is_spraying = false
