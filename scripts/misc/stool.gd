class_name Stool
extends StaticBody2D

@export var table: Table

func _ready() -> void:
    pass

func customer_sit() -> void:
    table.order_drink(global_position.x > table.global_position.x)

func customer_leave() -> void:
    table.customer_leave(global_position.x > table.global_position.x)