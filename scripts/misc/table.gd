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
	var order

	if right_stool:
		right_customer = true
		order = Order.new(self, false, true)
	else:
		left_customer = true
		order = Order.new(self, true, false)

	GameManager.instance.bartender.take_order(order)

func customer_leave(right_stool: bool) -> void:
	var clean_table_request

	if right_stool:
		right_customer = false
		clean_table_request = CleanTableRequest.new(self, false, true)
	else:
		left_customer = false
		clean_table_request = CleanTableRequest.new(self, true, false)

	GameManager.instance.bartender.note_clean_table(clean_table_request)

func place_drink_for_customer(order: Order):
	if order.order_from_left && not left_drink:
		left_drink = GameManager.instance.get_a_spirit_bottle()
		left_drink.remember_table(self)
		left_drink.global_position = global_position + Vector2(-bottle_offset, 0)
	
	if order.order_from_right && not right_drink:
		right_drink = GameManager.instance.get_a_spirit_bottle()
		right_drink.remember_table(self)
		right_drink.global_position = global_position + Vector2(bottle_offset, 0)

func clean_table(clean_table_request: CleanTableRequest):
	if clean_table_request.request_from_left and left_drink:
		left_drink.disable()

	if clean_table_request.request_from_right and right_drink:
		right_drink.disable()

func forget_drink(drink: SpiritBottle):
	if drink == left_drink:
		left_drink = null
	elif drink == right_drink:
		right_drink = null
