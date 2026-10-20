class_name GameManager
extends Node

static var instance: GameManager
@export var player: Node2D
@export var hud: Node
@export var giving_track_point: Node2D

@export var ghost_scene: PackedScene
var ghost_targets: Array[Node2D] = []

func _enter_tree() -> void:
	instance = self

## Ghost need to chase after the player or the npcs so for now
## we will add whatever that is player or npc to this array.
func register_as_ghost_target(target: Node2D) -> void:
	ghost_targets.append(target)

## Self-explanatory
func get_a_random_target_for_ghost() -> Node2D:
	return ghost_targets.pick_random()
