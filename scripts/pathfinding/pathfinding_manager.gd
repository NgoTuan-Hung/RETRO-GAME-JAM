class_name PathfindingManager
extends Node

## Centralized pathfinding service for NPCs and entities.
## Uses AStarGrid2D (native C++) with diagonal corner-cutting prevention.

static var instance: PathfindingManager

@export var grid_data: PathfindingGridData

var astar_grid: AStarGrid2D

func _enter_tree() -> void:
	if instance == null:
		instance = self

func _ready() -> void:
	if instance == null:
		instance = self
	initialize_grid()

## Initializes or rebuilds the AStarGrid2D based on current grid_data.
func initialize_grid(data: PathfindingGridData = null) -> void:
	if data != null:
		grid_data = data
	
	if grid_data == null:
		push_warning("[PathfindingManager] No PathfindingGridData assigned! Creating default.")
		grid_data = PathfindingGridData.new()

	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(grid_data.region_position, grid_data.region_size)
	astar_grid.cell_size = grid_data.cell_size
	astar_grid.offset = grid_data.cell_size * 0.5
	
	# Prevent cutting corners around obstacles (diagonal movement requires adjacent cells to be walkable)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()

	# Apply obstacles
	for cell in grid_data.blocked_cells:
		if astar_grid.is_in_bounds(cell.x, cell.y):
			astar_grid.set_point_solid(cell, true)

## Converts world position to grid cell coordinate.
func world_to_grid(world_pos: Vector2) -> Vector2i:
	if grid_data == null:
		return Vector2i.ZERO
	var local := world_pos - grid_data.world_offset
	var gx := int(floor(local.x / grid_data.cell_size.x))
	var gy := int(floor(local.y / grid_data.cell_size.y))
	return Vector2i(gx, gy)

## Converts grid cell coordinate to world position.
func grid_to_world(cell: Vector2i, center: bool = true) -> Vector2:
	if grid_data == null:
		return Vector2.ZERO
	var pos := grid_data.world_offset + Vector2(cell) * grid_data.cell_size
	if center:
		pos += grid_data.cell_size * 0.5
	return pos

## Checks if world position is inside the grid and walkable.
func is_walkable(world_pos: Vector2) -> bool:
	if astar_grid == null:
		return false
	var cell := world_to_grid(world_pos)
	return astar_grid.is_in_bounds(cell.x, cell.y) and not astar_grid.is_point_solid(cell)

## Checks if grid cell is inside the grid and walkable.
func is_cell_walkable(cell: Vector2i) -> bool:
	if astar_grid == null:
		return false
	return astar_grid.is_in_bounds(cell.x, cell.y) and not astar_grid.is_point_solid(cell)

## Dynamically marks a cell as solid or walkable at runtime.
func set_cell_solid(cell: Vector2i, solid: bool) -> void:
	if astar_grid and astar_grid.is_in_bounds(cell.x, cell.y):
		astar_grid.set_point_solid(cell, solid)

## Finds a path between two world positions. Returns PackedVector2Array in world coordinates.
## If goal is occupied, it tries to find the closest reachable adjacent cell.
func find_path(start_world: Vector2, goal_world: Vector2) -> PackedVector2Array:
	if astar_grid == null:
		initialize_grid()
		if astar_grid == null:
			return PackedVector2Array()

	var start_cell := world_to_grid(start_world)
	var goal_cell := world_to_grid(goal_world)

	if not astar_grid.is_in_bounds(start_cell.x, start_cell.y):
		return PackedVector2Array()

	if not astar_grid.is_in_bounds(goal_cell.x, goal_cell.y):
		return PackedVector2Array()

	# If start cell is accidentally inside a wall (e.g. pushed into wall), find nearest free cell
	if astar_grid.is_point_solid(start_cell):
		var free_start: Vector2i = _find_nearest_walkable_neighbor(start_cell)
		if free_start != Vector2i(-1, -1):
			start_cell = free_start
		else:
			return PackedVector2Array()

	# If goal cell is solid (e.g. target NPC standing near wall), find nearest free neighbor
	if astar_grid.is_point_solid(goal_cell):
		var free_goal: Vector2i = _find_nearest_walkable_neighbor(goal_cell)
		if free_goal != Vector2i(-1, -1):
			goal_cell = free_goal
		else:
			return PackedVector2Array()

	var raw_points: PackedVector2Array = astar_grid.get_point_path(start_cell, goal_cell)
	if raw_points.is_empty():
		return PackedVector2Array()

	# Convert local AStar points to world coordinates (centered in each cell)
	var world_path: PackedVector2Array = PackedVector2Array()
	world_path.resize(raw_points.size())
	for i in range(raw_points.size()):
		var pt: Vector2 = raw_points[i]
		world_path[i] = pt + grid_data.world_offset

	return world_path

func _find_nearest_walkable_neighbor(center: Vector2i) -> Vector2i:
	var neighbors: Array[Vector2i] = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	for dir: Vector2i in neighbors:
		var n: Vector2i = center + dir
		if astar_grid.is_in_bounds(n.x, n.y) and not astar_grid.is_point_solid(n):
			return n
	return Vector2i(-1, -1)
