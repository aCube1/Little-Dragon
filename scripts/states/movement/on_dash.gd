extends BaseState

var _jump: JumpComponent
var _dash: DashComponent
var _controller: PlayerController


func _ready() -> void:
	_jump = owner.get_meta(&"JumpComponent")
	_dash = owner.get_meta(&"DashComponent")

	if owner.has_meta(&"Controller"):
		_controller = owner.get_meta(&"Controller")


func _enter(msg: Dictionary) -> void:
	var dir := _controller.dash_direction

	# We can't dash up if we are on the floor
	if msg.has("was_on_floor") and msg.was_on_floor:
		dir.y = 0.0

	# Consume all jumps if we are dashing up/down
	if dir.y != 0.0 and _jump != null:
		_jump.do_jump(_jump.max_jumps, true)

	_dash.do_dash(dir.normalized())


func _physics_update(delta: float) -> void:
	_dash.apply_stop_force(delta)

	if _jump != null:
		_jump.try_corner_correct(delta, false)
		_jump.try_corner_correct(delta, true)
