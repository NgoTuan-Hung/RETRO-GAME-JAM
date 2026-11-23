@tool
class_name CustomerSimulationDebugger
extends Node

## References to all tables in the bar.
## If left empty, they will be automatically discovered in _ready() or via the "Auto-Discover Tables" button.
@export var tables: Array[Table] = []

@export_group("Simulation Settings")
## Enable or pause the simulation.
@export var enabled: bool = true

## Minimum and maximum time (in seconds) before the next customer arrives (default: 0 - 15s).
@export_range(0.0, 60.0, 0.5) var min_arrival_interval: float = 0.0
@export_range(0.0, 60.0, 0.5) var max_arrival_interval: float = 10.0

## Minimum and maximum drinking duration (in seconds) before the customer leaves (default: 30 - 60s).
@export_range(1.0, 180.0, 1.0) var min_drinking_duration: float = 30.0
@export_range(1.0, 180.0, 1.0) var max_drinking_duration: float = 60.0

## Whether to automatically search for Table nodes in the scene tree on startup.
@export var auto_find_tables_on_ready: bool = true

## Print simulation logs to the Godot console.
@export var log_events: bool = true

@export_group("Monitoring")
## Seconds remaining until the next customer arrives.
@export var next_arrival_in: float = 0.0
## Number of customers currently sitting and drinking at tables.
@export var active_customers_count: int = 0

@export_group("Actions")
## Manually trigger a customer arrival immediately.
@export_tool_button("Spawn Customer Now", "Play")
var btn_spawn = spawn_customer

## Auto-discover all Table nodes in the scene and resolve their stools.
@export_tool_button("Auto-Discover Tables", "Search")
var btn_discover = auto_discover_tables

## Clear all currently sitting customers, calling stool.customer_leave() for each.
@export_tool_button("Clear All Customers", "Stop")
var btn_clear = clear_all_sitting_customers

@export_group("Remote Inspector Fallbacks")
## Toggle in Remote inspector during Play mode to manually spawn a customer.
@export var trigger_spawn_customer_toggle: bool = false:
	set(value):
		if value:
			spawn_customer()

## Toggle in Remote inspector during Play mode to clear all sitting customers.
@export var trigger_clear_customers_toggle: bool = false:
	set(value):
		if value:
			clear_all_sitting_customers()

# Internal class to track individual sitting customers
class SittingCustomer:
	var customer_id: int
	var table: Table
	var stool: Stool
	var is_right_stool: bool
	var remaining_time: float
	var total_duration: float

	func _init(p_id: int, p_table: Table, p_stool: Stool, p_is_right: bool, p_duration: float) -> void:
		customer_id = p_id
		table = p_table
		stool = p_stool
		is_right_stool = p_is_right
		remaining_time = p_duration
		total_duration = p_duration

var _time_until_next_arrival: float = 0.0
var _sitting_customers: Array[SittingCustomer] = []
var _customer_counter: int = 0


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if auto_find_tables_on_ready or tables.is_empty():
		auto_discover_tables()

	_schedule_next_arrival()

	if log_events:
		print("[CustomerSim] Initialized with %d tables. First arrival scheduled in %.2fs." % [
			tables.size(),
			_time_until_next_arrival
		])


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# 1. Update sitting customers drinking timer
	_process_sitting_customers(delta)

	# 2. Arrival timer
	if not enabled:
		return

	_time_until_next_arrival -= delta
	next_arrival_in = max(0.0, _time_until_next_arrival)

	if _time_until_next_arrival <= 0.0:
		spawn_customer()
		_schedule_next_arrival()


## Schedules the next customer arrival randomly between min_arrival_interval and max_arrival_interval
func _schedule_next_arrival() -> void:
	var low = min(min_arrival_interval, max_arrival_interval)
	var high = max(min_arrival_interval, max_arrival_interval)
	_time_until_next_arrival = randf_range(low, high)
	next_arrival_in = _time_until_next_arrival


