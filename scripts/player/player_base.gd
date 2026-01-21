extends Area2D
@export var invinsibility_timer : Timer
@export var bomb_cooldown_timer : Timer
@export var normal_speed : int = 500
@export var focus_speed : int = 100
@export var fire_rate : float = 1000
@export var bullet_speed : float = 2000
@export var bullet_distance : float = 2

var focus = false
var allow_shooting : bool = true

var _Shoot : Callable = Callable(_ModeOne)
var _shoot_mode : bool = true
var shoot_mode : bool = true:
	set (value):
		_shoot_mode = value

		if (value):
			_Shoot = _ModeOne
		else:
			_Shoot = _ModeTwo
	get:
		return _shoot_mode

var _to_be_fired : float
var _transition_node : Node
var _particle_explosion : GPUParticles2D
var _vulnerable : bool = false
var _bomb_ready : bool = true

@warning_ignore_start("unused_private_class_variable")
var _atlas_sprite : int = 4
var _account_for_rotation : float = deg_to_rad(global_rotation - 90)
var _aprox_radius = 20
@warning_ignore_restore("unused_private_class_variable")

signal player_hit
signal player_bomb_start
signal player_bomb_end

func _ready() -> void:
	_particle_explosion = $ParticlesExplosion
	_transition_node = $Transition
	_transition_node.AllowMovement()

	_transition_node.end_of_pool.connect(Main.InvertBackgroundColor)
	_transition_node.end_of_pool.connect(player_bomb_end.emit)

func _physics_process(delta: float) -> void:
	var velocity : Vector2 = Input.get_vector("left", "right", "up", "down")
	focus = Input.is_action_pressed("focus")

	position += velocity * (focus_speed if focus else normal_speed) * delta

func _process(delta: float) -> void:
	if (_bomb_ready && Input.is_action_just_pressed("ship_action") && bomb_cooldown_timer.is_stopped()):
		_ShipAction()
	elif (allow_shooting && Input.is_action_pressed("shoot") && _vulnerable):
		_to_be_fired += fire_rate * delta
		_Shoot.call()
	else:
		_to_be_fired = 0

func _ShipAction():
	Vulnerable(false)
	bomb_cooldown_timer.start()
	shoot_mode = !_shoot_mode
	player_bomb_start.emit()
	_transition_node.AllowShooting()

func Hit():
	if _vulnerable:
		Vulnerable(false)
		_particle_explosion.emitting = true
		invinsibility_timer.start()
		player_hit.emit()

func Switch(on : bool):
	self.set_physics_process(on)
	self.visible = on

func Vulnerable(on : bool):
	_vulnerable = on

func BombReady(on = true):
	_bomb_ready = on

func _ModeOne():
	push_error("OVERRIDE PLAYER MODE ONE")

func _ModeTwo():
	push_error("OVERRIDE PLAYER MODE TWO")