##This script relies on enemies having a Hit() method. Bullet map is a bullet manager which will set the position of bullets shot by using the function Shoot
extends MultiMeshInstance2D

##The amount of bullets pre-loaded before any interaction. ResetPoolSize will use this number
@export var preloaded_pool_size : int = 100

##Set according to atlas (texture). Will break if changed during runtime
@export var sprite_size : Vector2 = Vector2(1, 1)

#bullet data
enum bullet_data {POSITION, ROTATION, SPEED, SIZE, COLLISION_GROUP, ANGULAR_VEL, LIFETIME, SPRITE_INDEX, INSTANCE}
var _bullet_data : Array[Array]

#collision variables
var _collision_group_node_positions : Array[Array] = [[]]
var _collision_group_node_radius : Array[Array] = [[]]
var _collision_group_nodes : Array[Array] = [[]]

var _collision_group_names : Array[String]
var _collision_groups : Dictionary = {"dummy" : 0}

#Atlas variables
var _sprites_per_atlas_row : int

#utilities
const _vector2_right : Vector2 = Vector2(1, 0)
var _spare_transform : Transform2D
var _dead_bullets : Array[int]
var _pool_size : int

#state flags
var _allow_shooting : bool = false
var _paused : bool = false


#To-do
#Bullet movement buckets
var _movement_type_buckets : Array[Array] = []
var _movement_type_methods : Array[Callable] = [_MovementDefault] #Set manually

enum MovementType {default}

#signals
signal spawner_cleared







#Private functions

func _ready() -> void:
	if texture == null:
		texture = CanvasTexture.new()
		_sprites_per_atlas_row = 1
	else:
		var _atlas_size : Vector2 = texture.get_size()
		_sprites_per_atlas_row = int(_atlas_size.x / sprite_size.x)
		sprite_size /= _atlas_size

	_SetupMovementBuckets()
	_SetupBulletData()
	ResetPoolSize() #Bullets depend on movement buckets, this has to go AFTER buckets initialization


	_paused = false
	_allow_shooting = true

	Main.DEBUG.connect.call_deferred(DEBUG)


func _physics_process(delta: float) -> void:
	if !_paused:
		_ManageBulletLifetimes(delta)

		for group in _collision_group_nodes.size():
			for node in _collision_group_nodes[group].size():
				_collision_group_node_positions[group][node] = _collision_group_nodes[group][node].global_position

		for enum_number in MovementType.size():
			_movement_type_methods[enum_number].call()


func _process(_delta: float) -> void:
	if !_paused:
		_MeshAndCollide.call_deferred()


##The mesh and collide puts together collision and rendering, which increases performance by quite a bit. (See inital commit on github)
func _MeshAndCollide() -> void:
	if multimesh.instance_count < _pool_size:
		breakpoint
	for index in _pool_size:
		if _bullet_data[bullet_data.LIFETIME][index] > 0:
			_spare_transform = Transform2D(_bullet_data[bullet_data.ROTATION][index] - global_rotation, to_local(_bullet_data[bullet_data.POSITION][index]))
			_spare_transform.x *= _bullet_data[bullet_data.SIZE][index] * 1.1
			_spare_transform.y *= _bullet_data[bullet_data.SIZE][index] * 1.1
			multimesh.set_instance_transform_2d(index, _spare_transform)

			for node_index in _collision_group_node_positions[_bullet_data[bullet_data.COLLISION_GROUP][index]].size():
				if ((_bullet_data[bullet_data.POSITION][index] - _collision_group_node_positions[_bullet_data[bullet_data.COLLISION_GROUP][index]][node_index]).length_squared() < #get the distance between the node and the bullet
					(_collision_group_node_radius[_bullet_data[bullet_data.COLLISION_GROUP][index]][node_index] + _bullet_data[bullet_data.SIZE][index] * 0.5) **2 #If their sizes together are greater than the distance, they overlap
					):
					_collision_group_nodes[_bullet_data[bullet_data.COLLISION_GROUP][index]][node_index].Hit()


func _ManageBulletLifetimes(delta : float):
	for index in _pool_size:
		if _bullet_data[bullet_data.LIFETIME][index] > 0:
			if _bullet_data[bullet_data.LIFETIME][index] > delta:
				_bullet_data[bullet_data.LIFETIME][index] -= delta
			
			else:
				_bullet_data[bullet_data.LIFETIME][index] = 0
				_dead_bullets.append(index)
				multimesh.set_instance_transform_2d(index, _spare_transform)


#Resizing is both expensive, and will introduce bugs... apparently. Anyway, every resize resets all instance custom data and flickers if not handled correctly
func _IncreaseMultimeshInstanceCount():
	multimesh.instance_count *= 2 #I believe this makes sense, as the more you resize, the more likely it is that you're using an insane amount of bullets

	for index in _pool_size: #please don't tank my fps please
		@warning_ignore("integer_division")
		multimesh.set_instance_custom_data(
			index,
			Color(
				(_bullet_data[bullet_data.SPRITE_INDEX][index] % _sprites_per_atlas_row),
				(_bullet_data[bullet_data.SPRITE_INDEX][index] / _sprites_per_atlas_row),
				sprite_size.x,
				sprite_size.y
			))


