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

## Create a drink order for the bartender for this table, recording whether
## the customer is on the left or right stool so the drink is placed on the correct side.
func order_drink(right_stool: bool) -> void:
	var order

	if right_stool:
		right_customer = true
		order = Order.new(self, false, true)
	else:
		left_customer = true
		order = Order.new(self, true, false)

	GameManager.instance.bartender.take_order(order)

## Create a table-cleaning request for the bartender when a customer leaves,
## recording which side they sat on so the correct drink is cleared.
func customer_leave(right_stool: bool) -> void:
	var clean_table_request

	if right_stool:
		right_customer = false
		clean_table_request = CleanTableRequest.new(self, false, true)
	else:
		left_customer = false
		clean_table_request = CleanTableRequest.new(self, true, false)

	GameManager.instance.bartender.note_clean_table(clean_table_request)

## Called by the bartender upon reaching the table to serve; spawns and places
## drinks on the corresponding side(s) based on the order.
func place_drink_for_customer(order: Order):
	if order.order_from_left && not left_drink:
		left_drink = GameManager.instance.get_a_spirit_bottle()
		left_drink.remember_table(self)
		left_drink.global_position = global_position + Vector2(-bottle_offset, 0)
	
	if order.order_from_right && not right_drink:
		right_drink = GameManager.instance.get_a_spirit_bottle()
		right_drink.remember_table(self)
		right_drink.global_position = global_position + Vector2(bottle_offset, 0)

## Called by the bartender upon reaching the table to clean; disables any
## remaining drinks on the side(s) specified in the request.
func clean_table(clean_table_request: CleanTableRequest):
	if clean_table_request.request_from_left and left_drink:
		left_drink.disable()

	if clean_table_request.request_from_right and right_drink:
		right_drink.disable()

## Clear this table's reference to the given drink (e.g., when it is disabled or picked up).
func forget_drink(drink: SpiritBottle):
	if drink == left_drink:
		left_drink = null
	elif drink == right_drink:
		right_drink = null
