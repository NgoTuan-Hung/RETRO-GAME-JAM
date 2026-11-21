@tool
class_name Debugger
extends Node

## Drag and drop the Stool node from the Scene dock / Inspector here
@export var stool: Stool

@export_group("Actions")
## Inspector button to call the stool's customer_sit() method
@export_tool_button("Customer Sit", "Play")
var btn_customer_sit = trigger_customer_sit

## Fallback checkbox to trigger from Inspector while running in Play mode (Remote tab)
@export var trigger_customer_sit_toggle: bool = false:
	set(value):
		if value:
			trigger_customer_sit()

## Triggers customer_sit on the stool
func trigger_customer_sit() -> void:
	if not is_instance_valid(stool):
		push_warning("Debugger: No Stool assigned in Inspector or Stool node is invalid!")
		return

	if not stool.has_method("customer_sit"):
		push_error("Debugger: Object '%s' does not have a customer_sit() method!" % stool.name)
		return

	if "table" in stool and stool.table == null:
		push_warning("Debugger: Stool '%s' has no Table assigned in its Inspector!" % stool.name)

	if Engine.is_editor_hint() and (GameManager.instance == null or not is_instance_valid(GameManager.instance)):
		push_warning("Debugger: Currently in Editor mode (game not running), GameManager.instance is null. To fully test Bartender reaction, run the game (F5/F6)!")

	print("[Debugger] Calling stool.customer_sit() on node: %s" % stool.name)
	stool.customer_sit()
