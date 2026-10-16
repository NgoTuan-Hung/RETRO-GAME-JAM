class_name GameManager
extends Node

static var instance: GameManager
@export var player: Node2D
@export var hud: Node

func _enter_tree() -> void:
	instance = self
