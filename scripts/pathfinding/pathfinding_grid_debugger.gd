@tool
class_name PathfindingGridDebugger
extends Node2D

## Visualizer and Editor Debugger for PathfindingGridData.
## Renders grid bounds, walkable cells, obstacles, start/goal points, and computed paths.

signal path_calculated(success: bool, message: String)

@export var grid_data: PathfindingGridData:
	set(value):
		if grid_data and grid_data.changed.is_connected(_on_grid_data_changed):
			grid_data.changed.disconnect(_on_grid_data_changed)
		grid_data = value
		if grid_data:
			grid_data.changed.connect(_on_grid_data_changed)
		rebuild_and_redraw()

@export_group("Pathfinding Points")
@export var start_point: Vector2i = Vector2i(1, 1):
	set(value):
		start_point = value
		if auto_update_path:
			find_path()
		queue_redraw()

@export var goal_point: Vector2i = Vector2i(10, 10):
	set(value):
		goal_point = value
		if auto_update_path:
			find_path()
		queue_redraw()

@export_group("Visualization")
@export var show_grid: bool = true:
	set(value):
		show_grid = value
		queue_redraw()

@export var show_walkable_wireframes: bool = false:
	set(value):
		show_walkable_wireframes = value
		queue_redraw()

@export var show_obstacles: bool = true:
	set(value):
		show_obstacles = value
		queue_redraw()

@export var show_path: bool = true:
	set(value):
		show_path = value
		queue_redraw()

## Border width for grid cells (-1.0 = adaptive 1-pixel screen hairline, crisp at any cell size or zoom level).
@export var cell_border_width: float = -1.0:
	set(value):
		cell_border_width = value
		queue_redraw()

@export var auto_update_path: bool = true

@export_group("Physics Scan")
@export_flags_2d_physics var obstacle_collision_mask: int = 1
@export var scan_scale: float = 0.85

@export_group("Editor Actions")
@export var action_find_path: bool = false:
	set(value):
		if value:
			find_path()

@export var action_scan_colliders: bool = false:
	set(value):
		if value:
			scan_physics_colliders()

@export var action_clear_obstacles: bool = false:
	set(value):
		if value:
			clear_obstacles()

@export var action_save_to_file: bool = false:
	set(value):
		if value:
			save_resource_to_file()

var current_path: PackedVector2Array = PackedVector2Array()
var last_search_succeeded: bool = false
var last_search_message: String = "No search performed yet."

# Internal astar instance for Editor preview
var _editor_astar: AStarGrid2D = null

# State for EditorPlugin tool interaction (Pen / Box dragging)
var is_box_dragging: bool = false
var box_start_cell: Vector2i = Vector2i.ZERO
var box_current_cell: Vector2i = Vector2i.ZERO
var box_mode_add: bool = true
var hovered_cell: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	if grid_data == null:
		grid_data = PathfindingGridData.new()
	if not grid_data.changed.is_connected(_on_grid_data_changed):
		grid_data.changed.connect(_on_grid_data_changed)
	rebuild_and_redraw()

func _on_grid_data_changed() -> void:
	rebuild_and_redraw()

func rebuild_and_redraw() -> void:
	if grid_data == null:
		queue_redraw()
		return

	_editor_astar = AStarGrid2D.new()
	_editor_astar.region = Rect2i(grid_data.region_position, grid_data.region_size)
	_editor_astar.cell_size = grid_data.cell_size
	_editor_astar.offset = grid_data.cell_size * 0.5
	_editor_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_editor_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_editor_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_editor_astar.update()

	for cell in grid_data.blocked_cells:
		if _editor_astar.is_in_bounds(cell.x, cell.y):
			_editor_astar.set_point_solid(cell, true)

	if auto_update_path:
		find_path()
	queue_redraw()

