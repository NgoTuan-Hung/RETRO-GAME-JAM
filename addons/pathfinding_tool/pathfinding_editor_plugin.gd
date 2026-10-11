@tool
extends EditorPlugin

## Interactive Canvas Editor for PathfindingGridDebugger.
## Replicates Unity Editor pathfinding visualizer & editor.

enum EditToolMode { VIEW, SET_START, SET_GOAL, ADD_OBSTACLE, REMOVE_OBSTACLE }
enum DrawShapeMode { PEN, BOX }

var current_mode: EditToolMode = EditToolMode.VIEW
var current_shape: DrawShapeMode = DrawShapeMode.PEN

var debugger: PathfindingGridDebugger = null
var toolbar: HBoxContainer = null

# UI Controls
var mode_button_group: ButtonGroup = ButtonGroup.new()
var shape_button_group: ButtonGroup = ButtonGroup.new()
var shape_container: HBoxContainer = null
var status_label: Label = null

# Input Tracking
var is_mouse_down: bool = false
var is_box_dragging: bool = false
var box_start_cell: Vector2i = Vector2i.ZERO
var box_current_cell: Vector2i = Vector2i.ZERO
var last_painted_cell: Vector2i = Vector2i(-1, -1)

# Undo / Redo tracking for Pen strokes
var pen_pre_stroke_blocked: Array[Vector2i] = []
var pen_stroke_modified: bool = false

func _enter_tree() -> void:
	_build_toolbar()

func _exit_tree() -> void:
	if toolbar:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar)
		toolbar.queue_free()
		toolbar = null

func _handles(object: Object) -> bool:
	if object is PathfindingGridDebugger:
		return true
	if object is Node2D:
		var script = object.get_script()
		if script != null:
			if script.resource_path == "res://scripts/pathfinding/pathfinding_grid_debugger.gd":
				return true
			if script.get_global_name() == &"PathfindingGridDebugger":
				return true
	return false

func _edit(object: Object) -> void:
	if debugger and debugger != object:
		debugger.hovered_cell = Vector2i(-1, -1)
		debugger.is_box_dragging = false
		debugger.queue_redraw()
	debugger = object as PathfindingGridDebugger
	if toolbar:
		toolbar.visible = (debugger != null)
		if debugger != null:
			# Auto switch to 2D viewport so toolbar and grid are immediately visible
			EditorInterface.set_main_screen_editor("2D")
			_update_status_label()

func _make_visible(visible: bool) -> void:
	if toolbar:
		toolbar.visible = visible and (debugger != null)

