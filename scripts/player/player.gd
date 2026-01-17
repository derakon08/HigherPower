extends Node2D

@export var invinsibility_timer : Timer
@export var bomb_cooldown_timer : Timer
@export var normal_speed : int = 500
@export var focus_speed : int = 100
@export var fire_rate : float
@export var allow_shooting : bool = true

@export_category("bullets")
@export var bullet_speed : float
@export var bullet_distance : float

var _Shoot : Callable = Callable(_ModeOne)
var _shoot_mode : bool = true
@export var shoot_mode : bool = true:
	set (value):
		_shoot_mode = value

		if (value):
			_Shoot = _ModeOne
		else:
			_Shoot = _ModeTwo
	get:
		return _shoot_mode

var focus = false

const _bullet_scene : PackedScene = preload("res://scenes/player/player_bullet.tscn")
var _transition_node : Node
var _pooled_bullets : Array
var _to_be_fired : float
var _pool_size : int
var _pool_index = 0
var _particle_explosion : GPUParticles2D
var _vulnerable : bool = false
var _bomb_ready : bool = true

signal player_hit
signal player_bomb_start
signal player_bomb_end

func _ready() -> void:
	_particle_explosion = $ParticlesExplosion
	_transition_node = $Transition
	_transition_node.AllowMovement()

	_transition_node.end_of_pool.connect(Main.InvertBackgroundColor)
	_transition_node.end_of_pool.connect(player_bomb_end.emit)

	_pool_size += ceil((bullet_distance / bullet_speed) / (1 / fire_rate))
	for i in _pool_size:
		var bullet_instance = _bullet_scene.instantiate()
		bullet_instance.speed = bullet_speed
		bullet_instance.max_distance = bullet_distance
		bullet_instance.Switch(false)
		add_child.call_deferred(bullet_instance)
		_pooled_bullets.append(bullet_instance)

func _physics_process(delta: float) -> void:
	var velocity : Vector2 = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"), Input.get_action_strength("down") - Input.get_action_strength("up"))
	focus = Input.is_action_pressed("focus")

	position += velocity.normalized() * (focus_speed if focus else normal_speed) * delta
	
	if (_bomb_ready && Input.is_action_just_pressed("ship_action") && bomb_cooldown_timer.is_stopped()):
		_ShipAction()
	elif (allow_shooting && Input.is_action_pressed("shoot") && _vulnerable):
		_to_be_fired += fire_rate * delta
		_Shoot.call()
	else:
		_to_be_fired = 0

func _ModeOne():
	if _to_be_fired >= 0.5:
		_pool_index = _pool_index if _pool_index < _pool_size else 0

		_pooled_bullets[_pool_index].Switch(true)
		_pooled_bullets[_pool_index].global_position = global_position
		_pooled_bullets[_pool_index].rotation = global_rotation if focus else global_rotation + randf_range(-20,20) * 0.01745

		_pool_index += 1
		_to_be_fired = 0

func _ModeTwo():
	var angle = deg_to_rad(-2 if focus else -30)
	var angle_step = abs((angle * 2) / (_pool_size))

	if (!focus && _to_be_fired >= _pool_size) || (focus && _to_be_fired >= _pool_size):
		for index in _pool_size:
			_pool_index = _pool_index if _pool_index < _pool_size else 0

			_pooled_bullets[_pool_index].Switch(true)
			_pooled_bullets[_pool_index].global_position = global_position
			_pooled_bullets[_pool_index].rotation = global_rotation + angle

			_pool_index += 1
			angle += angle_step
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
