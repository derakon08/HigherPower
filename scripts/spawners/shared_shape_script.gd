extends "res://scripts/spawners/legacy_version.gd"
@export_category("HitScan Settings") #all about hitbox, sad i haven't used it
#values for my frost arrow sprite, probably won't use it
@export var hitbox_segments : int = 4
@export var base_radius : float = 0.4
@export var tip_radius : float = 0.05
@export var hitbox_length : float = 0.7
@export var offset : float = -0.6

var hitbox_origin : PackedVector2Array
var hitbox_radius : PackedFloat32Array

func RePooling():
	if !_EnsureCollisionSettings():
		print("Invalid value in " + get_parent().name + '/' + name)
	else:
		super.RePooling()


#processes and logic
func _physics_process(delta: float) -> void:
	var vector = Vector2(1,0)
	movement_waves_clock += delta
	_is_alive = false
	for index in _pool_size: #move and collide
		if _bullet_active[index]:
			_is_alive = true
			if _CheckCollision(index):
				collision.emit()
			elif (_clip_bullets && !_visible_area.has_point(_bullet_position[index])): #kill bullet if out of bounds
				_bullet_speed[index] = 0
				_bullet_active[index] = false
				_dead_bullets.push_back(index)

		if _allow_movement && _bullet_speed[index] != 0:
			_bullet_position[index] += vector.rotated(_bullet_rotation[index]) * CalculateMovement.call(index) * delta
			_bullet_rotation[index] += _angular_velocity * delta

#func _process(delta: float) -> void:
	#super._process(delta)
	#_SetDebugMeshes()

#other helpers
func _SetDebugMeshes(): #this set meshes for each hitbox segment
	var scaler := Transform2D()

	for index in _pool_size:
		for step in hitbox_segments:
			scaler = Transform2D(_bullet_rotation[index] - global_rotation, to_local(_bullet_position[index]) + hitbox_origin[step].rotated(_bullet_rotation[index] - global_rotation))
			scaler.x *= hitbox_radius[step] * 2
			scaler.y *= hitbox_radius[step] * 2

			multimesh.set_instance_transform_2d(index * hitbox_segments + step, scaler)

func _CheckCollision(index:int) -> bool:
	if (allow_collision &&
		(_bullet_position[index] - objective.position).length_squared() 
		< _collision_check_radius):
			for step in hitbox_origin.size():
				if (
				(_bullet_position[index] + hitbox_origin[step].rotated(_bullet_rotation[index]) - objective.position).length_squared() 
				< ((hitbox_radius[step] + _objective_hitbox_radius)) ** 2): #collision area + player hitbox area overlap
					collision.emit()
	elif (clip_bullets && !_visible_area.has_point(_bullet_position[index])):
		_bullet_speed[index] = 0
		_dead_bullets.push_back(index)
	return false

#func _PoolBullets():
#	super._PoolBullets()
#	multimesh.instance_count *= hitbox_segments
#	multimesh.visible_instance_count *= hitbox_segments


#Ensure settings
func _EnsureCollisionSettings():
	if(base_radius <= 0 || hitbox_segments < 1):
		return false #non negotiable base bullet length and hitbox shape

	elif (hitbox_segments > 1): #you need values for each segment
		return hitbox_length > 0 && tip_radius > 0

	elif (hitbox_segments == 1): #you can't add lenght to a single segment, duh
		return hitbox_length == 0 && tip_radius == 0

#Hitbox stuff
func _CalculateCollisionShape(): #why is this so complicated
	hitbox_origin = [] # 1. reset related arrays
	hitbox_radius = []

	#2. scale related values
	var this_offset : float = offset * bullet_size
	var this_base_radius : float = base_radius * bullet_size
	var this_tip_radius : float = tip_radius * bullet_size
	var this_hitbox_length : float =  hitbox_length * bullet_size

	#3. calculate the (name of variable)
	var space_between_segments : float = this_hitbox_length / hitbox_segments #space between segments
	var radius_difference : float = (this_base_radius - this_tip_radius) / hitbox_segments #radius reduction for each section

	#4. calculate position offset to each segment
	var offset_added : Vector2 = Vector2.ZERO
	offset_added.x = this_offset / hitbox_segments

	#5.
	for i in hitbox_segments: #add origin with space and offset, and radius accounting for size difference
		hitbox_origin.append(
			(Vector2(space_between_segments, 0) * i)
			+ offset_added)
		hitbox_radius.append((this_base_radius - radius_difference * i) * 0.5) #This magic number (sort of) defines how sharp the edge should be. 0.5 for sharpest

	if hitbox_segments > 1: #check which segment is has the furthest reach
		var max_reach : float = 0
		for i in hitbox_segments:
			if hitbox_origin[i].length() + hitbox_radius[i] > max_reach: #Check from the origin to the radius range
				max_reach = hitbox_origin[i].length() + hitbox_radius[i]

		_collision_check_radius = (_objective_hitbox_radius + max_reach)**2
	else: #Add everything till the border is wide enough
		_collision_check_radius = (_objective_hitbox_radius + hitbox_origin[0].length() + hitbox_radius[0]) **2
