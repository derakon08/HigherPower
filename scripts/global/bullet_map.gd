##This script relies on enemies having a Hit(Vector2) method. Bullet map is a bullet manager which will set the position of bullets shot by using the function Shoot
extends MultiMeshInstance2D

##The amount of bullets pre-loaded before any interaction. ResetPoolSize will use this number
@export var preloaded_pool_size : int = 100

##Set according to atlas (texture). Will break if changed during runtime
@export var sprite_size : Vector2 = Vector2(1, 1)

#bullet data
var _bullet_angular_velocity : Array[float]
var _bullet_collision_group : Array[int]
var _bullet_position : Array[Vector2]
var _bullet_rotation : Array[float]
var _bullet_lifetime : Array[float]
var _bullet_speed : Array[float]
var _bullet_size : Array[float]
var _bullet_sprite_index : Array[int]
var _bullet_instance : Array[int]
var _bullet_collision_offset : Array[Vector2]
var _bullet_collision_size_multiplier: Array[float]
var _bullet_movement_type_ref : Array[MovementType]

#collision variables
var _collision_group_node_positions : Array[Array] = [[]]
var _collision_group_node_radius : Array[Array] = [[]]
var _collision_group_nodes : Array[Array] = [[]]

var _collision_group_names : Array[String] = ["dummy"]
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
var _clearing_bullets : bool = false


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
	Reset()


	_paused = false
	_allow_shooting = true

	Main.DEBUG.connect.call_deferred(DEBUG)


func _physics_process(delta: float) -> void:
	if !_paused:
		_ManageBulletLifetimes(delta)

		for enum_number in MovementType.size():
			_movement_type_methods[enum_number].call()


func _process(_delta: float) -> void:
	if !_paused:
		for group in _collision_group_nodes.size():
			for node in _collision_group_nodes[group].size():
				_collision_group_node_positions[group][node] = _collision_group_nodes[group][node].global_position

		_MeshAndCollide.call_deferred()


##The mesh and collide puts together collision and rendering, which increases performance by quite a bit. (See inital commit on github)
func _MeshAndCollide() -> void:
	var bullet_collision_group : int
	var bullet_position : Vector2
	var bullet_size : float
	var collision_offset : Vector2
	var collision_multiplier : float

	var nodes_position : Array
	var nodes_radius : Array

	for index in _pool_size:
		if _bullet_lifetime[index] <= 0:
			continue

		#bunch of cache
		bullet_collision_group = _bullet_collision_group[index]
		bullet_position = _bullet_position[index]
		bullet_size = _bullet_size[index]
		collision_offset = _bullet_collision_offset[index].rotated(_bullet_rotation[index])
		collision_multiplier = _bullet_collision_size_multiplier[index]
		nodes_position = _collision_group_node_positions[bullet_collision_group]
		nodes_radius = _collision_group_node_radius[bullet_collision_group]

		_spare_transform = Transform2D(_bullet_rotation[index] - global_rotation, to_local(bullet_position))
		_spare_transform.x *= bullet_size
		_spare_transform.y *= bullet_size
		multimesh.set_instance_transform_2d(index, _spare_transform)

		for node_index in _collision_group_nodes[bullet_collision_group].size():
			if ((bullet_position + collision_offset - nodes_position[node_index]).length() < #get the distance between the node and the bullet
				(nodes_radius[node_index] + bullet_size * 0.5 * collision_multiplier) #If their sizes together are greater than the distance, they overlap
				):
				_collision_group_nodes[bullet_collision_group][node_index].Hit(Vector2(index, _bullet_instance[index]))


func _ManageBulletLifetimes(delta : float):
	for index in _pool_size:
		if _bullet_lifetime[index] > 0:
			if _bullet_lifetime[index] > delta:
				_bullet_lifetime[index] -= delta
			
			else:
				_bullet_lifetime[index] = 0
				_dead_bullets.append(index)
				multimesh.set_instance_custom_data(index, Color(0,0,0,0)) #please please please please