## Handles a customer arrival:
## Iterates randomly through tables to find one with an empty seat (left_customer == false or right_customer == false).
## Randomly selects an available stool (left or right) and calls customer_sit().
## Starts drinking timer for 30-60s before calling table.customer_left().
func spawn_customer() -> void:
	if Engine.is_editor_hint() and (GameManager.instance == null or not is_instance_valid(GameManager.instance)):
		push_warning("[CustomerSim] Editor mode: GameManager.instance is null. Run the game (F5/F6) to test full simulation!")
		return

	if tables.is_empty():
		auto_discover_tables()
		if tables.is_empty():
			push_warning("[CustomerSim] No tables found to seat customer!")
			return

	_customer_counter += 1
	var cid = _customer_counter

	# Shuffle tables to iterate through them randomly
	var shuffled_tables: Array[Table] = []
	for t in tables:
		if is_instance_valid(t):
			_resolve_stools_for_table(t)
			shuffled_tables.append(t)
	shuffled_tables.shuffle()

	var selected_table: Table = null
	for t in shuffled_tables:
		if not t.left_customer or not t.right_customer:
			selected_table = t
			break

	if selected_table == null:
		if log_events:
			print("[CustomerSim] Customer #%d arrived, but all tables are occupied. Customer left." % cid)
		return

	# Determine open seats on the selected table
	var available_seats: Array[bool] = [] # false = left, true = right
	if not selected_table.left_customer:
		available_seats.append(false)
	if not selected_table.right_customer:
		available_seats.append(true)

	if available_seats.is_empty():
		return

	# Choose randomly between open seats
	var choose_right: bool = available_seats.pick_random()
	var stool_side: String = "right" if choose_right else "left"
	var target_stool: Stool = selected_table.right_stool if choose_right else selected_table.left_stool

	# Call stool.customer_sit() on the chosen stool
	if target_stool != null:
		target_stool.customer_sit()
	else:
		# Fallback if stool wasn't assigned or found
		selected_table.order_drink(choose_right)

	# Simulate drinking duration (30 - 60s)
	var low_drink = min(min_drinking_duration, max_drinking_duration)
	var high_drink = max(min_drinking_duration, max_drinking_duration)
	var drinking_duration = randf_range(low_drink, high_drink)

	var sitting_customer = SittingCustomer.new(cid, selected_table, target_stool, choose_right, drinking_duration)
	_sitting_customers.append(sitting_customer)
	active_customers_count = _sitting_customers.size()

	if log_events:
		print("[CustomerSim] Customer #%d sat at %s (%s stool). Drinking for %.1fs." % [
			cid,
			selected_table.name,
			stool_side,
			drinking_duration
		])


## Triggers customer leaving through their corresponding stool (or table fallback).
func _customer_leave(customer: SittingCustomer) -> void:
	if is_instance_valid(customer.stool):
		customer.stool.customer_leave()
	elif is_instance_valid(customer.table):
		var fallback_stool = customer.table.right_stool if customer.is_right_stool else customer.table.left_stool
		if is_instance_valid(fallback_stool):
			fallback_stool.customer_leave()
		else:
			customer.table.customer_leave(customer.is_right_stool)


## Decrements customer drinking timers and triggers stool.customer_leave() when time is up.
func _process_sitting_customers(delta: float) -> void:
	for i in range(_sitting_customers.size() - 1, -1, -1):
		var c = _sitting_customers[i]
		if not is_instance_valid(c.table):
			_sitting_customers.remove_at(i)
			continue

		# Check if seat was cleared externally
		var seat_occupied = c.table.right_customer if c.is_right_stool else c.table.left_customer
		if not seat_occupied:
			_sitting_customers.remove_at(i)
			continue

		c.remaining_time -= delta
		if c.remaining_time <= 0.0:
			var side = "right" if c.is_right_stool else "left"
			_customer_leave(c)
			if log_events:
				print("[CustomerSim] Customer #%d finished drinking and left %s (%s stool) after %.1fs." % [
					c.customer_id,
					c.table.name,
					side,
					c.total_duration
				])
			_sitting_customers.remove_at(i)

	active_customers_count = _sitting_customers.size()


## Clears all sitting customers immediately.
func clear_all_sitting_customers() -> void:
	for c in _sitting_customers:
		_customer_leave(c)
	_sitting_customers.clear()
	active_customers_count = 0
	if log_events:
		print("[CustomerSim] All sitting customers cleared.")


## Automatically locates all Table nodes in the scene tree and resolves their stools.
func auto_discover_tables() -> void:
	tables.clear()
	var search_root: Node = null

	if get_tree() and get_tree().current_scene:
		search_root = get_tree().current_scene
	elif owner:
		search_root = owner
	elif get_parent():
		search_root = get_parent()
	else:
		search_root = self

	_find_tables_recursive(search_root)

	for t in tables:
		_resolve_stools_for_table(t)

	if log_events:
		print("[CustomerSim] Auto-discovered %d tables." % tables.size())


func _find_tables_recursive(node: Node) -> void:
	if node is Table and not tables.has(node):
		tables.append(node)
	for child in node.get_children():
		_find_tables_recursive(child)


## Resolves left_stool and right_stool references on a Table if they are not already set.
func _resolve_stools_for_table(table: Table) -> void:
	if not is_instance_valid(table):
		return

	if table.left_stool != null and table.right_stool != null:
		return

	var parent = table.get_parent()
	if parent == null:
		return

	var candidate_stools: Array[Stool] = []
	for child in parent.get_children():
		if child is Stool:
			if child.table == table or child.global_position.distance_to(table.global_position) < 60.0:
				candidate_stools.append(child)

	for stool in candidate_stools:
		if stool.global_position.x < table.global_position.x:
			if table.left_stool == null:
				table.left_stool = stool
		elif stool.global_position.x > table.global_position.x:
			if table.right_stool == null:
				table.right_stool = stool