## Finds path using internal AStar instance and calculates time.
func find_path() -> void:
	if grid_data == null:
		return
	if _editor_astar == null:
		rebuild_and_redraw()
		if _editor_astar == null:
			return

	if not _editor_astar.is_in_bounds(start_point.x, start_point.y):
		current_path.clear()
		last_search_succeeded = false
		last_search_message = "Start point %s is outside grid bounds." % str(start_point)
		path_calculated.emit(false, last_search_message)
		queue_redraw()
		return

	if not _editor_astar.is_in_bounds(goal_point.x, goal_point.y):
		current_path.clear()
		last_search_succeeded = false
		last_search_message = "Goal point %s is outside grid bounds." % str(goal_point)
		path_calculated.emit(false, last_search_message)
		queue_redraw()
		return

	if _editor_astar.is_point_solid(start_point):
		current_path.clear()
		last_search_succeeded = false
		last_search_message = "Start point %s is blocked!" % str(start_point)
		path_calculated.emit(false, last_search_message)
		queue_redraw()
		return

	if _editor_astar.is_point_solid(goal_point):
		current_path.clear()
		last_search_succeeded = false
		last_search_message = "Goal point %s is blocked!" % str(goal_point)
		path_calculated.emit(false, last_search_message)
		queue_redraw()
		return

	var start_time := Time.get_ticks_usec()
	var raw_points := _editor_astar.get_point_path(start_point, goal_point)
	var elapsed_ms := (Time.get_ticks_usec() - start_time) / 1000.0

	if not raw_points.is_empty():
		current_path = raw_points
		last_search_succeeded = true
		last_search_message = "Path found! Length: %d steps (%.3f ms)" % [current_path.size(), elapsed_ms]
		path_calculated.emit(true, last_search_message)
	else:
		current_path.clear()
		last_search_succeeded = false
		last_search_message = "No valid path from %s to %s." % [str(start_point), str(goal_point)]
		path_calculated.emit(false, last_search_message)

	queue_redraw()

## Scans physical colliders or tilemap collision in 2D space.
func scan_physics_colliders() -> void:
	if grid_data == null:
		return

	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		push_warning("[PathfindingGridDebugger] No physics space state available for scan.")
		return

	var shape := RectangleShape2D.new()
	shape.size = grid_data.cell_size * scan_scale

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = obstacle_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var new_blocked: Array[Vector2i] = []
	var reg_pos := grid_data.region_position
	var reg_size := grid_data.region_size

	for x in range(reg_pos.x, reg_pos.x + reg_size.x):
		for y in range(reg_pos.y, reg_pos.y + reg_size.y):
			var cell := Vector2i(x, y)
			var cell_world_center := grid_data.world_offset + (Vector2(cell) + Vector2(0.5, 0.5)) * grid_data.cell_size
			query.transform = Transform2D(0.0, to_global(cell_world_center))
			var results := space_state.intersect_shape(query, 1)
			if not results.is_empty():
				new_blocked.append(cell)

	grid_data.blocked_cells = new_blocked
	grid_data.emit_changed()
	last_search_message = "Scanned physics colliders: %d obstacles detected." % new_blocked.size()
	print("[PathfindingGridDebugger] " + last_search_message)
	rebuild_and_redraw()

func clear_obstacles() -> void:
	if grid_data:
		grid_data.clear_obstacles()
		rebuild_and_redraw()

func save_resource_to_file(path: String = "") -> void:
	if grid_data == null:
		return
	var save_path := path
	if save_path.is_empty():
		save_path = grid_data.resource_path
	if save_path.is_empty():
		save_path = "res://data/pathfinding_grid_data.tres"
	var err := ResourceSaver.save(grid_data, save_path)
	if err == OK:
		print("[PathfindingGridDebugger] Saved grid data successfully to %s" % save_path)
	else:
		push_error("[PathfindingGridDebugger] Failed to save grid data to %s (Error %d)" % [save_path, err])

