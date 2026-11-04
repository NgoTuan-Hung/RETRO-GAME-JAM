extends CharacterBody2D

@export var speed:float= 100.0
@export var direction:= Vector2(1, 0)
@export var change_time: float
@export var ray_length:= 40.0

var move_direction: Vector2
var dodge_direction: Vector2
var dodge_time: float

@onready var anime: AnimationPlayer = $AnimationPlayer
@onready var ray: RayCast2D = $RayCast2D
@onready var sprite: Sprite2D = $JanitorSprite

func _physics_process(delta: float) -> void:
	change_time -= delta
	if change_time <= 0:
		if randf() < 0.4:
			direction = Vector2.ZERO
		else:
			for i in range(4):
				direction.x = randf_range(-1, 1)
				direction.y = randf_range(-1, 1)
				ray.target_position = direction.normalized() * ray_length
				ray.force_raycast_update()
				if not ray.is_colliding():
					break
			if ray.is_colliding() == true:
				direction = Vector2.ZERO

		change_time = randf_range(1.0, 4.0)
	
	move_direction = direction
	
	if dodge_time > 0:
		dodge_time -= delta
		move_direction = dodge_direction
	
	elif direction != Vector2.ZERO:
		ray.target_position = direction.normalized() * ray_length
		ray.force_raycast_update()
		if ray.is_colliding():
			if ray.get_collider() is Player or NPC:
				for angle in [30, -30, 60, -60, 90, -90]:
					var test = direction.normalized().rotated(deg_to_rad(angle))
					ray.target_position = test * ray_length
					ray.force_raycast_update()
					if not ray.is_colliding():
						dodge_direction = test
						dodge_time = 0.4
						move_direction = test
						break
				if dodge_time <= 0:
					move_direction = Vector2.ZERO
			else:
				change_time = 0
	velocity = move_direction.normalized() * speed
	
	if move_direction == Vector2.ZERO:
		anime.play("idle")
	else:
		anime.play("walk")
	if move_direction.x < 0:
		sprite.flip_h = true
	if move_direction.x > 0:
		sprite.flip_h = false
	
	move_and_slide()
