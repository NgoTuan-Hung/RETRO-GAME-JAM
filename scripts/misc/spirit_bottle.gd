class_name SpiritBottle
extends Area2D

@export var textures: Array[Texture2D] = []
@onready var sprite: Sprite2D = $Sprite2D
var table: Table

func _ready() -> void:
    sprite.texture = textures.pick_random()

func enable() -> void:
    sprite.texture = textures.pick_random()
    process_mode = Node.PROCESS_MODE_INHERIT
    visible = true

func disable() -> void:
    process_mode = Node.PROCESS_MODE_DISABLED
    visible = false
    table.forget_drink(self)
    table = null

func remember_table(table: Table) -> void:
    self.table = table