class_name SpiritBottle
extends Area2D

@export var textures: Array[Texture2D] = []
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
    sprite.texture = textures.pick_random()

func enable() -> void:
    sprite.texture = textures.pick_random()
    process_mode = Node.PROCESS_MODE_INHERIT
    visible = true

func disable() -> void:
    process_mode = Node.PROCESS_MODE_DISABLED
    visible = false