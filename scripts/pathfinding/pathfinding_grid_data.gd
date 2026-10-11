@tool
class_name PathfindingGridData
extends Resource

## Data container for 2D A* Pathfinding Grid, saving dimensions and obstacles.

@export var region_position: Vector2i = Vector2i(0, 0)
@export var region_size: Vector2i = Vector2i(60, 40)
@export var cell_size: Vector2 = Vector2(16.0, 16.0)
@export var world_offset: Vector2 = Vector2.ZERO

## List of obstacle coordinates in grid space.
@export var blocked_cells: Array[Vector2i] = []

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= region_position.x and cell.x < region_position.x + region_size.x \
		and cell.y >= region_position.y and cell.y < region_position.y + region_size.y

func is_blocked(cell: Vector2i) -> bool:
	return cell in blocked_cells

func add_obstacle(cell: Vector2i) -> bool:
	if not is_in_bounds(cell):
		return false
	if cell not in blocked_cells:
		blocked_cells.append(cell)
		emit_changed()
		return true
	return false

func remove_obstacle(cell: Vector2i) -> bool:
	var idx := blocked_cells.find(cell)
	if idx != -1:
		blocked_cells.remove_at(idx)
		emit_changed()
		return true
	return false

func add_obstacles_box(min_cell: Vector2i, max_cell: Vector2i) -> bool:
	var min_x := mini(min_cell.x, max_cell.x)
	var max_x := maxi(min_cell.x, max_cell.x)
	var min_y := mini(min_cell.y, max_cell.y)
	var max_y := maxi(min_cell.y, max_cell.y)
	
	var changed := false
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var cell := Vector2i(x, y)
			if is_in_bounds(cell) and cell not in blocked_cells:
				blocked_cells.append(cell)
				changed = true
	if changed:
		emit_changed()
	return changed

func remove_obstacles_box(min_cell: Vector2i, max_cell: Vector2i) -> bool:
	var min_x := mini(min_cell.x, max_cell.x)
	var max_x := maxi(min_cell.x, max_cell.x)
	var min_y := mini(min_cell.y, max_cell.y)
	var max_y := maxi(min_cell.y, max_cell.y)
	
	var set_to_remove := {}
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			set_to_remove[Vector2i(x, y)] = true
	
	var old_count := blocked_cells.size()
	blocked_cells = blocked_cells.filter(func(cell: Vector2i) -> bool: return not set_to_remove.has(cell))
	if blocked_cells.size() != old_count:
		emit_changed()
		return true
	return false

func clear_obstacles() -> void:
	if not blocked_cells.is_empty():
		blocked_cells.clear()
		emit_changed()

func get_world_rect() -> Rect2:
	var pos := world_offset + Vector2(region_position) * cell_size
	var size := Vector2(region_size) * cell_size
	return Rect2(pos, size)
