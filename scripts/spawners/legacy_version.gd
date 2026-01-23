extends MultiMeshInstance2D 
#i'm quite proud of this one, perhaps even more than the shape script

#settings, you know the drill
#actually i don't... each time i refactor the settings become more and more complex
@export_category("Density Settings")
@export var bullet_density : int #number of bullets in the wall

var  _bullets_max_angle : float
@export var bullets_max_angle : float:
	set(degrees):
		_bullets_max_angle = deg_to_rad(degrees) #conversion in setter to allow changes during runtime
		_spacing = _bullets_max_angle / bullet_density

		if degrees != 360:
			_angle += _bullets_max_angle * -0.5 #center the wall
	get:
		return rad_to_deg(_bullets_max_angle)

@export_category("Spawner Settings")
@export var stream_number : int
@export var fire_rate  : float #mustn't be less than 0.1

var _angle_between_spawns : float
@export var angle_between_spawns : float:
	set(degrees):
		_angle_between_spawns = deg_to_rad(degrees) #conversion to allow changes at runtime
	get:
		return rad_to_deg(_angle_between_spawns)

var _wait_between_spawns : float
@export var wait_between_spawns : float:
	set (value):
		_COOLDOWN_TIMER.set_process(value > 0)
		_wait_between_spawns = value
	get:
		return _wait_between_spawns
@export var _COOLDOWN_TIMER : Node #Timer for space between streams

@export var spawn_offset : Vector2
@export var objective : Area2D
@export var auto_start : bool = false

var _one_shot : bool
@export var one_shot : bool = false:
	set (value):
		_pool_index = 0
		_one_shot = value
		if (value):
			_clip_bullets = false
	get:
		return _one_shot

@export var allow_collision : bool = true


@export var delay_spawns : bool

@export_group("Options")
var CalculatePosition : Callable = Callable(self, &"PositionCalcNone")
var CalculateRotation : Callable = Callable(self, &"RotationCalcNone")
var CalculateMovement : Callable = Callable(self, &"MovementNone")
#The presets system
#each setter checks what preset is selected and changes the function at runtime
#Note: Setters are only called at initialization if their default value is changed, otherwise it will not be called AT ALL
@export_subgroup("Position")
@export var position_peaks : int:
	set (value):
		position_peaks_constant = value * PI/360
	get:
		return position_peaks_constant * 360/PI as int

@export var max_peaks_value : float = -1:
	set (value):
		_max_peaks_value.x = value
	get:
		return _max_peaks_value.x

@export var position_min_peaks_value : float
@export var peak_sharpness : float = 1
@export var position_waves_value : float = 0.0
@export var elipse_shape : Vector2

@export var position_preset : PositionType:
	set(value):
		preset_get[0] = value
		match value:
			PositionType.none:
				CalculatePosition = Callable(self, &"PositionCalcNone")
			PositionType.knot:
				CalculatePosition = Callable(self, &"PositionCalcKnot")
			PositionType.flower:
				CalculatePosition = Callable(self, &"PositionCalcFlower")
			PositionType.star:
				CalculatePosition = Callable(self, &"PositionCalcStar")
			PositionType.spiral:
				CalculatePosition = Callable(self, &"PositionCalcSpiral")
			PositionType.elipse:
				CalculatePosition = Callable(self, &"PositionCalcElipse")
			PositionType.experimental:
				CalculatePosition = Callable(self, &"PositionCalcExperimental")
	get:
		return preset_get[0]


@export_subgroup("Rotation")
@export var rotating_strength : float
@export var rotation_preset : RotationType:
	set(value):
		preset_get[1] = value
		match (value):
			RotationType.none:
				CalculateRotation = Callable(self, &"RotationCalcNone")
			RotationType.follow_rotation:
				CalculateRotation = Callable(self, &"RotationCalcFollowRotation")
			RotationType.follow_objective:
				CalculateRotation = Callable(self, &"RotationCalcFollowObjective")
			RotationType.changing:
				CalculateRotation = Callable(self, &"RotationCalcChanging")
	get:
		return preset_get[1]


@export_subgroup("Movement")
@export var movement_peaks : int:
	set(value):
		movement_peaks_constant = rad_to_deg(value * PI/360)
	get:
		return deg_to_rad(movement_peaks_constant * 360/PI) as int

@export var movement_min_peaks_value : float
@export var movement_waves_frequency : float
@export var movement_speed_change : float

