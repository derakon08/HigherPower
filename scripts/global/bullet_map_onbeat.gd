#This script relies on enemies having a Hit() method
extends MultiMeshInstance2D
var preloaded_pool_size : int = 100
var event_cache_size : int = 100
var tick_frequency : float = 0.3
var atlas_height : int
var atlas_width : int
var sprite_size : int

#bullet data
var _bullet_angular_velocity : Array[float]
var _bullet_collision_group : Array[int]
var _bullet_position : Array[Vector2]
var _bullet_rotation : Array[float]
var _bullet_ticks : Array[int]
var _bullet_movement : Array[Callable]
var _bullet_speed : Array[float]
var _bullet_size : Array[float]

#collision variables
var _collision_group_node_positions : Array[Array] = [[]]
var _collision_group_node_radius : Array[Array] = [[]]
var _collision_group_nodes : Array[Array] = [[]]

var _collision_group_names : Array[String]
var _collision_groups : Dictionary = {"dummy" : 0}

#event variables
var _ticks_clock : float
var _event_schedule : Array[Array]
var _event_schedule_index : int

var _pool_size : int
var _dead_bullets : Array

var _spare_transform : Transform2D
var _vector2_right : Vector2 = Vector2(1, 0)
var _allow_shooting
var _paused : bool = false

#Callable references
#To-do

#Bullet callables
var _movement_methods : Array[Callable] = [_MovementDefault]
var _position_methods : Array[Callable] = [_PositionDefault]
var _rotation_methods : Array[Callable] = [_RotationDefault]

enum RotationType {default, follow_rotation, follow_objective, changing}
enum PositionType {default, knot, flower, star, spiral, elipse, experimental}
enum MovementType {default, reverse, set_speed, change_speed, flower_bloom, reverse_bloom, star, spiral, waves, pulse, stop} 

#Event callables
var _events : Array[Callable] = []

enum EventType {}


signal spawner_cleared
signal tick_event
signal tick







#Private functions

func _ready() -> void:
	#set multimesh and timer
	multimesh = MultiMesh.new()
	multimesh.set_mesh(QuadMesh.new())
	multimesh.visible_instance_count = -1

	if texture == null:
		texture = CanvasTexture.new()

	ResetPoolSize()

	_paused = false


func _physics_process(delta: float) -> void:
	if !_paused:
		_ticks_clock += delta

		for group in _collision_group_nodes.size():
			for node in _collision_group_nodes[group]:
				_collision_group_node_positions[group][node] = node.global_position
		
		_SetBulletMesh()
		_CheckBulletCollision()

		for index in _pool_size:
			if _bullet_ticks[index] > 0:
				_bullet_movement[index].call(delta)

		while _ticks_clock >= tick_frequency:
			_ticks_clock -= tick_frequency
			_EventTick()
			_BulletTick()

			tick.emit()
		

#subtracts bullet ticks and checks if it's dead then, so bullets die right after tick 1
func _BulletTick():
	for index in _pool_size:
		if _bullet_ticks[index] > 0:
			_bullet_ticks[index] -= 1

			if _bullet_ticks[index] < 1:
				_dead_bullets.append(index)
				multimesh.set_instance_transform_2d(index, _spare_transform * 0)


func _EventTick() -> void:
	if _event_schedule_index >= _event_schedule.size(): _event_schedule_index = 0

	if !_event_schedule[_event_schedule_index].is_empty():
		for event in _event_schedule[_event_schedule_index]:
			event #i haven't thought about events yet
		
		_event_schedule[_event_schedule_index].clear()

	
	_event_schedule_index += 1

	tick_event.emit()


func _SetBulletMesh() -> void: #sets mesh instances using the bullet data
	for index in _pool_size:
		if _bullet_ticks[index] > 0:
			_spare_transform = Transform2D(_bullet_rotation[index] - global_rotation, to_local(_bullet_position[index]))
			_spare_transform.x *= _bullet_size[index] * 1.1
			_spare_transform.y *= _bullet_size[index] * 1.1
			multimesh.set_instance_transform_2d(index, _spare_transform)


