extends Node2D

@export var radius : float = 0.0
@export var speed : float = 100.0
@export var health : int = 100
@export var move_to_end : bool = false
@export var fire_rate : float = 0.0
@export var stream_density : int = 1
@export var bullet_hit_sprite : int = 0
@export var bullet_hit_duration : float = 0
@export var bullet_hit_speed : float = 100
@export var route_node : Node

var _route : Array[Vector2]
var _current_route : int = -1

var _Shoot : Callable = _ModeOne
var _shoot_mode : bool = true

var _free_at_screen_edge : bool = false
var _direction : Vector2
var _game_area : Rect2
var _move : bool = true
var _shoot : bool = false
var _to_be_fired : float = 0.0

signal reached_pos

func _ready() -> void:
	_game_area = Main.game_area.grow(radius * 2)
	_free_at_screen_edge = _game_area.has_point(global_position)
	BulletMap.AddObjectiveToGroup("enemies", self, radius)

	if !route_node:
		_route.append(
			Main.player.global_position
			)
	else:
		for child in route_node.get_children():
			_route.append(child.global_position)
		
	_ReachedPosition()


func _physics_process(delta: float) -> void:
	if _move:
		global_position -= _direction * speed * delta

		if (global_position - _route[_current_route]).length() < speed * delta:
			_ReachedPosition()

func _process(delta: float) -> void:
	if _shoot:
		_to_be_fired += delta * fire_rate

		_Shoot.call()
		 

func _ModeOne():
	push_error("NO BEHAVIOUR DEFINED FOR ENEMY ATTACK")


func _ModeTwo():
	push_error("NO BEHAVIOUR DEFINED FOR ENEMY ATTACK")    


func _OnWarpAction():
	_shoot_mode = !_shoot_mode
	if (_shoot_mode):
		_Shoot = _ModeOne
	else:
		_Shoot = _ModeTwo


func _ReachedPosition():
	_current_route += 1
	_move = move_to_end

	if _current_route < _route.size():
		_direction = Vector2(1,0).rotated(
			atan2(
					global_position.y - _route[_current_route].y,
					global_position.x - _route[_current_route].x
				)
			)

		_ReachedStop(_current_route)
	
	else:
		_move = false
		_ReachedEnd()

@warning_ignore("UNUSED_PARAMETER")
func _ReachedStop(route_stop : int):
	push_error("NO BEHAVIOUR DEFINED FOR NODE: ", self)


func _ReachedEnd():
	push_error("NO BEHAVIOUR DEFINED FOR NODE: ", self)


func _Death():
	BulletMap.RemoveObjectiveFromGroup("enemies", self)
	queue_free()






func Hit(bullet : Vector2i):
	#Main.InvertBackgroundColor() #this hurts so much, and im not even epileptic
	health -= 1
	BulletMap.ChangeBulletSprite(bullet, bullet_hit_sprite)
	BulletMap.TouchBulletData(bullet, BulletMap.bullet_data.COLLISION_GROUP, true, 0) #dummy group
	BulletMap.TouchBulletData(bullet, BulletMap.bullet_data.SPEED, true, bullet_hit_speed)
	BulletMap.TouchBulletData(bullet, BulletMap.bullet_data.LIFETIME, true, bullet_hit_duration)

	if health < 1:
		_Death()


func SetMovement(on : bool):
	_move = on


func SetShooting(on : bool):
	_shoot = on
