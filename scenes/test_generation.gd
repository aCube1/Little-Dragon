extends Node2D

const _chars := [
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

@onready var generator := $MapGenerator


func _ready() -> void:
	generator.connect("step_completed", _display_map)
	generator.connect("generation_finished",
		func(_map, _rooms):
			print("FINISHED!")
	)


func _process(_dt: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		generator.start_generation()


func _display_map(map: Array[int], _rooms: Array[int]) -> void:
	var text_map := ""
	for i in map.size():
		var room := map[i]

		if room != generator.CELL_EMPTY:
			text_map += _chars[room & generator.DOOR_MASK]
		else:
			text_map += "█"

		if i % generator.map_size.x == generator.map_size.x - 1:
			text_map += "\n"

	%MapRenderer.text = text_map
