class_name Table
extends StaticBody2D

var left_customer: bool = false
var right_customer: bool = false
var customer_number: int = 0

var bottle_offset = 5

func _ready() -> void:
	pass

func order_drink(stool: Stool) -> void:
	GameManager.instance.bartender.take_order(self)
	if stool.global_position.x > global_position.x:
		right_customer = true
	else:
		left_customer = true

func place_drink_for_customer():
	if left_customer:
		var left_bottle = GameManager.instance.get_a_spirit_bottle()
		left_bottle.global_position = global_position + Vector2(-bottle_offset, 0)
	
	if right_customer:
		var right_bottle = GameManager.instance.get_a_spirit_bottle()
		right_bottle.global_position = global_position + Vector2(bottle_offset, 0)
