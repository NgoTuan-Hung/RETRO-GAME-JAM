class_name HolyWaterSpray
extends Area2D

@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D
var circle_shape: CircleShape2D

## Maximum spray distance (matches how far particles travel)
@export var max_distance: float = 80.0
## Spray duration in seconds (matches particle lifetime)
@export var duration: float = 0.5
@export var max_radius: float = 22.0	

var spray_tween: Tween

func _ready() -> void:
	# Ensure the shape is a unique instance so it does not affect other spray instances
	hitbox.shape = hitbox.shape.duplicate()
	circle_shape = hitbox.shape as CircleShape2D

func fire(global_position: Vector2, fire_angle: float) -> void:
	visible = true
	self.global_position = global_position
	rotation = fire_angle

	# Initial state: small hitbox right at the nozzle
	hitbox.position = Vector2.ZERO
	circle_shape.radius = 0.0

	# Emit spray particles
	particles.restart()
	particles.emitting = true

	if spray_tween and spray_tween.is_valid():
		spray_tween.kill() 

	# Animate collider using Tween
	spray_tween = create_tween().set_parallel(true)

	# 1. Move forward: starts fast and gradually decelerates (EASE_OUT mimicking damping)
	spray_tween.tween_property(hitbox, "position:x", max_distance, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Expand gradually: grows from 6px to 22px radius to cover the mist cone
	spray_tween.tween_property(circle_shape, "radius", max_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Auto-disable when spray duration ends
	await get_tree().create_timer(duration).timeout
	disable()

func enable() -> void:
	process_mode = ProcessMode.PROCESS_MODE_INHERIT

func disable() -> void:
	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	visible = false

# func _on_body_entered(body: Node2D) -> void:
# 	# When hitting a ghost directly
# 	if body is Ghost:
# 		print("Hit ghost with holy water!")
# 		# Call ghost purification or disable method
# 		if body.has_method("purify"):
# 			body.purify()
# 		elif body.has_method("temporary_disable"):
# 			body.temporary_disable()

# 	# (Optional) If hitting a possessed NPC
# 	if body is NPC and body.possessed:
# 		print("Purifying possessed NPC!")
# 		# body.exorcise() ...
