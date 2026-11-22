class_name Table
extends StaticBody2D

var left_customer: bool = false
var right_customer: bool = false
var left_drink: SpiritBottle = null
var right_drink: SpiritBottle = null
var customer_number: int = 0

@export var left_stool: Stool
@export var right_stool: Stool

var bottle_offset = 5

func _ready() -> void:
	pass

func order_drink(right_stool: bool) -> void:
	GameManager.instance.bartender.take_order(self)
	if right_stool:
		right_customer = true
	else:
		left_customer = true

func customer_left(right_stool: bool) -> void:
	if right_stool:
		right_customer = false
	else:
		left_customer = false

func place_drink_for_customer():
	if left_customer && not left_drink:
		left_drink = GameManager.instance.get_a_spirit_bottle()
		left_drink.global_position = global_position + Vector2(-bottle_offset, 0)
	
	if right_customer && not right_drink:
		right_drink = GameManager.instance.get_a_spirit_bottle()
		right_drink.global_position = global_position + Vector2(bottle_offset, 0)

func clean_table():
	if left_drink:
		left_drink.disable()

	if right_drink:
		right_drink.disable()		
