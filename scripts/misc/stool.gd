class_name Stool
extends StaticBody2D

@export var table: Table

func _ready() -> void:
    pass

## Notify the associated table that a customer has sat on this stool.
func customer_sit() -> void:
    table.order_drink(global_position.x > table.global_position.x)

## Notify the associated table that a customer has left this stool.
func customer_leave() -> void:
    table.customer_leave(global_position.x > table.global_position.x)