@export var movement_preset  : MovementType:
	set (value):
		preset_get[2] = value
		match value:
			MovementType.none:
				CalculateMovement = Callable(self, &"MovementNone")
			MovementType.reverse:
				CalculateMovement = Callable(self, &"MovementReverse")
			MovementType.change_speed:
				CalculateMovement = Callable(self, &"MovementChange")
			MovementType.set_speed:
				CalculateMovement = Callable(self, &"MovementSet")
			MovementType.flower_bloom:
				CalculateMovement = Callable(self, &"MovementBloom")
			MovementType.reverse_bloom:
				CalculateMovement = Callable(self, &"MovementReverseBloom")
			MovementType.star:
				CalculateMovement = Callable(self, &"MovementStar")
			MovementType.spiral:
				CalculateMovement = Callable(self, &"MovementSpiral")
			MovementType.waves:
				CalculateMovement = Callable(self, &"MovementWaves")
			MovementType.pulse:
				CalculateMovement = Callable(self, &"MovementPulse")
			MovementType.stop:
				CalculateMovement = Callable(self, &"MovementStop")
			
	get:
		return preset_get[2]

@export_category("Bullet Settings")
@export var stream_final_speed : float #mustn't be less than 1
@export var stream_start_speed : float
@export var angular_velocity : float:
	set(degrees):
		_angular_velocity = deg_to_rad(degrees)
	get:
		return rad_to_deg(_angular_velocity)
var _angular_velocity : float
@export var bullet_max_distance : float #mustn't be less than 1
@export var bullet_size : float = 1

var _clip_bullets : bool
@export var clip_bullets : bool:
	set (value):
		_clip_bullets = value
		if (value):
			_one_shot = false
	get:
		return _clip_bullets

#bullet data
var _bullet_position : PackedVector2Array
var _bullet_rotation : PackedFloat32Array
var _bullet_speed : PackedFloat32Array
var _bullet_active : Array
var _speed_step : float #difference in speed between bullets in a stream
var _spacing : float = 0

#collision variables
var _objective_hitbox_radius : float
var _collision_check_radius : float
var _visible_area : Rect2

#these hold pooling data
var _pool_size : int
var _pool_index : int = 0
var _dead_bullets : Array

var _is_alive : bool = false

#cache variables
var _angle : float = 0 #spawner direction
var _to_be_fired : float = 1 #number of bullets this frame
var _stream_index : int
var _allow_movement : bool = false
var _allow_shooting : bool = false

#used in presets
var position_peaks_constant : float
var movement_peaks_constant : float
var _rotating_strength : float
var movement_waves_clock : float
var _max_peaks_value : Vector2 = Vector2(-1,0)
var preset_get : Array = [0, 0, 0] #keep track of what presets are selected

enum RotationType {none, follow_rotation, follow_objective, changing}
enum PositionType {none, knot, flower, star, spiral, elipse, experimental}
enum MovementType {none, reverse, set_speed, change_speed, flower_bloom, reverse_bloom, star, spiral, waves, pulse, stop} 

signal collision
signal stream_over
signal end_of_pool
signal spawner_ready
signal spawner_cleared

func _ready() -> void:
	#set multimesh and timer
	multimesh = MultiMesh.new()
	multimesh.set_mesh(QuadMesh.new())

	_COOLDOWN_TIMER.timeout.connect(AllowShooting)
	_COOLDOWN_TIMER.set_process(_wait_between_spawns > 0)

	_visible_area = Main.game_area.grow(bullet_size * 2)

	if texture == null:
		texture = CanvasTexture.new()

	#defaults to the player and connects to Hit function
	if objective == null:
		objective = Main.player
	_objective_hitbox_radius = objective.get_node("CollisionShape2D").shape.radius * objective.scale.y
	collision.connect(objective.Hit)

	_allow_movement = auto_start
	_allow_shooting = auto_start

	RePooling()

func RePooling(): #This can be run many times to change some important settings
	var temp_settings : Array = [allow_collision, _allow_movement, _allow_shooting]
	allow_collision = false
	_allow_movement = false
	_allow_shooting = false

	# check for invalid values
	if (!_EnsureSpawnerSettings() || !_EnsureBulletSettings()):
		print("Invalid value in " + get_parent().name + '/' + name)
	else:
		_collision_check_radius = (bullet_size * 0.5 + _objective_hitbox_radius) ** 2 #simple collision check radius, little logic needed
		_stream_index = 0

		_spacing = _bullets_max_angle / bullet_density

		if bullets_max_angle != 360:
			_angle += _bullets_max_angle * -0.5 #center the wall

		_CalculatePoolSize()
		_PoolBullets()

		if auto_start: #kinda ugly, but will do
			allow_collision = temp_settings[0]
			_allow_movement = temp_settings[1]
			_allow_shooting = temp_settings[2]

func _physics_process(delta: float) -> void:
	var vector = Vector2(1,0)
	movement_waves_clock += delta
	_is_alive = false
	for index in _pool_size: #move and collide
		if _bullet_active[index]:
			_is_alive = true
			_CheckCollision(index)

		if _allow_movement && _bullet_speed[index] != 0:
			_bullet_position[index] += vector.rotated(_bullet_rotation[index]) * CalculateMovement.call(index) * delta
			_bullet_rotation[index] += _angular_velocity * delta