func _build_toolbar() -> void:
	toolbar = HBoxContainer.new()
	toolbar.name = "PathfindingToolbar"
	toolbar.visible = false

	# Title separator
	var sep1 := VSeparator.new()
	toolbar.add_child(sep1)

	var title := Label.new()
	title.text = "Pathfinding Tool:"
	toolbar.add_child(title)

	# Mode Buttons
	var modes := [
		{"id": EditToolMode.VIEW, "label": "👁 View", "tip": "Default view mode (Pan / Zoom)"},
		{"id": EditToolMode.SET_START, "label": "🟢 Start", "tip": "Click on grid cell to set Start Point"},
		{"id": EditToolMode.SET_GOAL, "label": "🎯 Goal", "tip": "Click on grid cell to set Goal Point"},
		{"id": EditToolMode.ADD_OBSTACLE, "label": "🧱 Wall", "tip": "Paint walls / obstacles (Hold Shift to quickly toggle Pen ↔ Box)"},
		{"id": EditToolMode.REMOVE_OBSTACLE, "label": "🧹 Erase", "tip": "Erase walls / obstacles (Hold Shift to quickly toggle Pen ↔ Box)"}
	]

	for m in modes:
		var btn := Button.new()
		btn.text = m["label"]
		btn.tooltip_text = m["tip"]
		btn.toggle_mode = true
		btn.button_group = mode_button_group
		if m["id"] == EditToolMode.VIEW:
			btn.button_pressed = true
		btn.pressed.connect(func(): _on_mode_selected(m["id"]))
		toolbar.add_child(btn)

	# Shape Container (Pen vs Box)
	shape_container = HBoxContainer.new()
	var sep_shape := VSeparator.new()
	shape_container.add_child(sep_shape)

	var pen_btn := Button.new()
	pen_btn.text = "✏ Pen"
	pen_btn.tooltip_text = "✏ Pen: Freehand paint/erase individual cells (Hold Shift while painting to switch to Box)"
	pen_btn.toggle_mode = true
	pen_btn.button_group = shape_button_group
	pen_btn.button_pressed = true
	pen_btn.pressed.connect(func(): current_shape = DrawShapeMode.PEN)
	shape_container.add_child(pen_btn)

	var box_btn := Button.new()
	box_btn.text = "📦 Box"
	box_btn.tooltip_text = "📦 Box: Click & drag to create rectangular area (Hold Shift to switch to Pen. Press Escape to cancel)"
	box_btn.toggle_mode = true
	box_btn.button_group = shape_button_group
	box_btn.pressed.connect(func(): current_shape = DrawShapeMode.BOX)
	shape_container.add_child(box_btn)

	shape_container.visible = false
	toolbar.add_child(shape_container)

	# Actions
	var sep_act := VSeparator.new()
	toolbar.add_child(sep_act)

	var find_btn := Button.new()
	find_btn.text = "▶ Find Path"
	find_btn.tooltip_text = "Calculate A* path between Start and Goal immediately"
	find_btn.pressed.connect(_on_find_path_pressed)
	toolbar.add_child(find_btn)

	var scan_btn := Button.new()
	scan_btn.text = "🔍 Scan Colliders"
	scan_btn.tooltip_text = "Scan 2D physics colliders in scene to automatically generate walls (Supports Undo / Redo)"
	scan_btn.pressed.connect(_on_scan_colliders_pressed)
	toolbar.add_child(scan_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear Walls"
	clear_btn.tooltip_text = "Clear all walls on grid (Supports Undo / Redo)"
	clear_btn.pressed.connect(_on_clear_walls_pressed)
	toolbar.add_child(clear_btn)

	var save_btn := Button.new()
	save_btn.text = "💾 Save"
	save_btn.tooltip_text = "Save grid data to res://data/pathfinding_grid_data.tres"
	save_btn.pressed.connect(_on_save_data_pressed)
	toolbar.add_child(save_btn)

	# Status Label
	var sep_stat := VSeparator.new()
	toolbar.add_child(sep_stat)

	status_label = Label.new()
	status_label.text = "Ready"
	toolbar.add_child(status_label)

	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar)

func _on_mode_selected(mode: EditToolMode) -> void:
	current_mode = mode
	if shape_container:
		shape_container.visible = (current_mode == EditToolMode.ADD_OBSTACLE or current_mode == EditToolMode.REMOVE_OBSTACLE)
	if debugger:
		debugger.is_box_dragging = false
		debugger.queue_redraw()

func _on_find_path_pressed() -> void:
	if debugger:
		debugger.find_path()
		_update_status_label()

func _on_scan_colliders_pressed() -> void:
	if debugger and debugger.grid_data:
		var undo_redo := get_undo_redo()
		var old_blocked: Array[Vector2i] = debugger.grid_data.blocked_cells.duplicate()
		debugger.scan_physics_colliders()
		var new_blocked: Array[Vector2i] = debugger.grid_data.blocked_cells.duplicate()
		undo_redo.create_action("Scan Colliders")
		undo_redo.add_do_property(debugger.grid_data, "blocked_cells", new_blocked)
		undo_redo.add_undo_property(debugger.grid_data, "blocked_cells", old_blocked)
		undo_redo.add_do_method(debugger, "rebuild_and_redraw")
		undo_redo.add_undo_method(debugger, "rebuild_and_redraw")
		undo_redo.add_do_method(self, "_update_status_label")
		undo_redo.add_undo_method(self, "_update_status_label")
		undo_redo.commit_action(false)
		_update_status_label()

