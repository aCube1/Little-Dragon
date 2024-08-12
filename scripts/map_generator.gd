class_name MapGenerator
extends Resource


# Exit sides
enum {
	EXIT_UP = 0x01,    # 0b0001
	EXIT_DOWN = 0x02,  # 0b0010
	EXIT_LEFT = 0x04,  # 0b0100
	EXIT_RIGHT = 0x08, # 0b1000
	EXIT_MASK = 0x0f,  # 0bxxxx
}

# Room kind
enum {
	KIND_WALL = 0x00,
	KIND_EMPTY = 0x10, # 0b0001_xxxx
	KIND_START = 0x30, # 0b0011_xxxx
	KIND_END = 0x70,   # 0b0111_xxxx
}

@export var map_size: Vector2i

var map: PackedInt32Array   # Array map with all tiles
var rooms: PackedInt32Array # Valid visited rooms

var _stack: Array[int]


func generate() -> bool:
	if map_size.x == 0 or map_size.y == 0:
		push_error("Map Size shouldn't be 0");
		return false

	# Clear all data
	_stack.clear()
	rooms.clear()
	map.clear()
	map.resize(map_size.x * map_size.y)

	# Formula to get the number of rooms:
	var max_rooms := (randi() % 2) * map.size() * 0.6

	var start_pos := Vector2(randi_range(0, map_size.x - 1), randi_range(0, map_size.y - 1))
	var start_room = get_index(start_pos)
	_stack.push_back(start_room)

	while not _stack.is_empty():
		_visit(_stack.pop_back())

		if rooms.size() > max_rooms:
			break

	if rooms.size() < max_rooms:
		return false

	# Transverse map to remap valid exits into the IDs
	for room in rooms:
		var exits := _get_exits(room)
		map[room] |= exits

	# TODO: Generate bigger rooms
	_generate_special()

	return true


func get_index(pos: Vector2i) -> int:
	var idx := pos.x + map_size.x * pos.y

	if idx < 0 or idx >= map.size():
		return -1

	return idx


func get_position(idx: int) -> Vector2:
	if idx < 0 or idx >= map.size():
		return Vector2.INF

	@warning_ignore("integer_division")
	return Vector2(idx % map_size.x, idx / map_size.x)


# Generate all special rooms: Start, End
# TODO: Improve special rooms generation, or let the Mapper
# choose how the rooms work
func _generate_special() -> void:
	# The first discovered Room must be the Start Room
	map[rooms[0]] |= KIND_START

	# Try to find furthest room with only 1
	# neightbor and set it as the End Room
	var start_pos := get_position(rooms[0])
	var end_pos := start_pos
	var end_room := rooms[0]

	for room in rooms:
		# End rooms must have 3 walls on the sides
		var walls := _get_walls(room)
		if walls.size() != 3:
			continue

		var current_pos := get_position(room)
		if (start_pos.distance_squared_to(current_pos)
			> start_pos.distance_squared_to(end_pos)):
			end_pos = get_position(room)
			end_room = room

	map[end_room] |= KIND_END


# Visit room, if valid, add valid adjacent rooms to the stack, then mark room
# as visited and store it
func _visit(next: int) -> void:
	if next < 0:
		return

	# Only visit rooms that have at least 3 walls
	var walls := _get_walls(next)
	if walls.size() < 3:
		return

	walls.shuffle()

	_stack.push_back(walls[0])
	_stack.push_back(walls[1])

	# Mark as visited
	map[next] |= KIND_EMPTY
	rooms.push_back(next)


# Return an array with all adjacent walls of provided room
func _get_walls(idx: int) -> Array[int]:
	var walls: Array[int] = []
	var pos := get_position(idx)

	var valid_sides := [
		Vector2(pos.x, pos.y - 1), # Up
		Vector2(pos.x, pos.y + 1), # Down
		Vector2(pos.x - 1, pos.y), # Left
		Vector2(pos.x + 1, pos.y), # Right
	]

	for side in valid_sides:
		# Maintain the trail inside the grid
		if (side.x >= map_size.x or side.x < 0
		or side.y >= map_size.y or side.y < 0):
			continue

		var wall := get_index(side)
		if map[get_index(side)] == KIND_WALL:
			walls.push_back(wall)

	return walls


# Return a bitfield masking all exits of provided room
func _get_exits(idx: int) -> int:
	var exits := 0
	var pos := get_position(idx)

	# This must be sorted to be relative to the
	# bit position in the ExitSides enum
	var sides := [
		Vector2(pos.x, pos.y - 1), # EXIT_UP
		Vector2(pos.x, pos.y + 1), # EXIT_DOWN
		Vector2(pos.x - 1, pos.y), # EXIT_LEFT
		Vector2(pos.x + 1, pos.y), # EXIT_RIGHT
	]

	for i in sides.size():
		var side: Vector2 = sides[i]

		# Maintain the trail inside the grid
		if (side.x >= map_size.x or side.x < 0
		or side.y >= map_size.y or side.y < 0):
			continue

		# The room has an exit if the adjacent room is not a Wall
		if (map[get_index(side)] & KIND_EMPTY) > 0:
			exits |= 1 << i

	return exits