func _process(delta: float) -> void:
	if (_bullet_active.size() >= _pool_size): #if pool ready
		_SetMeshes()

	if (_allow_shooting): #shoot if told and allowed
		_to_be_fired += fire_rate * delta

		if (_stream_index >= stream_number): #stream ended, apply logic
			_stream_index = 0
			_COOLDOWN_TIMER.Start(_wait_between_spawns)
			_angle += _angle_between_spawns
			_allow_shooting = wait_between_spawns == 0
			stream_over.emit()
		elif (_to_be_fired > 1):
			_Shoot()
			_to_be_fired -= 1




#Frequent helpers
func _Shoot(): #should be overriden
	#added because of await in delay spawns
	var temp_stream_index = _stream_index
	var pending_bullet_index = []
	var i = 0 #actually comes from the dead bullets managing, but doubles as a safeguard
	var temp_angle = _angle #keep track of the global and per round _angle separately

	_stream_index += 1

	for bullet in bullet_density:
		if _dead_bullets.size() > bullet_density && !_one_shot:
			i = _dead_bullets.pop_front()
		else:
			i = _pool_index
			_pool_index += 1

			if _pool_index >= _pool_size:
				end_of_pool.emit()
				_pool_index = 0
				_allow_shooting = !_one_shot

		_bullet_active[i] = true
		_bullet_position[i] = CalculatePosition.call(temp_angle)
		_bullet_rotation[i] = CalculateRotation.call(temp_angle, i)

		temp_angle += _spacing

		if delay_spawns && _allow_shooting:
			_bullet_speed[i] = 0
			pending_bullet_index.append(i)
			await get_tree().process_frame
		else:
			_bullet_speed[i] = stream_start_speed + (_speed_step * temp_stream_index)
	
	for index in pending_bullet_index.size():
		_bullet_speed[pending_bullet_index[index]] = stream_start_speed + (_speed_step * temp_stream_index)

func _SetMeshes(): #sets mesh instances using the bullet data
	var scaler := Transform2D()
	var unrender := Transform2D.IDENTITY * 0
	
	for index in _pool_size:
		if _bullet_active[index]:
			scaler = Transform2D(_bullet_rotation[index] - global_rotation, to_local(_bullet_position[index]))
			scaler.x *= bullet_size * 1.1
			scaler.y *= bullet_size * 1.1
			multimesh.set_instance_transform_2d(index, scaler)
		else:
			multimesh.set_instance_transform_2d(index, unrender)

func _CheckCollision(index : int):
	if (allow_collision && (_bullet_position[index] - objective.global_position).length_squared() < _collision_check_radius):
		collision.emit()
	elif (_clip_bullets && !_visible_area.has_point(_bullet_position[index])): #kill bullet if out of bounds
		_bullet_speed[index] = 0
		_bullet_active[index] = false
		_dead_bullets.push_back(index)

func _PoolBullets(): #reset and fill arrays
	_bullet_rotation = []
	_bullet_position = []
	_bullet_speed = []
	_bullet_active = []

	for i in _pool_size:
		_bullet_position.append(Vector2.ZERO)
		_bullet_rotation.append(0)
		_bullet_speed.append(0)
		_bullet_active.append(false)

	print("pooled ", _pool_size)
	multimesh.instance_count = _pool_size
	multimesh.visible_instance_count = _pool_size
	spawner_ready.emit()

func _CalculatePoolSize(): #calculate how many bullets per stream
	_pool_size = 0
	if stream_final_speed != 0 && stream_number > 1:
		_speed_step = (stream_final_speed - stream_start_speed) / (stream_number - 1)

		for i in stream_number:
			var speed = abs(stream_start_speed + _speed_step * i)
			if speed == 0:
				speed = 0.1
			_pool_size += ceil((bullet_max_distance / speed) / (1 / fire_rate))
	else:
		_speed_step = 0
		_pool_size += ceil((bullet_max_distance / stream_start_speed) / (1 / fire_rate))
	_pool_size *= bullet_density


#Extra helpers and methods
func SetSpawner(on : bool = true):
	if (_bullets_max_angle != TAU):
		_angle = _bullets_max_angle * -0.5 #center the wall
	else:
		_angle = 0

	_allow_movement = on
	allow_collision = on
	_allow_shooting = on
	_is_alive = on

func AllowShooting():
	_allow_shooting = true

func StopShooting():
	_COOLDOWN_TIMER.Stop()
	_allow_shooting = false

func StopMovement():
	_allow_movement = false

func AllowMovement():
	_allow_movement = true

