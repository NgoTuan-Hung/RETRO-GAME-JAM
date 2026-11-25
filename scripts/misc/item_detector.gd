## Detects nearby spirit bottles for the player and highlights the closest one with a selection arrow.
class_name ItemDetector
extends Area2D

@export var selection_arrow_packed_scene: PackedScene
var selection_arrow: Node2D
var nearest_bottle_distance: float = INF
var nearest_bottle: SpiritBottle = null

var detected_bottles: Array[SpiritBottle] = []

func _ready() -> void:
	selection_arrow = selection_arrow_packed_scene.instantiate()
	selection_arrow.visible = false
	get_tree().current_scene.add_child.call_deferred(selection_arrow)
	pass

func _process(delta: float) -> void:
	nearest_bottle_distance = INF
	nearest_bottle = null

	# Find the closest detected bottle and place the selection arrow above it
	for bottle in detected_bottles:
		var distance = global_position.distance_to(bottle.global_position)
		if distance < nearest_bottle_distance:
			nearest_bottle_distance = distance
			nearest_bottle = bottle
			selection_arrow.visible = true
			selection_arrow.global_position = nearest_bottle.global_position - Vector2(0, 35)

## Track spirit bottles that enter the player's detection area.
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("spirit_bottle"):
		if area not in detected_bottles:
			detected_bottles.append(area)

## Stop tracking spirit bottles that leave the detection area, hiding the arrow if it was the nearest one.
func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("spirit_bottle"):
		if area == nearest_bottle:
			nearest_bottle = null
			nearest_bottle_distance = INF
			selection_arrow.visible = false
		detected_bottles.erase(area)
