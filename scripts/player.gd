
class_name Player
extends CharacterBody2D


@onready var animated_sprite := $AnimatedSprite2D
var scale_alteration:float = 100

var PAUSED:bool = false

@export var SPEED:float = 300.0
@export var JUMP_VELOCITY:float = -400.0
@export var DOUBLE_JUMP: int = 2
@export var COYOTE_TIME:float = .25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity:float = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_jump:bool = false
var jumps:int = 0

@onready var _coyote_timer : Timer

func _stop_coyote_timer():
	if _coyote_timer != null:
		_coyote_timer.stop()
		remove_child(_coyote_timer)
	
	_coyote_timer = null


func _start_coyote_timer():
	if _coyote_timer != null: 
		_stop_coyote_timer()

	_coyote_timer = Timer.new()
	_coyote_timer.wait_time = COYOTE_TIME
	_coyote_timer.one_shot = true
	add_child(_coyote_timer)
	_coyote_timer.start()


func _physics_process(delta):
	# Pause player movement
	if PAUSED: return

	# Add the gravity.
	if not is_on_floor():	
		velocity.y += gravity * delta

	# Apply controllers
	_jump_controller()
	_move_controller()

	# apply velocity
	move_and_slide()


func _move_controller():
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func _jump_controller():
	if not is_on_floor(): 
		if not coyote_jump: 
			_start_coyote_timer()
			coyote_jump = true
	else:
		jumps = 0
		coyote_jump = false
	
	# calculate if player can jump by coyote time or in floor or extra-jump
	var can_jump:bool = ((_coyote_timer != null and _coyote_timer.time_left > 0) or 
		is_on_floor() or (jumps != 0 and jumps < DOUBLE_JUMP))

	# Handle jump
	if Input.is_action_just_pressed("ui_accept"):
		if can_jump:
			velocity.y = JUMP_VELOCITY
			
			_stop_coyote_timer()
			coyote_jump = true
			can_jump = false
			jumps += 1
	