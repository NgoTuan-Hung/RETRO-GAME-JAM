class_name GhostEffect
extends Node2D

@export var fly_distance: float = 80.0
@export var duration: float = 0.6
@onready var sprite: Sprite2D = $Sprite2D

func start_eject(start_pos: Vector2, eject_direction: Vector2, flipped_h: bool) -> void:
	global_position = start_pos
	modulate = Color(1, 1, 1, 1)
	sprite.flip_h = flipped_h
	scale = Vector2.ONE

	var target_pos = start_pos + eject_direction * fly_distance

	var tween = create_tween().set_parallel(true)

	# 1. Bay nhanh lúc đầu, chậm dần về cuối (EASE_OUT)
	tween.tween_property(self, "global_position", target_pos, duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	# 2. Fade out hoàn toàn
	tween.tween_property(self, "modulate:a", 0.0, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	# 3. Phóng to nhẹ như làn khói loãng dần
	tween.tween_property(self, "scale", scale * 1.3, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	# Xong tween thì giải phóng node
	await tween.finished
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false

func enable() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