func _CheckBulletCollision() -> void:
	#Get the node position for the bullet's collision group
	for index in _pool_size:
		for node_index in _collision_group_node_positions[_bullet_collision_group[index]].size():
			if ((_bullet_position[index] - _collision_group_node_positions[_bullet_collision_group[index]][node_index]).length_squared() < #get the distance between the node and the bullet
				(_collision_group_node_radius[_bullet_collision_group[index]][node_index] + _bullet_size[index] * 0.5) **2 #If their sizes together are greater than the distance, they overlap
				):
				_collision_group_nodes[_bullet_collision_group[index]][node_index].Hit()


func _RemoveObjectiveFromGroup(group_name : String, node : Node) -> void:
	if !_collision_groups.has(group_name):
		push_warning("Invalid collision group for node removal: " + group_name)
		return

	for group in _collision_group_nodes[_collision_groups[group_name]]:
		for node_index in group.size():
			if group[node_index] == node:
				_JaggedSwapItemBackAndPop(
					[
					_collision_group_nodes,
					_collision_group_node_radius,
					_collision_group_node_positions
					],
					node_index
				)

				return

			else:
				continue


func _ClearBullets(kill : bool = false) -> void:
	_dead_bullets.clear()

	for index in _pool_size:
		if (_bullet_ticks[index] > 0):
			multimesh.set_instance_transform_2d(index, _spare_transform * 0)
			_bullet_ticks[index] = -1
			if !kill: 
				await get_tree().process_frame

	_pool_size = 100
	spawner_cleared.emit()


func _SwapItemBackAndPop(arrays : Array[Array], index : int) -> void:
	for external_index in arrays.size(): #for each array passed
		arrays[external_index][index] = arrays[external_index][arrays[external_index].size() - 1] #place the item (arrays) in last place to the index given
		arrays[external_index].pop_back() #delete duplicate


func _JaggedSwapItemBackAndPop(arrays : Array[Array], index : int) -> void:
	for parameter_array in arrays: #for each jagged array passed
		for inner_index in parameter_array.size() - 1: #for each array inside the array passed
			parameter_array[inner_index][index] = parameter_array[inner_index][parameter_array.size() - 1] #place the item (nodes) in the last place to the index given
			parameter_array.pop_back() #delete the duplicate





#Public methods

func Shoot(bullet_position : Vector2, bullet_speed : float, bullet_duration : int, bullet_rotation : float, bullet_size : float, collision_group : String = "dummy", angular_velocity : float = 0, bullet_movement : MovementType = MovementType.default, bullet_start_position : PositionType = PositionType.default, bullet_start_rotation : RotationType = RotationType.default) -> int:
	if !_allow_shooting:
		return -1
	else:
		await tick
	
	var i : int

	if !_dead_bullets.is_empty():
		i = _dead_bullets.pop_back()

		_bullet_angular_velocity[i] = angular_velocity
		_bullet_collision_group[i] = _collision_groups[collision_group]
		_bullet_position[i] = _position_methods[bullet_start_position].call(bullet_position)
		_bullet_rotation[i] = _rotation_methods[bullet_start_rotation].call(bullet_rotation)
		_bullet_ticks[i] = bullet_duration
		_bullet_movement[i] = _movement_methods[bullet_movement].bind(i)
		_bullet_size[i] = bullet_size

		_bullet_speed[i] = bullet_speed

	else:
		multimesh.instance_count += 1
		i = _pool_size
		_pool_size += 1

		_bullet_angular_velocity.append( angular_velocity)
		_bullet_collision_group.append(_collision_groups[collision_group])
		_bullet_ticks.append(bullet_duration)
		_bullet_position.append(_position_methods[bullet_start_position].call(bullet_position))
		_bullet_rotation.append(_rotation_methods[bullet_start_rotation].call(bullet_rotation))
		_bullet_movement.append(_movement_methods[bullet_movement].bind(i))
		_bullet_size.append(bullet_size)
		
		_bullet_speed.append(bullet_speed)

	return i


