class_name Movement
extends Node

## Emitted when movement begins or stops
signal movement_started
signal movement_stopped

## Movement speed of the character
@export var move_speed: float = 100.0

## Ancestor hub reference
@onready var hub: NodeHub = get_parent() as NodeHub

## Current movement direction vector (normalized if length > 1)
var movement_direction: Vector2 = Vector2.ZERO:
	set(value):
		var prev := movement_direction
		movement_direction = value.normalized() if value.length() > 1.0 else value
		# Emit signal when starting to move
		if prev == Vector2.ZERO and movement_direction != Vector2.ZERO:
			movement_started.emit()
		# Emit signal when stopping
		elif prev != Vector2.ZERO and movement_direction == Vector2.ZERO:
			movement_stopped.emit()

## Handles character physics movement and velocity
func _physics_process(_delta: float) -> void:
	if not hub: return

	hub.velocity = movement_direction * move_speed
	hub.move_and_slide()

## Handles facing direction and animation state updates
func _process(_delta: float) -> void:
	if not hub: return

	# Flip sprite horizontally based on movement direction
	if movement_direction.x != 0 and hub.sprite:
		hub.sprite.scale.x = -1.0 if movement_direction.x < 0 else 1.0

	# Update animation state machine (walk while moving, idle when stationary)
	if hub.playback:
		hub.playback.travel("walk" if movement_direction != Vector2.ZERO else "idle")

## Sets the movement direction vector (typically called by an input handler or AI controller)
func set_movement_value(value: Vector2) -> void:
	movement_direction = value