func _ClearBullets(kill : bool = false):
	var unrender := Transform2D.IDENTITY * 0
	var temp_delay_spawns_bool : bool

	if kill:
		queue_free()
		return
	else:
		temp_delay_spawns_bool = delay_spawns
		_pool_index = 0
		_dead_bullets = []

	delay_spawns = false

	for index in _pool_size:
		if (_bullet_active[index]):
			multimesh.set_instance_transform_2d(index, unrender)
			_bullet_speed[index] = 0
			_bullet_position[index] = Vector2.ZERO
			_bullet_rotation[index] = 0
			_bullet_active[index] = false
			if !kill: 
				await get_tree().process_frame

	delay_spawns = temp_delay_spawns_bool
	spawner_cleared.emit()

func KillSpawner(): #delete node
	SetSpawner(false)
	call_deferred(&"_ClearBullets", true)
func ClearSpawner():
	SetSpawner(false)
	call_deferred(&"_ClearBullets", false)

func IsAlive() -> bool:
	return _is_alive


#Ensure settings
func _EnsureSpawnerSettings() -> bool:
	return stream_number > 0 && fire_rate > 0 || bullet_density > 0

func _EnsureBulletSettings():
	return abs(stream_start_speed) > 0 && bullet_size > 1

#Presets POSITION
func PositionCalcNone(base_angle : float): #Position around spawner
	return global_position + spawn_offset.rotated(base_angle)
func PositionCalcKnot(base_angle : float): #nvm, can't explain it
	return global_position + _max_peaks_value.rotated(base_angle) * sin(rad_to_deg(base_angle) * position_peaks_constant + _angle + rotation)
func PositionCalcFlower(base_angle : float):
	return global_position + _max_peaks_value.rotated(base_angle) * max(abs(sin(rad_to_deg(base_angle) * position_peaks_constant + _angle + rotation)) **peak_sharpness, position_min_peaks_value)
func PositionCalcStar(base_angle : float):
	return global_position + _max_peaks_value.rotated(base_angle) * max(abs(tri_wave(rad_to_deg(base_angle) * position_peaks_constant + _angle + rotation))  **peak_sharpness, position_min_peaks_value)
func PositionCalcSpiral(base_angle):
	return global_position + _max_peaks_value.rotated(base_angle) * max(abs(saw_wave(rad_to_deg(base_angle) * position_peaks_constant + _angle + rotation))  **peak_sharpness, position_min_peaks_value)
func PositionCalcElipse(base_angle : float):
	return global_position + Vector2(cos(base_angle) * elipse_shape.x, sin(base_angle) * elipse_shape.y)
func PositionCalcExperimental(base_angle : float):
	return global_position + _max_peaks_value.rotated(base_angle) * sin(rad_to_deg(base_angle) * position_peaks_constant * position_waves_value)

#Presets ROTATION
func RotationCalcNone(base_angle : float, _index = null):
	return global_rotation + base_angle
func RotationCalcFollowRotation(_base_angle = null, _index = null):
	return global_rotation
func RotationCalcChanging(base_angle : float, _index = null):
	_rotating_strength += rotating_strength
	return global_rotation + base_angle + _rotating_strength
func RotationCalcFollowObjective(_base_angle, index : int):
	return atan2( #atan is a function which returns the _angle between the base of a right triangle, and the hypotenuse
			_bullet_position[index].y - objective.global_position.y,
			_bullet_position[index].x - objective.global_position.x) + PI

#Presets MOVEMENT
func MovementNone(index : int):
	return _bullet_speed[index]
func MovementReverse(index : int):
	return -_bullet_speed[index]
func MovementChange(index : int):
	return _bullet_speed[index] + movement_speed_change
func MovementSet(_index = null):
	return movement_speed_change
func MovementBloom(index : int):
	return _bullet_speed[index] * max(abs(sin(_bullet_rotation[index] * movement_peaks_constant + _angle + rotation)), movement_min_peaks_value)
func MovementReverseBloom(index : int):
	return _bullet_speed[index] * max(sin(_bullet_rotation[index] * movement_peaks_constant + _angle + rotation), movement_min_peaks_value)
func MovementStar(index : int):
	return _bullet_speed[index] * max(tri_wave(_bullet_rotation[index] * movement_peaks_constant + _angle + rotation), movement_min_peaks_value)
func MovementSpiral(index : int):
	return _bullet_speed[index] * max(saw_wave(_bullet_rotation[index] * movement_peaks_constant + _angle + rotation), movement_min_peaks_value)
func MovementWaves(index : int):
	return _bullet_speed[index]  * tri_wave(movement_waves_clock * movement_waves_frequency)
func MovementPulse(index : int):
	return _bullet_speed[index] * saw_wave(movement_waves_clock * movement_waves_frequency)
func MovementStop(_index : int):
	return 0


func tri_wave(x): #goes up fast and down fast
	var f = x / PI
	return abs((f - floor(f)) * 2.0 - 1.0)
func saw_wave(x): #goes up and then down instantly
	var f = x / PI
	return f - floor(f)
	
