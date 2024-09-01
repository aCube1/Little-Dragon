class_name MapGenerator
extends Resource

signal generation_finished(map: PackedInt32Array, rooms: PackedInt32Array)
signal step_completed(map: PackedInt32Array, rooms: PackedInt32Array)


# Room data
enum {
	CELL_EMPTY = -1,
	CELL_VISITED = 0,

	DOOR_LEFT = 1 << 0,  # 0b0001
	DOOR_RIGHT = 1 << 1, # 0b0010
	DOOR_UP = 1 << 2,    # 0b0100
	DOOR_DOWN = 1 << 3,  # 0b1000
	DOOR_MASK = 0x0f,    # 0bxxxx
}

const _GIVEUP_CHANCE := 0.3

@export var map_size: Vector2i
@export var max_rooms: int = 16

var _map: PackedInt32Array   # Array map with all tiles
var _rooms: PackedInt32Array # Valid visited rooms
var _stack: Array[int]


func generate() -> void:
	if map_size.x == 0 or map_size.y == 0:
		push_error("Invalid map size!")
		return

	if max_rooms <= 0 or max_rooms >= map_size.x * map_size.y:
		push_error("Invalid maximum number of rooms provided!")
		return

	_map.resize(map_size.x * map_size.y)
	var start := _get_index(Vector2i(
		randi_range(1, map_size.x - 2),
		randi_range(1, map_size.y - 2)
	))

	# Reset data
	_stack.clear()
	_rooms.clear()
	_map.fill(CELL_EMPTY)

	# Next index in the 'rooms' array to push into stack
	var stack_next := 0

	while _rooms.size() < max_rooms:
		# If the stack is empty, push a random or start cell into stack
		if _stack.is_empty():
			if not _rooms.is_empty():
				# Try to find next cell to continue iteration
				_push_neighbours(_rooms[stack_next])
				stack_next += 1
				if stack_next >= _rooms.size():
					stack_next = 0
			else:
				_stack.push_back(start)

		_do_step()

	generation_finished.emit(_map.duplicate(), _rooms.duplicate())


# Visit room, add neighbour rooms to the stack, then register room
# as visited and store it
func _do_step() -> void:
	var next = _stack.pop_back()
	if next == null:
		return

	# The cell must not be already registered
	if next in _rooms:
		return

	# There are N% chance of giving up direction
	if randf() <= _GIVEUP_CHANCE:
		return

	# If the wall has less than 3 adjacent empty cells, don't register it
	# TODO: Generate bigger rooms
	if _get_empty_cells(next).size() < 3:
		return

	_push_neighbours(next)

	# Map valid exits into the cells data
	_map[next] = _get_exits(next)
	for cell in _get_adjacent_cells(next):
		if _map[cell] != CELL_EMPTY:
			_map[cell] = _get_exits(cell)

	_rooms.push_back(next) # Register as a valid room
	step_completed.emit(_map.duplicate(), _rooms.duplicate())


# Follow a set of rules and push all valid neighbours to the stack
func _push_neighbours(room: int) -> void:
	# Get all adjacent empty cells
	for cell in _get_empty_cells(room):
		# If stack is not empty, there is 50% of chance of not adding this cell
		if not _stack.is_empty() and randi() % 2 == 0:
			continue

		# Check if the cell have 3 adjacent empty cells
		if _get_empty_cells(cell).size() != 3:
			continue

		_stack.push_back(cell)


# Get all adjacent empty cells of provided cell
func _get_empty_cells(cell: int) -> Array[int]:
	var walls: Array[int]

	for wall in _get_adjacent_cells(cell):
		if _map[wall] == CELL_EMPTY:
			walls.append(wall)

	return walls


# Return a bitfield masking all doors of provided cell
func _get_exits(idx: int) -> int:
	var exits: int = CELL_VISITED
	var cells := _get_adjacent_cells(idx)
	var pos := _get_position(idx)

	for i in cells.size():
		var cell := cells[i]

		# Ignore empty cells
		if _map[cell] == CELL_EMPTY:
			continue

		var cell_pos := _get_position(cell)
		if cell_pos.x < pos.x:
			exits |= DOOR_LEFT
		elif cell_pos.x > pos.x:
			exits |= DOOR_RIGHT
		elif cell_pos.y < pos.y:
			exits |= DOOR_UP
		elif cell_pos.y > pos.y:
			exits |= DOOR_DOWN

	return exits


# Get adjacent cells of provided cell. If 'diagonal' is true the function stores it too
func _get_adjacent_cells(idx: int, diagonal: bool = false) -> Array[int]:
	var cells: Array[int]
	var map_area := Rect2i(0, 0, map_size.x - 1, map_size.y - 1)
	var position := _get_position(idx) as Vector2i

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue

			# If we are not searching diagonals, we just jump to next iteration
			if not diagonal and abs(dx) == abs(dy):
				continue

			var new_pos := position + Vector2i(dx, dy)
			if not map_area.has_point(new_pos):
				continue

			var cell := _get_index(new_pos)
			cells.append(cell)


	return cells


func _get_index(pos: Vector2i) -> int:
	var idx := pos.x + map_size.x * pos.y

	if idx < 0 or idx >= _map.size():
		return -1

	return idx


func _get_position(idx: int) -> Vector2:
	if idx < 0 or idx >= _map.size():
		return Vector2.INF

	@warning_ignore("integer_division")
	return Vector2(idx % map_size.x, idx / map_size.x)
