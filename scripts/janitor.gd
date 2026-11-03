extends CharacterBody2D

@export var speed:float= 100.0
@export var direction:= Vector2(1, 0)
@export var change_time: float
@export var ray_length:= 30.0

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
	
	if direction != Vector2.ZERO:
		ray.target_position = direction.normalized() * ray_length
		ray.force_raycast_update()
		if ray.is_colliding():
			change_time = 0
	velocity = direction.normalized() * speed
	
	if direction == Vector2.ZERO:
		anime.play("idle")
	else:
		anime.play("walk")
	if direction.x < 0:
		sprite.flip_h = true
	if direction.x > 0:
		sprite.flip_h = false
	
	move_and_slide()
