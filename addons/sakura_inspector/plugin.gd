@tool
extends EditorPlugin

var overlay_script = preload("res://addons/sakura_inspector/sakura_overlay.gd")
var overlay_node: Control

func _enter_tree() -> void:
	call_deferred("_setup_sakura")

func _setup_sakura() -> void:
	var base_control = EditorInterface.get_base_control()
	if not base_control:
		return

	var old = base_control.get_node_or_null("SakuraInspectorOverlay")
	if old:
		old.queue_free()

	overlay_node = Control.new()
	overlay_node.name = "SakuraInspectorOverlay"
	overlay_node.set_script(overlay_script)

	base_control.add_child(overlay_node)
	print("[SakuraPlugin] Sakura Overlay attached to base control & active!")

func _exit_tree() -> void:
	if is_instance_valid(overlay_node):
		overlay_node.queue_free()
