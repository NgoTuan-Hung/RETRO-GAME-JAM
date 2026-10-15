class_name GameManager
extends Node

static var instance: GameManager
@export var player: Node2D

func _enter_tree() -> void:
	instance = self
