extends CharacterBody2D

@export var speed:float= 100.0
@export var direction:= Vector2(1, 0)
@export var change_time: float
func _physics_process(delta: float) -> void:
	change_time -= delta
	if change_time <= 0:
		if randf() < 0.3:
			direction = Vector2.ZERO
		else:
			direction.x = randf_range(-1, 1)
			direction.y = randf_range(-1, 1)
		
		change_time = randf_range(1.0, 4.0)
		
	velocity = direction.normalized() * speed
	
	move_and_slide()
