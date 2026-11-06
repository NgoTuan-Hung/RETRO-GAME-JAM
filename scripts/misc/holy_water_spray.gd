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

@export var boogie_energy_drain: float = 10

func _ready() -> void:
	# Ensure the shape is a unique instance so it does not affect other spray instances
	hitbox.shape = hitbox.shape.duplicate()
	circle_shape = hitbox.shape as CircleShape2D
	area_entered.connect(_on_area_entered)

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

## Purify ghosts that enter the spray area
## TODO: Answer the question: Should the spray purify just one ghost at a time or all ghosts in the area? For now, it purifies all ghosts in the area.
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("ghost_hurt_box"):
		var ghost = area.get_parent() as Ghost
		if ghost.current_state != Ghost.State.APPEAR:
			# If the ghost is possessing an NPC, cancel the possession and purify the ghost in the direction of the holy water spray.
			# Otherwise, just purify the ghost in the direction of the holy water spray.
			if ghost.current_state == Ghost.State.POSSESS:
				ghost.cancel_possession_on_npc(ghost.global_position - global_position)
			else:
				ghost.purify(ghost.global_position - global_position)
	elif area.is_in_group("npc_hurt_box"):
		var npc = area.get_parent() as NPC
		if npc.possessed:
			npc.stop_possession()
			var ghost_effect = GameManager.instance.get_a_ghost_effect()
			ghost_effect.start_eject(npc.global_position, (npc.global_position - global_position).normalized(), npc.sprite.flip_h)
	elif area.is_in_group("boogie_woogie_hurt_box"):
		var boogie = area.get_parent() as BoogieWoogie
		boogie.filled -= boogie_energy_drain
