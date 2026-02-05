extends ENEMY

@export var bullet_start_speed : float :
	set (value):
		_stream_start_speed = value
		_speed_step = _stream_end_speed - value / stream_density
		print(_speed_step)
	
	get:
		return _stream_start_speed

@export var stream_end_speed : float :
	set (value):
		_stream_end_speed = value
		_speed_step = value - _stream_start_speed / stream_density
		print(_speed_step)
	
	get:
		return _stream_end_speed

@export var bullet_lifetime : float
@export var bullet_sprite : int
@export var bullet_offset : Vector2
@export var bullet_size : float
@export var bullet_collision_multiplier : float

@export var bullet_density : int :
	set (value):
		_bullet_density = value
		_spacing = _bullets_max_angle / value
	
	get:
		return _bullet_density

@export var bullets_max_angle : float:
	set(degrees):
		_bullets_max_angle = deg_to_rad(degrees)
		_spacing = _bullets_max_angle / bullet_density

		if degrees != 360:
			_angle = _bullets_max_angle * 0.25 #center the wall downwards (?
	get:
		return rad_to_deg(_bullets_max_angle)

@export var aim_at_player : bool


var _bullet_density : int
var _bullets_max_angle : float
var _stream_start_speed : float
var _stream_end_speed : float

var _angle : float
var _spacing : float
var _current_bullet_position : Vector2
var _temp_angle : float
var _speed_step : float

func _ModeOne():
	if _to_be_fired > 1:
		_to_be_fired -= 1

		for stream_bullet in stream_density:
			_temp_angle = _angle

			for bullet in bullet_density:
				_current_bullet_position = global_position + Vector2(
					bullet_offset.x * cos(_temp_angle), 
					bullet_offset.y * sin(_temp_angle)
					).rotated(global_rotation)
				
				BulletMap.Shoot(
					_current_bullet_position,
					_stream_start_speed + _speed_step * stream_bullet ,
					bullet_lifetime, #make it so if the bullet is slower the lifetime increases to match the other bullets lifetimes
					(Main.player.global_position - _current_bullet_position).angle() if aim_at_player else _temp_angle + rotation,
					bullet_size,
					"player",
					bullet_sprite,
					0,
					Vector2(0,0),
					bullet_collision_multiplier
				)

				_temp_angle += _spacing

func _ModeTwo():
	_ModeOne()


func _OnWarpAction():
	super._OnWarpAction()

	if _attack_mode:
		_angle /= 1.5
		_spacing *= 2
	
	else:
		_angle *= 1.5
		_spacing /= 2
			

			
			


