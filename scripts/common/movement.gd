class_name Movement
extends Node

## Emitted when movement begins or stops
signal movement_started
signal movement_stopped

@export var move_speed: float = 100.0
@export var sprite: Sprite2D
@export var anim_tree: AnimationTree

@onready var actor: CharacterBody2D = get_parent()
var playback: AnimationNodeStateMachinePlayback

var movement_direction: Vector2 = Vector2.ZERO:
	set(value):
		var prev := movement_direction
		movement_direction = value.normalized() if value.length() > 1.0 else value
		if prev == Vector2.ZERO and movement_direction != Vector2.ZERO:
			movement_started.emit()
		elif prev != Vector2.ZERO and movement_direction == Vector2.ZERO:
			movement_stopped.emit()

func _ready() -> void:
	if actor:
		if not sprite:
			sprite = actor.find_child("*Sprite*", false) as Sprite2D
		if not anim_tree:
			anim_tree = actor.get_node_or_null("AnimationTree")

	if anim_tree:
		playback = anim_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback

## Physics loop: handles movement physics (equivalent to FixedUpdate in Unity)
func _physics_process(_delta: float) -> void:
	if not actor: return

	actor.velocity = movement_direction * move_speed
	actor.move_and_slide()

## Visual loop: handles facing and animation (equivalent to Update in Unity)
func _process(_delta: float) -> void:
	# Flip sprite horizontally (equivalent to transform.localScale in Movement.cs)
	if movement_direction.x != 0 and sprite:
		sprite.scale.x = -1.0 if movement_direction.x < 0 else 1.0

	# Update animation state machine (equivalent to Animator in Movement.cs)
	if not playback and anim_tree:
		playback = anim_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	if playback:
		playback.travel("walk" if movement_direction != Vector2.ZERO else "idle")

func set_movement_value(value: Vector2) -> void:
	movement_direction = value