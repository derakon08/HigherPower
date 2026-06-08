extends Node2D
@export var bullet_density : int :
	set (value):
		_bullet_density = value

		_spacing = _bullets_max_angle / value
	
	get:
		return _bullet_density

@export var stream_number : int = 1
@export var fire_rate  : float
@export var spawn_offset : Vector2
@export var objective : Node2D
@export var auto_start : bool = false
@export var delay_spawns : bool
@export var collision_group : String = "dummy"

@export var bullets_max_angle : float:
	set(degrees):
		_bullets_max_angle = deg_to_rad(degrees)
		
		if bullet_density > 1:
			_spacing = _bullets_max_angle / (bullet_density - 1)
		
		else:
			_spacing = 0

	get:
		return rad_to_deg(_bullets_max_angle)

@export var angle_between_streams : float:
	set(degrees):
		_angle_between_streams = deg_to_rad(degrees) #conversion to allow changes at runtime
	get:
		return rad_to_deg(_angle_between_streams)

@export var angle_between_bullets : float:
	set(degrees):
		_angle_between_bullets = deg_to_rad(degrees) #conversion to allow changes at runtime
	get:
		return rad_to_deg(_angle_between_bullets)

@export_group("Wait between spawns")
@export var use_timer : bool = false
@export var wait_between_spawns : float:
	set (value):
		if use_timer: _COOLDOWN_TIMER.set_process(value > 0)
		_wait_between_spawns = value
	get:
		return _wait_between_spawns
@export var _COOLDOWN_TIMER : Node #Timer for space between streams


@export_category("Bullet settings")
@export var stream_final_speed : float = 0.0:
	set (value):
		_stream_final_speed = value
		if (value - stream_start_speed) > 0:
			_speed_step = (value - stream_start_speed) / stream_number
		else:
			_speed_step = 0.0
	
	get:
		return _stream_final_speed


@export var stream_start_speed : float = 0.0 :
	set (value):
		_stream_start_speed = value
		if (stream_final_speed - value) > 0:
			_speed_step = (stream_final_speed - value) / stream_number
		else:
			_speed_step = 0.0
	
	get:
		return _stream_start_speed

@export var angular_velocity : float:
	set(degrees):
		_angular_velocity = deg_to_rad(degrees)
	get:
		return rad_to_deg(_angular_velocity)

@export var bullet_max_distance : float
@export var bullet_size : float = 1
@export var bullet_sprite : int = 0

@export_group("Options")
var CalculatePosition : Callable = _CalcPositionOffset
var CalculateRotation : Callable = RotationCalcNone
#The presets system
#each setter checks what preset is selected and changes the function at runtime
#Note: Setters are only called at initialization if their default value is changed, otherwise it will not be called AT ALL
@export_subgroup("Position")
@export var position_peaks : int:
	set (value):
		position_peaks_constant = value * PI/360
	get:
		return position_peaks_constant * 360/PI as int

@export var position_min_peaks_value : float
@export var peak_sharpness : float = 1
@export var position_waves_value : float = 0.0

@export var position_preset : PositionType:
	set(value):
		preset_get[0] = value
		match value:
			PositionType.none:
				CalculatePosition = _CalcPositionOffset
			PositionType.knot:
				CalculatePosition = PositionCalcKnot
			PositionType.flower:
				CalculatePosition = PositionCalcFlower
			PositionType.star:
				CalculatePosition = PositionCalcStar
			PositionType.spiral:
				CalculatePosition = PositionCalcSpiral
			PositionType.experimental:
				CalculatePosition = PositionCalcExperimental
	get:
		return preset_get[0]


@export_subgroup("Rotation")
@export var rotating_strength : float
@export var rotation_preset : RotationType:
	set(value):
		preset_get[1] = value
		match (value):
			RotationType.none:
				CalculateRotation = RotationCalcNone
			RotationType.follow_rotation:
				CalculateRotation = RotationCalcFollowRotation
			RotationType.changing:
				CalculateRotation = RotationCalcChanging
	get:
		return preset_get[1]


var _bullet_density : int
var _angle_between_streams : float
var	_angle_between_bullets : float
var _wait_between_spawns : float
var  _bullets_max_angle : float
var _angular_velocity : float

var _stream_start_speed : float = 0.0
var _stream_final_speed : float = 0.0

#bullet data
var _speed_step : float #difference in speed between bullets in a stream
var _spacing : float = 0
var _bullet_deviation : float = 0

#cache variables
var _angle : float = 0 #spawner direction
var _to_be_fired : float = 1 #number of bullets this frame
var _stream_index : int
var _allow_shooting : bool = false

