## Represents a drink served by the bartender.
class_name SpiritBottle
extends Area2D

@export var textures: Array[Texture2D] = []
@onready var sprite: Sprite2D = $Sprite2D
var table: Table

func _ready() -> void:
    sprite.texture = textures.pick_random()

## Enable the drink with a random sprite each time it is spawned.
func enable() -> void:
    sprite.texture = textures.pick_random()
    process_mode = Node.PROCESS_MODE_INHERIT
    visible = true

func disable() -> void:
    process_mode = Node.PROCESS_MODE_DISABLED
    visible = false
    # Notify the table that the drink was removed (e.g., picked up by the player).
    table.forget_drink(self)
    table = null

## Store the table where this drink was spawned so it can be notified
## later if the player takes the drink.
func remember_table(table: Table) -> void:
    self.table = table