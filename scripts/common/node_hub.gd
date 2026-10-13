class_name NodeHub
extends CharacterBody2D

## Central hub referencing child components and nodes.
## Allows child/grandchild nodes to communicate with each other through this hub.

@onready var movement: Movement = (get_node_or_null("Movement") if get_node_or_null("Movement") else find_child("Movement", false, false)) as Movement
@onready var sprite: Sprite2D = (get_node_or_null("Sprite2D") if get_node_or_null("Sprite2D") else find_child("*Sprite*", false, false)) as Sprite2D
@onready var anim_tree: AnimationTree = (get_node_or_null("AnimationTree") if get_node_or_null("AnimationTree") else find_child("AnimationTree", false, false)) as AnimationTree
@onready var anim_player: AnimationPlayer = (get_node_or_null("AnimationPlayer") if get_node_or_null("AnimationPlayer") else find_child("AnimationPlayer", false, false)) as AnimationPlayer
@onready var collision_shape: CollisionShape2D = (get_node_or_null("CollisionShape2D") if get_node_or_null("CollisionShape2D") else find_child("*Collision*", false, false)) as CollisionShape2D

var playback: AnimationNodeStateMachinePlayback:
	get:
		if playback == null and anim_tree != null:
			playback = anim_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
		return playback

func _ready() -> void:
	if anim_tree and playback == null:
		playback = anim_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