func ScheduleBulletEvent(event_tick : int, event_type : EventType, bullet_index : int) -> void:
	if event_tick > 0 && event_tick <= _bullet_ticks[bullet_index]:
		var scheduling_index = _event_schedule_index + event_tick

		if scheduling_index >= event_cache_size: scheduling_index -= event_cache_size

		_event_schedule[scheduling_index].append([bullet_index, _events[event_type]])
	
	else:
		push_warning("Can't schedule an event: Unavailable tick schedule")


func ResetPoolSize() -> void: #reset and fill arrays
	_bullet_angular_velocity.resize(preloaded_pool_size)
	_bullet_collision_group.resize(preloaded_pool_size)
	_bullet_position.resize(preloaded_pool_size)
	_bullet_rotation.resize(preloaded_pool_size)
	_bullet_ticks.resize(preloaded_pool_size)
	_bullet_movement.resize(preloaded_pool_size)
	_bullet_speed.resize(preloaded_pool_size)
	_bullet_size.resize(preloaded_pool_size)

	_dead_bullets.resize(preloaded_pool_size)

	for index in preloaded_pool_size: #delete comments on test success
		#_bullet_angular_velocity.append(0)
		#_bullet_collision_group.append(0)
		_bullet_ticks[index] = -1
		#_bullet_position.append(_vector2_right)
		#_bullet_rotation.append(0)
		#_bullet_movement.append(null)
		#_bullet_size.append(0)
		#_bullet_speed.append(0)

		_dead_bullets[index] = index

	multimesh.instance_count = preloaded_pool_size


func NukeGameBullets() -> void:
	_ClearBullets(true)


func ClearGameBullets() ->void:
	_allow_shooting = false
	_paused = true

	_ClearBullets(false)

	_allow_shooting = true
	_paused = false


func AddNewCollisionGroup(group_name : String) -> void:
	if _collision_groups.has(group_name):
		push_warning("Group already exists: " + group_name)
		return

	_collision_groups[group_name] = _collision_group_nodes.size()
	_collision_group_names.append(group_name)
	
	_collision_group_node_positions.append([])
	_collision_group_node_positions.append([])
	_collision_group_node_radius.append([])
	_collision_group_nodes.append([])


func RemoveCollisionGroup(group_name : String) -> void:
	if group_name == "dummy":
		push_error("Don't play dumb games")

	elif _collision_groups.has(group_name):
		if group_name != _collision_group_names[_collision_group_names.size() - 1]:
			_collision_groups[_collision_group_names[_collision_group_names.size() - 1]] = _collision_groups[group_name]
		
		_SwapItemBackAndPop(
			[
			_collision_group_nodes, 
			_collision_group_node_radius, 
			_collision_group_node_positions, 
			_collision_group_names
			], 
			_collision_groups[group_name])

		_collision_group_node_positions.pop_back() #resize group count
		_collision_groups.erase(group_name)

	else:
		push_warning("Trying to remove non existent group: " + group_name)


func AddObjectiveToGroup(group_name : String, node : Node, hitbox_radius : float) -> void:
	if group_name == "dummy" || !_collision_groups.has(group_name):
		push_warning("Invalid collision group for new node: " + group_name)
		return

	_collision_group_nodes[_collision_groups[group_name]].append(node)
	_collision_group_node_radius[_collision_groups[group_name]].append(hitbox_radius)
	_collision_group_node_positions[_collision_groups[group_name]].append(_vector2_right)


func RemoveObjectiveFromGroup(group_name : String, node : Node) ->void:
	if group_name == "dummy":
		push_warning("Invalid collision group for node removal: " + group_name)
		return

	_RemoveObjectiveFromGroup.call_deferred(group_name, node)


func Pause():
	_paused = true


func Unpause():
	_paused = false





#Top Callables

#Movement

func _MovementDefault(index : int, delta : float) -> void:
	_bullet_position[index] += _vector2_right.rotated(_bullet_rotation[index]) * _bullet_speed[index] * delta
	_bullet_rotation[index] += _bullet_angular_velocity[index]


#Position

func _PositionDefault(pos : Vector2) -> Vector2:
	return pos


#Rotation

func _RotationDefault(rot : float) -> float:
	return rot