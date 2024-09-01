extends Node2D

@export var generator: MapGenerator

var _map := [
	".",
	"╸", # 0b0001
	"╺", # 0b0010
	"━", # 0b0011
	"╹", # 0b0100
	"┛", # 0b0101
	"┗", # 0b0110
	"┻", # 0b0111
	"╻", # 0b1000
	"┓", # 0b1001
	"┏", # 0b1010
	"┳", # 0b1011
	"┃", # 0b1100
	"┫", # 0b1101
	"┣", # 0b1110
	"╋", # 0b1111
]


func _process(_dt: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_generate_map()


func _generate_map() -> void:
	generator.generate()

	var _text_map := ""
	for i in generator.map.size():
		var room := generator.map[i]

		if room != generator.CELL_EMPTY:
			_text_map += _map[room & generator.DOOR_MASK]
		else:
			_text_map += "█"

		if i % generator.map_size.x == generator.map_size.x - 1:
			_text_map += "\n"

	print("---")
	print(_text_map)