#Removes objective from the *collision* group
func _RemoveObjectiveFromGroup(group_name : String, node : Node) -> void:
	if !_collision_groups.has(group_name):
		push_warning("Invalid collision group for node removal: " + group_name)
		return

	for group in _collision_group_nodes[_collision_groups[group_name]]:
		for node_index in group.size():
			if group[node_index] == node:
				_JaggedSwapItemBackAndPopArray(
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


func _ChangeBulletMovementType(bullet_index : int, movement : MovementType) -> void:
	_movement_type_buckets[movement].append(bullet_index)
	
	#Get the ARRAY INDEX which contains the bullet index
	for index in _movement_type_buckets[movement].size():
		if _movement_type_buckets[movement][index] == bullet_index:
			_SwapItemBackAndPop(_movement_type_buckets[movement], index)


func _ClearBullets(kill : bool = false) -> void:
	_allow_shooting = false
	_paused = true

	for index in _pool_size:
		if (_bullet_data[bullet_data.LIFETIME][index] > 0):
			multimesh.set_instance_transform_2d(index, _spare_transform * 0)
			_bullet_data[bullet_data.LIFETIME][index] = -1
			if !kill && index % 2 == 0:
				await get_tree().process_frame

	_allow_shooting = true
	_paused = false

	spawner_cleared.emit()


#Called at ready(), will check every movement type and append an array for each
func _SetupMovementBuckets() -> void:
	for type in MovementType.size():
		var new_array : Array[int] = []
		_movement_type_buckets.append(new_array)
		_movement_type_methods[type] = _movement_type_methods[type].bind(type)

func _SetupBulletData() -> void:
	for type in bullet_data.size():
		_bullet_data.append([])


func _SwapItemBackAndPop(array : Array, index : int) -> void:
	array[index] = array[array.size() - 1] #copy the last item of the array at the index to delete
	array.pop_back() #delete duplicate


func _SwapItemBackAndPopArray(arrays : Array[Array], index : int) -> void:
	for external_index in arrays.size(): #for each array passed
		arrays[external_index][index] = arrays[external_index][arrays[external_index].size() - 1] #place the item (arrays) in last place to the index given
		arrays[external_index].pop_back() #delete duplicate


func _JaggedSwapItemBackAndPopArray(arrays : Array[Array], index : int) -> void:
	for parameter_array in arrays: #for each jagged array passed
		for inner_index in parameter_array.size() - 1: #for each array inside the array passed
			parameter_array[inner_index][index] = parameter_array[inner_index][parameter_array.size() - 1] #place the item (nodes) in the last place to the index given
			parameter_array.pop_back() #delete the duplicate






#Public methods

##Returns the BULLET ID in the shape of a Vector2, both numbers are necessary to ensure modification is possible.
##Where s = sprites in line: (x + sy) = sprite in atlas
func Shoot(bullet_position : Vector2, bullet_speed : float, bullet_lifetime : float, bullet_rotation : float, bullet_size : float, collision_group : String = "dummy", sprite_in_atlas : int = 0, angular_velocity : float = 0, bullet_movement : MovementType = MovementType.default) -> Vector2i:
	if !_allow_shooting:
		push_warning("!_allow_shooting is true")
		return _vector2_right * 0
	
	var i : int

	if !_dead_bullets.is_empty():
		i = _dead_bullets.pop_back()

		_bullet_data[bullet_data.ANGULAR_VEL][i] = angular_velocity
		_bullet_data[bullet_data.COLLISION_GROUP][i] = _collision_groups[collision_group]
		_bullet_data[bullet_data.POSITION][i] = bullet_position
		_bullet_data[bullet_data.ROTATION][i] = bullet_rotation
		_bullet_data[bullet_data.LIFETIME][i] = bullet_lifetime
		_bullet_data[bullet_data.SPEED][i] = bullet_speed
		_bullet_data[bullet_data.SIZE][i] = bullet_size

		_bullet_data[bullet_data.INSTANCE][i] += 1
		_bullet_data[bullet_data.SPRITE_INDEX][i] = sprite_in_atlas

	else:
		i = _pool_size

		_bullet_data[bullet_data.ANGULAR_VEL].append( angular_velocity)
		_bullet_data[bullet_data.COLLISION_GROUP].append(_collision_groups[collision_group])
		_bullet_data[bullet_data.LIFETIME].append(bullet_lifetime)
		_bullet_data[bullet_data.POSITION].append(bullet_position)
		_bullet_data[bullet_data.ROTATION].append(bullet_rotation)
		_bullet_data[bullet_data.SPEED].append(bullet_speed)
		_bullet_data[bullet_data.SIZE].append(bullet_size)

		_bullet_data[bullet_data.INSTANCE].append(1)
		_bullet_data[bullet_data.SPRITE_INDEX].append(sprite_in_atlas)
		_pool_size += 1

		if multimesh.instance_count < _pool_size:
			_IncreaseMultimeshInstanceCount()
	
	_movement_type_buckets[bullet_movement].append(i)

	@warning_ignore("integer_division")
	multimesh.set_instance_custom_data(
		i,
		Color(
			(sprite_in_atlas % _sprites_per_atlas_row),
			(sprite_in_atlas / _sprites_per_atlas_row),
			sprite_size.x,
			sprite_size.y
		))

	return Vector2i(i, _bullet_data[bullet_data.INSTANCE][i])


##If modify is TRUE, it will assign the new_value to the bullet data in data_type. If modify is FALSE it will return the value of the bullet data in data_type
func TouchBulletData(bullet_id : Vector2i, data_type : bullet_data, modify : bool = false, new_value : float = -1):
	if _bullet_data[bullet_data.INSTANCE][bullet_id[0]] != bullet_id[1]:
		push_warning("Invalid bullet index")
		return null
	
	if modify:
		_bullet_data[data_type][bullet_id[0]] = new_value

	else:
		return _bullet_data[data_type][bullet_id[0]]


func ChangeBulletMovementType(bullet_id : Vector2i, movement : MovementType) -> void:
	if _bullet_data[bullet_data.INSTANCE][bullet_id[0]] != bullet_id[1]:
		push_warning("Invalid bullet index")
		return
	
	_ChangeBulletMovementType.call_deferred(bullet_id[0], movement)


##Dead bullets stay in memory to be recycled, ResetPoolSize is meant as a literal way of clean up. 
func ResetPoolSize() -> void: #reset and fill arrays
	for type in bullet_data.size():
		_bullet_data[type].resize(preloaded_pool_size)

	_dead_bullets.resize(preloaded_pool_size)
	multimesh.instance_count = preloaded_pool_size
	_pool_size = preloaded_pool_size

	for index in preloaded_pool_size: #delete comments on test success
		#_bullet_data[bullet_data.ANGULAR_VEL]
		_bullet_data[bullet_data.COLLISION_GROUP][index] = 0
		_bullet_data[bullet_data.LIFETIME][index] = 0
		_bullet_data[bullet_data.INSTANCE][index] = 1
		#_bullet_data[bullet_data.POSITION][index] = Vector2.ZERO
		#_bullet_data[bullet_data.ROTATION]
		#_bullet_data[bullet_data.SIZE]
		#_bullet_data[bullet_data.SPEED]

		_dead_bullets[index] = index


##Instantly removes all bullets
func NukeGameBullets() -> void:
	_ClearBullets.call_deferred(true)


##Clears bullets slowly, more visually appealing. Keep in mind this will disable process and shooting
func ClearGameBullets() ->void:
	_ClearBullets.call_deferred(false)


func AddNewCollisionGroup(group_name : String) -> void:
	if _collision_groups.has(group_name):
		push_warning("Group already exists: " + group_name)
		return

	_collision_groups[group_name] = _collision_group_nodes.size()
	_collision_group_names.append(group_name)
	
	_collision_group_node_positions.append([])
	_collision_group_node_radius.append([])
	_collision_group_nodes.append([])


##(This can easily lead to problem, so unless you're sure that nothing is checking the specific group, don't use it often)
##Remove a collision group from the registered collision groups. It affects every array related to collision and collision cheking
func RemoveCollisionGroup(group_name : String) -> void:
	if group_name == "dummy":
		push_error("Don't play dumb games")

	elif _collision_groups.has(group_name):
		if group_name != _collision_group_names[_collision_group_names.size() - 1]:
			_collision_groups[_collision_group_names[_collision_group_names.size() - 1]] = _collision_groups[group_name]
		
		_SwapItemBackAndPopArray(
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


##Stop processing on this script
func Pause():
	_paused = true


##Use to resume processing 
func Unpause():
	_paused = false





#Movement Callables

func _MovementDefault(bucket_index : int) -> void:
	var index : int = 0
	var delta : float = get_physics_process_delta_time()
	while index < _movement_type_buckets[bucket_index].size():
		if _bullet_data[bullet_data.LIFETIME][_movement_type_buckets[bucket_index][index]] > 0:
			_bullet_data[bullet_data.POSITION][_movement_type_buckets[bucket_index][index]] += _vector2_right.rotated(_bullet_data[bullet_data.ROTATION][_movement_type_buckets[bucket_index][index]]) * _bullet_data[bullet_data.SPEED][_movement_type_buckets[bucket_index][index]] * delta
			_bullet_data[bullet_data.ROTATION][_movement_type_buckets[bucket_index][index]] += _bullet_data[bullet_data.ANGULAR_VEL][_movement_type_buckets[bucket_index][index]]
			index += 1
		else:
			_SwapItemBackAndPop(_movement_type_buckets[bucket_index], index)


func DEBUG():
	print("----------BULLETMAP-----------------BULLETMAP--------------BULLETMAP---------------")
	print(_pool_size)

