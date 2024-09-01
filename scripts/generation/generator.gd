class_name MapGenerator
extends Resource

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
@export var max_rooms: int

var map: Array[int]   # Array map with all tiles
var rooms: Array[int] # Valid visited rooms

var _stack: Array[int]


func generate() -> void:
	if map_size.x == 0 or map_size.y == 0:
		push_error("Invalid map size!")
		return
	if max_rooms <= 0 or max_rooms >= map_size.x * map_size.y:
		push_error("Invalid maximum number of rooms provided!")
		return

	map.resize(map_size.x * map_size.y)
	var start := _get_index(Vector2i(
		randi_range(1, map_size.x - 2),
		randi_range(1, map_size.y - 2)
	))

	# Reset data
	_stack.clear()
	rooms.clear()
	map.fill(CELL_EMPTY)

	while rooms.size() < max_rooms:
		# If the stack is empty, verify if the start cells has walls, if it has,
		# push it into stack, if not push a random cell
		if _stack.is_empty():
			if _get_walls(start).is_empty():
				_stack.push_back(rooms.pick_random())
			else:
				_stack.push_back(start)

		_do_step()

	# Transverse map to remap valid exits into the IDs
	for room in rooms:
		map[room] = _get_exits(room)


# Visit room, add neighbour rooms to the stack, then register room
# as visited and store it
func _do_step() -> void:
	var next: int = _stack.pop_back()

	# There are N% chance of giving up direction
	if randf() <= _GIVEUP_CHANCE:
		return

	_push_neighbours(next)

	# Mark as visited
	map[next] = CELL_VISITED
	rooms.push_back(next)


# Follow a set of rules and push all valid neighbours to the stack
func _push_neighbours(room: int) -> void:
	# TODO: Generate bigger rooms

	# Get all adjacent empty cells
	for cell in _get_walls(room):
		# There are 50% of chance of not adding this cell
		if randi() % 2 == 0:
			continue

		# Check if the cell have 3 adjacent empty cells
		if _get_walls(cell).size() != 3:
			continue

		_stack.push_back(cell)


# Get all adjacent empty cells of provided cell
func _get_walls(cell: int) -> Array[int]:
	var walls: Array[int]

	for wall in _get_adjacent_cells(cell):
		if map[wall] == CELL_EMPTY:
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
		if map[cell] == CELL_EMPTY:
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

	if idx < 0 or idx >= map.size():
		return -1

	return idx


func _get_position(idx: int) -> Vector2:
	if idx < 0 or idx >= map.size():
		return Vector2.INF

	@warning_ignore("integer_division")
	return Vector2(idx % map_size.x, idx / map_size.x)