func _draw() -> void:
	if grid_data == null or not show_grid:
		return

	var reg_pos := grid_data.region_position
	var reg_size := grid_data.region_size
	var c_size := grid_data.cell_size
	var origin := grid_data.world_offset
	var min_cell := minf(c_size.x, c_size.y)

	var total_size := Vector2(reg_size) * c_size
	var top_left := origin + Vector2(reg_pos) * c_size

	# Adaptive line thickness:
	# Default (-1.0) renders a 1-pixel screen hairline at any zoom level.
	# This ensures cells never get drowned out at 1x1 while staying crisp at 16x16.
	var wire_stroke := cell_border_width

	# Walkable wireframes / Grid lines
	# Drawn with draw_multiline for optimal performance (0 ms) and no edge overlapping.
	if show_walkable_wireframes:
		var wire_color := Color(1.0, 1.0, 1.0, 0.15)
		var grid_lines := PackedVector2Array()
		# Vertical lines
		for x in range(reg_size.x + 1):
			var px := top_left.x + x * c_size.x
			grid_lines.append(Vector2(px, top_left.y))
			grid_lines.append(Vector2(px, top_left.y + total_size.y))
		# Horizontal lines
		for y in range(reg_size.y + 1):
			var py := top_left.y + y * c_size.y
			grid_lines.append(Vector2(top_left.x, py))
			grid_lines.append(Vector2(top_left.x + total_size.x, py))
		draw_multiline(grid_lines, wire_color, wire_stroke)

	# Obstacles
	if show_obstacles:
		var obs_fill := Color(0.9, 0.15, 0.15, 0.65)
		var obs_wire := Color(1.0, 0.2, 0.2, 0.9)
		var use_compact := min_cell <= 4.0
		var obs_stroke := wire_stroke if wire_stroke >= 0.0 else (-1.0 if use_compact else 1.0)

		for cell in grid_data.blocked_cells:
			var cell_pos := origin + Vector2(cell) * c_size
			if use_compact:
				var cell_rect := Rect2(cell_pos, c_size)
				draw_rect(cell_rect, obs_fill, true)
				if min_cell >= 2.0 or wire_stroke >= 0.0:
					draw_rect(cell_rect, obs_wire, false, obs_stroke)
			else:
				var inset := c_size * 0.05
				var cell_rect := Rect2(cell_pos + inset, c_size - inset * 2.0)
				draw_rect(cell_rect, obs_fill, true)
				draw_rect(cell_rect, obs_wire, false, obs_stroke)

	# Outer boundary box
	var boundary_width := -1.0 if min_cell <= 4.0 else 2.0
	draw_rect(Rect2(top_left, total_size), Color(0.2, 0.8, 1.0, 0.9), false, boundary_width)

	# Start Point
	if grid_data.is_in_bounds(start_point):
		var start_rect := Rect2(origin + Vector2(start_point) * c_size, c_size)
		draw_rect(start_rect, Color(0.1, 0.95, 0.2, 0.85), true)
		var start_stroke := -1.0 if min_cell <= 4.0 else 2.0
		draw_rect(start_rect, Color.WHITE, false, start_stroke)

	# Goal Point
	if grid_data.is_in_bounds(goal_point):
		var goal_rect := Rect2(origin + Vector2(goal_point) * c_size, c_size)
		draw_rect(goal_rect, Color(0.1, 0.6, 1.0, 0.85), true)
		var goal_stroke := -1.0 if min_cell <= 4.0 else 2.0
		draw_rect(goal_rect, Color.WHITE, false, goal_stroke)

	# Path
	if show_path and not current_path.is_empty():
		var path_color := Color(1.0, 0.85, 0.0, 1.0)
		var pt_color := Color(1.0, 0.95, 0.2, 1.0)
		var path_line_w := -1.0 if min_cell <= 2.0 else clampf(min_cell * 0.15, 1.0, 2.5)

		# Draw line segments
		for i in range(current_path.size() - 1):
			var p1 := origin + current_path[i]
			var p2 := origin + current_path[i + 1]
			draw_line(p1, p2, path_color, path_line_w)

		# Draw node points
		if min_cell >= 4.0:
			var pt_radius := clampf(min_cell * 0.25, 1.0, 4.0)
			for pt in current_path:
				var center := origin + pt
				draw_circle(center, pt_radius, pt_color)
		elif min_cell > 1.0:
			for pt in current_path:
				var center := origin + pt
				draw_circle(center, min_cell * 0.25, pt_color)

	# Box Dragging Preview in Editor
	if is_box_dragging:
		var min_x := mini(box_start_cell.x, box_current_cell.x)
		var max_x := maxi(box_start_cell.x, box_current_cell.x)
		var min_y := mini(box_start_cell.y, box_current_cell.y)
		var max_y := maxi(box_start_cell.y, box_current_cell.y)
		var box_pos := origin + Vector2(min_x, min_y) * c_size
		var box_size := Vector2(max_x - min_x + 1, max_y - min_y + 1) * c_size

		var fill := Color(1.0, 0.2, 0.2, 0.4) if box_mode_add else Color(1.0, 0.9, 0.2, 0.4)
		var outline := Color(1.0, 0.3, 0.3, 0.95) if box_mode_add else Color(1.0, 0.95, 0.3, 0.95)
		draw_rect(Rect2(box_pos, box_size), fill, true)
		var box_stroke := -1.0 if min_cell <= 4.0 else 2.0
		draw_rect(Rect2(box_pos, box_size), outline, false, box_stroke)
	elif grid_data.is_in_bounds(hovered_cell):
		# Hovered cell indicator
		var h_rect := Rect2(origin + Vector2(hovered_cell) * c_size, c_size)
		var h_stroke := -1.0 if min_cell <= 4.0 else 1.5
		draw_rect(h_rect, Color(1.0, 1.0, 1.0, 0.5), false, h_stroke)