#Resizing is both expensive, and will introduce bugs... apparently. Anyway, every resize resets all instance custom data and flickers if not handled correctly
func _IncreaseMultimeshInstanceCount():
	if multimesh.instance_count <= 0:
		multimesh.instance_count = 1
	else:
		multimesh.instance_count *= 2 #I believe this makes sense, as the more you resize, the more likely it is that you're using an insane amount of bullets

	for index in _pool_size: #please don't tank my fps please
		@warning_ignore("integer_division")
		multimesh.set_instance_custom_data(
			index,
			Color(
				(_bullet_sprite_index[index] % _sprites_per_atlas_row),
				(_bullet_sprite_index[index] / _sprites_per_atlas_row),
				sprite_size.x,
				sprite_size.y
			))


#Removes objective from the *collision* group
func _RemoveObjectiveFromGroup(group_name : String, node : Node) -> void:
	if !_collision_groups.has(group_name):
		push_warning("Invalid collision group for node removal: " + group_name)
		return

	var collision_group : int = _collision_groups[group_name]

	for node_index in _collision_group_nodes[collision_group].size():
		if _collision_group_nodes[collision_group][node_index] == node:
			_SwapItemBackAndPopArray(
				[
				_collision_group_nodes[collision_group],
				_collision_group_node_radius[collision_group],
				_collision_group_node_positions[collision_group]
				],
				node_index
			)

			return

		else:
			continue


func _ChangeBulletMovementType(bullet_index : int, movement : MovementType) -> void:
	#Get from the buckets, the one the bullets asks to be in
	var bucket : Array = _movement_type_buckets[_bullet_movement_type_ref[bullet_index]]

	_movement_type_buckets[movement].append(bullet_index)
	_bullet_movement_type_ref[bullet_index] = movement

	#Search the bucket for the index where the bullet index is stored at, ok
	for index in bucket.size():
		if bucket[index] == bullet_index:
			_SwapItemBackAndPop(bucket, index)


func _ClearBullets(kill : bool = false) -> void:
	_allow_shooting = false
	_paused = true
	_clearing_bullets = true

	for index in _pool_size:
		if (_bullet_lifetime[index] > 0):
			multimesh.set_instance_transform_2d(index, _spare_transform * 0)
			_bullet_lifetime[index] = -1
			if !kill && index % 2 == 0:
				await get_tree().process_frame

	_allow_shooting = true
	_paused = false
	_clearing_bullets = false

	if !kill: spawner_cleared.emit()


#Called at ready(), will check every movement type and append an array for each
func _SetupMovementBuckets() -> void:
	for type in MovementType.size():
		var new_array : Array[int] = []
		_movement_type_buckets.append(new_array)
		_movement_type_methods[type] = _movement_type_methods[type].bind(type)


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


func _ValidateBulletInstance(bullet_id : Vector2i) -> bool:
	if _bullet_instance[bullet_id[0]] != bullet_id[1]:
		push_warning("Invalid bullet index")
		return false
	
	return true







#Public methods