#used in presets
var position_peaks_constant : float
var movement_peaks_constant : float
var _rotating_strength : float
var preset_get : Array = [0, 0, 0] #keep track of what presets are selected

enum RotationType {none, follow_rotation, follow_objective, changing}
enum PositionType {none, knot, flower, star, spiral, elipse, experimental}

signal stream_over

func _ready() -> void:
	if !objective:
		objective = Main.player
	
	if _bullets_max_angle != PI * 2:
		_angle += _bullets_max_angle * -0.5

	_allow_shooting = auto_start


func _process(delta: float) -> void:
	if (_allow_shooting): #shoot if told and allowed
		_to_be_fired += fire_rate * delta


		if !_to_be_fired < 1:
			_Shoot()
			_to_be_fired -= 1

		if _stream_index >= stream_number: #stream ended, apply logic
			_stream_index = 0
			_angle += _angle_between_streams
			_bullet_deviation = 0

			if use_timer && wait_between_spawns != 0: 
				_COOLDOWN_TIMER.Start(_wait_between_spawns)
			_allow_shooting = wait_between_spawns == 0
			stream_over.emit()


func _Shoot():
	#added because of await in delay spawns
	var temp_stream_index = _stream_index
	var pending_bullets_id : Array[Vector2i] = []
	var temp_angle = _angle + _bullet_deviation + rotation #keep track of the global and per round _angle separately

	_stream_index += 1
	_bullet_deviation += _angle_between_bullets

	for bullet in bullet_density:
		if delay_spawns:
			pending_bullets_id.append(
				BulletMap.Shoot(
					CalculatePosition.call(temp_angle),
					0,
					bullet_density,
					CalculateRotation.call(temp_angle),
					bullet_size,
					collision_group,
					bullet_sprite,
					_angular_velocity
				)
				)
			await get_tree().process_frame
		else:
			BulletMap.Shoot(
					CalculatePosition.call(temp_angle),
					stream_start_speed + _speed_step * temp_stream_index,
					bullet_max_distance,
					CalculateRotation.call(temp_angle),
					bullet_size,
					collision_group,
					bullet_sprite,
					_angular_velocity
				)
		
		temp_angle += _spacing
	
	for id in pending_bullets_id:
		BulletMap.TouchSpeed(id, true, stream_start_speed + _speed_step * temp_stream_index)
		BulletMap.TouchLifetime(id, true, bullet_max_distance)


func _CalcPositionOffset(angle : float) -> Vector2:
	return global_position + Vector2(
		spawn_offset.x * cos(angle), 
		spawn_offset.y * sin(angle)
		).rotated(global_rotation)





#Extra helpers and methods
func SetSpawner(on : bool = true):
	if (_bullets_max_angle != TAU):
		_angle = _bullets_max_angle * -0.5 #center the wall
	else:
		_angle = 0

	_allow_shooting = on


func StopSpawner():
	if use_timer: _COOLDOWN_TIMER.Stop()
	_allow_shooting = false


#Presets POSITION
func PositionCalcKnot(angle : float): #nvm, can't explain it
	return _CalcPositionOffset(angle) * sin(rad_to_deg(angle) * position_peaks_constant + _angle + rotation)

func PositionCalcFlower(angle : float):
	return _CalcPositionOffset(angle) * max(abs(sin(rad_to_deg(angle) * position_peaks_constant + _angle + rotation)) **peak_sharpness, position_min_peaks_value)

func PositionCalcStar(angle : float):
	return _CalcPositionOffset(angle) * max(abs(tri_wave(rad_to_deg(angle) * position_peaks_constant + _angle + rotation))  **peak_sharpness, position_min_peaks_value)

func PositionCalcSpiral(angle):
	return _CalcPositionOffset(angle) * max(abs(saw_wave(rad_to_deg(angle) * position_peaks_constant + _angle + rotation))  **peak_sharpness, position_min_peaks_value)

func PositionCalcExperimental(angle : float):
	return _CalcPositionOffset(angle) * sin(rad_to_deg(angle) * position_peaks_constant * position_waves_value)

#Presets ROTATION
func RotationCalcNone(angle : float):
	return global_rotation + angle

func RotationCalcFollowRotation(__angle = null):
	return global_rotation

func RotationCalcChanging(angle : float):
	_rotating_strength += rotating_strength
	return global_rotation + angle + _rotating_strength


func tri_wave(x): #goes up fast and down
	var f = x / PI
	return abs((f - floor(f)) * 2.0 - 1.0)

func saw_wave(x): #goes up and then down instantly
	var f = x / PI
	return f - floor(f)
	

