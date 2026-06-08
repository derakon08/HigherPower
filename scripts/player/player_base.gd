extends Area2D
@export var invinsibility_timer : Timer
@export var bomb_cooldown_timer : Timer
@export_range(0.0, 1.1) var GAMEPAD_DEADZONE : float = 0.03
@export var normal_speed : float = 500.0
@export var focus_speed : float = 100.0
@export var acceleration : float = 1.0
@export var deceleration : float = 1.0
@export var rotation_strenght : float = 1.0
@export var fire_rate : float = 1000

##This's been exported since i NEED the setter to activate
@export var shoot_mode : bool:
	set (value):
		_shoot_mode = value

		if (value):
			_Shoot = _ModeOne
		else:
			_Shoot = _ModeTwo
	get:
		return _shoot_mode

var aprox_radius : float = 0

var _focus = false
var _allow_shooting : bool = false

var _Shoot : Callable = Callable(_ModeOne)
var _shoot_mode : bool

var _to_be_fired : float
var _transition_node : Node
var _particle_explosion : GPUParticles2D
var _particle_trail : GPUParticles2D
var _vulnerable : bool = false
var _bomb_ready : bool = true

var _current_speed : float = 0.0
var _direction : Vector2 = Vector2(0, 1)

@warning_ignore_start("unused_private_class_variable")
var _atlas_sprite : int = 4

const EMITING_LIMIT : float = 50

signal player_hit




func _ready() -> void:
	Switch(false)
	_particle_explosion = $ParticlesExplosion
	_particle_trail = $Trail
	_transition_node = %Trans
	aprox_radius = get_node("CollisionShape2D").shape.radius

	_transition_node.stream_over.connect(_BombEnd)
	invinsibility_timer.timeout.connect(_Vulnerable.bind(true))
	bomb_cooldown_timer.timeout.connect(BombReady.bind(true))


func _physics_process(delta: float) -> void:
	var input_vector : Vector2 = Input.get_vector("left", "right", "up", "down", 0.0)

	if input_vector.length() > GAMEPAD_DEADZONE:
		_current_speed = lerp(_current_speed, (focus_speed if _focus else normal_speed), acceleration)
		_direction = lerp(_direction, input_vector, rotation_strenght)
		
	
	else:
		_current_speed = lerp(_current_speed, 0.0, deceleration)
		

	position += _direction * _current_speed * delta


func _process(delta: float) -> void:
	if _current_speed > EMITING_LIMIT:
		_particle_trail.speed_scale = _current_speed * delta
		_particle_trail.lifetime = _current_speed * delta
		_particle_trail.emitting = true
	else:
		_particle_trail.emitting = false

	if (_allow_shooting && _vulnerable):
		_to_be_fired += fire_rate * delta
		_Shoot.call()


func _input(event : InputEvent) -> void:
	if event is InputEventJoypadMotion:
		if event.is_action("shoot"):
			_allow_shooting = event.axis_value > 0.3

		elif event.is_action("focus"):
			_focus = event.axis_value > 0.5
		
		elif _bomb_ready && event.is_action("ship_action") && event.axis_value > 0.4:
			_BombStart()
		
		return

	if event.is_action("shoot"):
		_allow_shooting = event.pressed

	elif event.is_action("focus"):
		_focus = event.pressed
	
	elif _bomb_ready && event.is_action("ship_action"):
		_BombStart()


func _BombStart():
	_Vulnerable(false)
	_bomb_ready = false
	shoot_mode = !_shoot_mode

	Main.warp.emit()
	bomb_cooldown_timer.start()
	_transition_node.SetSpawner(true)


func _BombEnd():
	_transition_node.StopSpawner()
	Main.InvertBackgroundColor()
	BulletMap.NukeGameBullets()


func _GetPlayerAim() -> float:
	var strength : Vector2 = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")

	if strength.length() > GAMEPAD_DEADZONE:
		return strength.angle()
	
	return (get_viewport().get_mouse_position() - global_position).normalized().angle()





func Hit(_args):
	if _vulnerable:
		_Vulnerable(false)
		_particle_explosion.emitting = true
		player_hit.emit()


func Switch(on : bool):
	set_physics_process(on)
	set_process(on)
	set_process_input(on)
	visible = on


func _Vulnerable(on : bool):
	if !on:
		invinsibility_timer.start()

	_vulnerable = on


func BombReady(on = true):
	if on && !Main.narrator.IsTalking():
		Main.narrator.Talk("Get me out of here")
	
	_bomb_ready = on
	bomb_cooldown_timer.stop()



func _ModeOne():
	push_error("OVERRIDE PLAYER MODE ONE")

func _ModeTwo():
	push_error("OVERRIDE PLAYER MODE TWO")