##Returns the BULLET ID in the shape of a Vector2, both numbers are necessary to ensure modification is possible.
##Where s = sprites in line: (x + sy) = sprite in atlas.
##Collision offset : Vector2(push back, size reduction)
func Shoot(bullet_position : Vector2, bullet_speed : float, bullet_lifetime : float, bullet_rotation : float, bullet_size : float, collision_group : String = "dummy", sprite_in_atlas : int = 0, angular_velocity : float = 0, collision_offset : Vector2 = Vector2(0, 0), collision_size_multiplier : float = 1.0, bullet_movement : MovementType = MovementType.default) -> Vector2i:
	if !_allow_shooting:
		return _vector2_right * 0
	
	var i : int

	if !_dead_bullets.is_empty():
		i = _dead_bullets.pop_back()

		_bullet_collision_size_multiplier[i] = collision_size_multiplier
		_bullet_collision_offset[i] = collision_offset
		_bullet_collision_group[i] = _collision_groups[collision_group]
		_bullet_movement_type_ref[i] = bullet_movement
		_bullet_angular_velocity[i] = angular_velocity
		_bullet_position[i] = bullet_position
		_bullet_rotation[i] = bullet_rotation
		_bullet_lifetime[i] = bullet_lifetime
		_bullet_speed[i] = bullet_speed
		_bullet_size[i] = bullet_size

		_bullet_instance[i] += 1
		_bullet_sprite_index[i] = sprite_in_atlas

	else:
		i = _pool_size

		_bullet_collision_size_multiplier.append(collision_size_multiplier)
		_bullet_collision_offset.append(collision_offset)
		_bullet_movement_type_ref.append(bullet_movement)
		_bullet_angular_velocity.append( angular_velocity)
		_bullet_collision_group.append(_collision_groups[collision_group])
		_bullet_lifetime.append(bullet_lifetime)
		_bullet_position.append(bullet_position)
		_bullet_rotation.append(bullet_rotation)
		_bullet_speed.append(bullet_speed)
		_bullet_size.append(bullet_size)

		_bullet_instance.append(1)
		_bullet_sprite_index.append(sprite_in_atlas)
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

	return Vector2i(i, _bullet_instance[i])


##0. instance[br]
##1. position[br]2. speed[br]
##3. lifetime[br]4. rotation[br]5. size[br]
##6. collision group[br] 7. sprite[br]
##8. angular velocity[br]  9. collision offset[br]
##10. collision multiplier[br]11. movement type[br]
func GetBulletData(bullet_id : Vector2i):
	if !_ValidateBulletInstance(bullet_id):
		return null
	
	var bullet_data : Array

	bullet_data.append(_bullet_instance[bullet_id[0]])
	bullet_data.append(_bullet_position[bullet_id[0]])
	bullet_data.append(_bullet_speed[bullet_id[0]])
	bullet_data.append(_bullet_lifetime[bullet_id[0]])
	bullet_data.append(_bullet_rotation[bullet_id[0]])
	bullet_data.append(_bullet_size[bullet_id[0]])
	bullet_data.append(_collision_group_names[_bullet_collision_group[bullet_id[0]]])
	bullet_data.append(_bullet_sprite_index[bullet_id[0]])
	bullet_data.append(_bullet_angular_velocity[bullet_id[0]])
	bullet_data.append(_bullet_collision_offset[bullet_id[0]])
	bullet_data.append(_bullet_collision_size_multiplier[bullet_id[0]])
	bullet_data.append(_bullet_movement_type_ref[bullet_id[0]])

	return bullet_data


func TouchMovementType(bullet_id : Vector2i, modify : bool = false, movement : MovementType = MovementType.default):
	if !_ValidateBulletInstance(bullet_id):
		return
	
	if modify:
		_ChangeBulletMovementType.call_deferred(bullet_id[0], movement)
	else:
		return _bullet_movement_type_ref[bullet_id[0]]


func TouchSprite(bullet_id : Vector2i, modify : bool = false, sprite_index : int = -1):
	if  !_ValidateBulletInstance(bullet_id):
		return

	if modify:
		_bullet_sprite_index[bullet_id[0]] = sprite_index

		@warning_ignore("integer_division")
		multimesh.set_instance_custom_data(
			bullet_id[0],
			Color(
				(sprite_index % _sprites_per_atlas_row),
				(sprite_index / _sprites_per_atlas_row),
				sprite_size.x,
				sprite_size.y
			))
		
	else:
		return _bullet_sprite_index[bullet_id[0]]


func TouchLifetime(bullet_id : Vector2i, modify : bool = false, lifetime : float = -1.0):
	if  !_ValidateBulletInstance(bullet_id):
		return
	
	if modify:
		_bullet_lifetime[bullet_id[0]] = lifetime

		if !lifetime > 0:
			_dead_bullets.append(bullet_id[0])
			multimesh.set_instance_custom_data(bullet_id[0], Color(0,0,0,0))
	
	else:
		return _bullet_lifetime[bullet_id[0]]