func _on_clear_walls_pressed() -> void:
	if debugger and debugger.grid_data:
		var undo_redo := get_undo_redo()
		var old_blocked: Array[Vector2i] = debugger.grid_data.blocked_cells.duplicate()
		undo_redo.create_action("Clear Walls")
		undo_redo.add_do_method(debugger, "clear_obstacles")
		undo_redo.add_undo_property(debugger.grid_data, "blocked_cells", old_blocked)
		undo_redo.add_undo_method(debugger, "rebuild_and_redraw")
		undo_redo.add_do_method(self, "_update_status_label")
		undo_redo.add_undo_method(self, "_update_status_label")
		undo_redo.commit_action()
		_update_status_label()

func _on_save_data_pressed() -> void:
	if debugger:
		debugger.save_resource_to_file()
		_update_status_label("Saved successfully!")

func _update_status_label(custom_msg: String = "") -> void:
	if status_label == null:
		return
	if not custom_msg.is_empty():
		status_label.text = custom_msg
	elif debugger and debugger.grid_data:
		status_label.text = "Obstacles: %d | %s" % [debugger.grid_data.blocked_cells.size(), debugger.last_search_message]
	else:
		status_label.text = "No Grid"

func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if debugger == null or not debugger.is_inside_tree() or debugger.grid_data == null:
		return false

	var grid_data := debugger.grid_data

	# Cancel dragging on Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_box_dragging:
			is_box_dragging = false
			is_mouse_down = false
			debugger.is_box_dragging = false
			debugger.queue_redraw()
			_update_status_label("Box cancelled.")
			return true

	# Compute mouse cell
	if event is InputEventMouse:
		var editor_vp := EditorInterface.get_editor_viewport_2d()
		var canvas_xform: Transform2D
		if editor_vp:
			canvas_xform = editor_vp.global_canvas_transform * editor_vp.canvas_transform
		else:
			canvas_xform = debugger.get_viewport().global_canvas_transform * debugger.get_viewport().get_canvas_transform()

		var world_mouse: Vector2 = canvas_xform.affine_inverse() * event.position
		var local_mouse: Vector2 = debugger.to_local(world_mouse)

		var rel: Vector2 = local_mouse - grid_data.world_offset
		var cell: Vector2i = Vector2i(
			int(floor(rel.x / grid_data.cell_size.x)),
			int(floor(rel.y / grid_data.cell_size.y))
		)

		var in_bounds := grid_data.is_in_bounds(cell)
		var old_hovered := debugger.hovered_cell
		debugger.hovered_cell = cell if in_bounds else Vector2i(-1, -1)

		# Effective box mode (Hold Shift to toggle mode Pen <-> Box)
		var is_shift: bool = event.shift_pressed
		var effective_box_mode: bool = (current_shape == DrawShapeMode.BOX) != is_shift

		# Mouse Button Left
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not in_bounds:
					return false

				is_mouse_down = true

				match current_mode:
					EditToolMode.VIEW:
						return false

					EditToolMode.SET_START:
						var undo_redo := get_undo_redo()
						var old_start: Vector2i = debugger.start_point
						undo_redo.create_action("Set Start Point")
						undo_redo.add_do_property(debugger, "start_point", cell)
						undo_redo.add_undo_property(debugger, "start_point", old_start)
						undo_redo.add_do_method(self, "_update_status_label")
						undo_redo.add_undo_method(self, "_update_status_label")
						undo_redo.commit_action()
						return true

					EditToolMode.SET_GOAL:
						var undo_redo := get_undo_redo()
						var old_goal: Vector2i = debugger.goal_point
						undo_redo.create_action("Set Goal Point")
						undo_redo.add_do_property(debugger, "goal_point", cell)
						undo_redo.add_undo_property(debugger, "goal_point", old_goal)
						undo_redo.add_do_method(self, "_update_status_label")
						undo_redo.add_undo_method(self, "_update_status_label")
						undo_redo.commit_action()
						return true

					EditToolMode.ADD_OBSTACLE, EditToolMode.REMOVE_OBSTACLE:
						if effective_box_mode:
							is_box_dragging = true
							box_start_cell = cell
							box_current_cell = cell
							debugger.is_box_dragging = true
							debugger.box_start_cell = cell
							debugger.box_current_cell = cell
							debugger.box_mode_add = (current_mode == EditToolMode.ADD_OBSTACLE)
							debugger.queue_redraw()
							return true
						else:
							# Pen Stroke start
							pen_pre_stroke_blocked = grid_data.blocked_cells.duplicate()
							pen_stroke_modified = false
							last_painted_cell = cell
							if current_mode == EditToolMode.ADD_OBSTACLE:
								if grid_data.add_obstacle(cell):
									pen_stroke_modified = true
							else:
								if grid_data.remove_obstacle(cell):
									pen_stroke_modified = true
							_update_status_label()
							return true

			else: # Mouse Up
				if is_mouse_down:
					is_mouse_down = false
					last_painted_cell = Vector2i(-1, -1)

					if is_box_dragging:
						is_box_dragging = false
						debugger.is_box_dragging = false

						var undo_redo := get_undo_redo()
						var old_blocked: Array[Vector2i] = grid_data.blocked_cells.duplicate()
						var is_add := (current_mode == EditToolMode.ADD_OBSTACLE)

						undo_redo.create_action("Box " + ("Add" if is_add else "Remove") + " Obstacles")
						if is_add:
							undo_redo.add_do_method(grid_data, "add_obstacles_box", box_start_cell, box_current_cell)
						else:
							undo_redo.add_do_method(grid_data, "remove_obstacles_box", box_start_cell, box_current_cell)
						undo_redo.add_undo_property(grid_data, "blocked_cells", old_blocked)
						undo_redo.add_do_method(debugger, "rebuild_and_redraw")
						undo_redo.add_undo_method(debugger, "rebuild_and_redraw")
						undo_redo.add_do_method(self, "_update_status_label")
						undo_redo.add_undo_method(self, "_update_status_label")
						undo_redo.commit_action()

						_update_status_label()
						return true

					elif pen_stroke_modified:
						# Pen Stroke completed -> Commit Undo/Redo action
						var undo_redo := get_undo_redo()
						var new_blocked: Array[Vector2i] = grid_data.blocked_cells.duplicate()
						var action_name: String = "Paint Walls" if current_mode == EditToolMode.ADD_OBSTACLE else "Erase Walls"
						undo_redo.create_action(action_name)
						undo_redo.add_do_property(grid_data, "blocked_cells", new_blocked)
						undo_redo.add_undo_property(grid_data, "blocked_cells", pen_pre_stroke_blocked)
						undo_redo.add_do_method(debugger, "rebuild_and_redraw")
						undo_redo.add_undo_method(debugger, "rebuild_and_redraw")
						undo_redo.add_do_method(self, "_update_status_label")
						undo_redo.add_undo_method(self, "_update_status_label")
						undo_redo.commit_action(false)
						pen_stroke_modified = false
						_update_status_label()
						return true

		# Mouse Motion
		if event is InputEventMouseMotion:
			if is_box_dragging:
				if in_bounds and cell != box_current_cell:
					box_current_cell = cell
					debugger.box_current_cell = cell
					debugger.queue_redraw()
				return true
			elif is_mouse_down and in_bounds and not effective_box_mode:
				if cell != last_painted_cell:
					last_painted_cell = cell
					if current_mode == EditToolMode.ADD_OBSTACLE:
						if grid_data.add_obstacle(cell):
							pen_stroke_modified = true
					elif current_mode == EditToolMode.REMOVE_OBSTACLE:
						if grid_data.remove_obstacle(cell):
							pen_stroke_modified = true
					_update_status_label()
					return true
			else:
				if debugger.hovered_cell != old_hovered:
					debugger.queue_redraw()

	return false
