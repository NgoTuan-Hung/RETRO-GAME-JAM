class_name GameManager
extends Node

static var instance: GameManager
@export var player: Node2D
@export var hud: Node
@export var giving_track_point: Node2D

@export var ghost_scene: PackedScene
var ghost_targets: Array[Node2D] = []
@export var dancer_walkable_area_scene: DancerWalkableArea
var reusable_ghost: Array[Node] = []

enum BW_state { ACTIVE, APPEARING, DISAPPEARING, SUMMONING, HIBERNATING }
var BW_current_state := BW_state.HIBERNATING

signal BW_APPEARING
signal BW_DISAPPEARING

func _enter_tree() -> void:
	instance = self

## Ghost need to chase after the player or the npcs so for now
## we will add whatever that is player or npc to this array.
func register_as_ghost_target(target: Node2D) -> void:
	ghost_targets.append(target)

## Self-explanatory
func get_a_random_target_for_ghost() -> Node2D:
	return ghost_targets.pick_random()

func get_next_target_for_ghost(skip_player: bool = false) -> Node2D:
	for target in ghost_targets:
		if target is Player:
			if skip_player:
				continue
			else:
				return target
		elif target is NPC:
			if target.possessed || target.current_state == NPC.State.BEING_POSSESSED:
				continue
			else: return target

	return player # If there are really nothing else we can choose, comeback to player

## Get the ghost_scene from game manager and instantiate it
## , the ghost is reusable if it's disabled
func get_a_ghost() -> Node:
	for ghost in reusable_ghost:
		if ghost.process_mode == ProcessMode.PROCESS_MODE_DISABLED:
			ghost.enable()
			return ghost

	var ghost = ghost_scene.instantiate()
	get_tree().current_scene.add_child(ghost)
	reusable_ghost.append(ghost)
	return ghost

func get_bwstate() -> BW_state :
	return BW_current_state

func bw_state_active() -> void :
	BW_current_state = BW_state.ACTIVE

func bw_state_appearing() -> void :
	BW_current_state = BW_state.APPEARING
	BW_APPEARING.emit()

func bw_state_disappearing() -> void :
	BW_current_state = BW_state.DISAPPEARING
	BW_DISAPPEARING.emit()

func bw_state_hibernating() -> void :
	BW_current_state = BW_state.HIBERNATING

func bw_state_summoning() -> void :
	BW_current_state = BW_state.SUMMONING