func TouchSpeed(bullet_id : Vector2i, modify : bool = false, speed : float = -1.0):
	if  !_ValidateBulletInstance(bullet_id):
		return

	if modify:
		_bullet_speed[bullet_id[0]] = speed
	
	else:
		return _bullet_speed[bullet_id[0]]


func TouchCollisionGroup(bullet_id : Vector2i, modify : bool = false, collision_group : String = "dummy"):
	if  !_ValidateBulletInstance(bullet_id):
		return

	if modify:
		_bullet_collision_group[bullet_id[0]] = _collision_groups[collision_group]
	
	else:
		return _collision_group_names[_bullet_collision_group[bullet_id[0]]]


func TouchSize(bullet_id : Vector2i, modify : bool = false, size : float = -1.0):
	if  !_ValidateBulletInstance(bullet_id):
		return

	if modify:
		_bullet_size[bullet_id[0]] = size
	
	else:
		return _bullet_size[bullet_id[0]]



##Dead bullets stay in memory to be recycled, ResetPoolSize is meant as a literal way of clean up. 
func ResetPoolSize() -> void: #reset and fill arrays
	for bucket in _movement_type_buckets:
		bucket.clear()


	_bullet_collision_size_multiplier.resize(preloaded_pool_size)
	_bullet_movement_type_ref.resize(preloaded_pool_size)
	_bullet_collision_offset.resize(preloaded_pool_size)
	_bullet_angular_velocity.resize(preloaded_pool_size)
	_bullet_collision_group .resize(preloaded_pool_size)
	_bullet_sprite_index.resize(preloaded_pool_size)
	_bullet_instance.resize(preloaded_pool_size)
	_bullet_position.resize(preloaded_pool_size)
	_bullet_rotation.resize(preloaded_pool_size)
	_bullet_lifetime.resize(preloaded_pool_size)
	_bullet_speed.resize(preloaded_pool_size)
	_bullet_size.resize(preloaded_pool_size)

	_dead_bullets.resize(preloaded_pool_size)
	multimesh.instance_count = preloaded_pool_size
	_pool_size = preloaded_pool_size

	for index in preloaded_pool_size:
		_bullet_lifetime[index] = 0.1
		_bullet_instance[index] = 1

		_dead_bullets[index] = index


func Reset():
	ResetPoolSize()

	for array in _collision_group_nodes.size():
		_collision_group_node_positions[array].clear()
		_collision_group_node_radius[array].clear()
		_collision_group_nodes[array].clear()


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


func RemoveObjectiveFromGroup(group_name : String, node : Node) -> void:
	if group_name == "dummy":
		push_warning("Invalid collision group for node removal: " + group_name)
		return

	_RemoveObjectiveFromGroup.call_deferred(group_name, node)


##Stop processing on this script
func Pause():
	_paused = true
	_allow_shooting = false


##Use to resume processing 
func Unpause():
	_paused = false
	_allow_shooting = true

##Use to stop/allow shooting for external scripts. Use IsClearingBullets() to avoid desync
func AllowShooting(allow : bool):
	if _clearing_bullets:
		push_warning("Spawner is clearing. Delaying call...")
		await spawner_cleared
	
	_allow_shooting = allow

func IsClearingBullets():
	return _clearing_bullets





#Movement Callables

func _MovementDefault(bucket_index : int) -> void:
	var bullet : int 
	var delta : float = get_physics_process_delta_time()
	var bucket : Array[int] = _movement_type_buckets[bucket_index]
	for index in range(_movement_type_buckets[bucket_index].size() -1, -1, -1):
		bullet = bucket[index]
		if _bullet_lifetime[bullet] > 0:
			_bullet_position[bullet] += _vector2_right.rotated(_bullet_rotation[bullet]) * _bullet_speed[bullet] * delta
			_bullet_rotation[bullet] += _bullet_angular_velocity[bullet]
			index += 1
		else:
			_SwapItemBackAndPop(_movement_type_buckets[bucket_index], index)


func DEBUG():
	print("----------BULLETMAP-----------------BULLETMAP--------------BULLETMAP---------------")
	print(_pool_size)

