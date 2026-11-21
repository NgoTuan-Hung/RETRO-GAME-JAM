class_name Stool
extends StaticBody2D

@export var table: Table

func _ready() -> void:
    pass

func customer_sit() -> void:
    table.order_drink(self)