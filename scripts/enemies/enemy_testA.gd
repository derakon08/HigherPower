class_name ENEMY
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

var allow_shooting : bool = true

var _Attack : Callable = _ModeOne
var _attack_mode : bool = true

var _free_at_screen_edge : bool = false
var _direction : Vector2
var _game_area : Rect2
var _move : bool = true
var _to_be_fired : float = 0.0


var _route : Array[Vector2]

var _current_route : int = -1
var current_route : int :
	set (value):
		if value < _route.size():
			_direction = (global_position - _route[value]).normalized()
			_current_route = value
		
		else:
			_move = false
			_ReachedEnd()

	get:
		return _current_route

signal reached_pos


#Obligatory overrides
func _ModeOne():
	push_error("NO BEHAVIOUR DEFINED FOR ENEMY ATTACK")

func _ModeTwo():
	push_error("NO BEHAVIOUR DEFINED FOR ENEMY ATTACK")

@warning_ignore("UNUSED_PARAMETER")
func _ReachedStop(route_stop : int):
	push_error("NO BEHAVIOUR DEFINED FOR NODE: ", self)

func _ReachedEnd():
	push_error("NO BEHAVIOUR DEFINED FOR NODE: ", self)




func _ready() -> void:
	if !route_node:
		_route.append(
			Main.player.global_position
			)
	else:
		for child in route_node.get_children():
			_route.append(child.global_position)

	_game_area = Main.game_area.grow(radius * 2)
	_free_at_screen_edge = _game_area.has_point(global_position)
	BulletMap.AddObjectiveToGroup("enemies", self, radius)
	_move = move_to_end
	current_route = 0


func _physics_process(delta: float) -> void:
	if _move:
		global_position -= _direction * speed * delta

		if (global_position - _route[current_route]).length() < speed * delta:
			_move = move_to_end
			_ReachedStop(current_route)
			current_route += 1

func _process(delta: float) -> void:
	if allow_shooting:
		_to_be_fired += delta * fire_rate

		_Attack.call()    


func _OnWarpAction():
	_attack_mode = !_attack_mode
	if (_attack_mode):
		_Attack = _ModeOne
	else:
		_Attack = _ModeTwo


func _Death():
	BulletMap.RemoveObjectiveFromGroup("enemies", self)
	queue_free()






func Hit(bullet : Vector2i):
	#Main.InvertBackgroundColor() #this hurts so much, and im not even epileptic
	health -= 1
	BulletMap.TouchCollisionGroup(bullet, true)
	BulletMap.TouchSprite(bullet, true, bullet_hit_sprite)
	BulletMap.TouchSpeed(bullet, true, bullet_hit_speed)
	BulletMap.TouchLifetime(bullet, true, bullet_hit_duration)

	if health < 1:
		_Death()


func SetMovement(on : bool):
	_move = on

##Equivalent to setting shoot directly
func SetShooting(on : bool):
	allow_shooting = on


func SetRoute(directions : Node):
	_route.clear()
	_move = move_to_end

	for child in directions.get_children():
		_route.append(child.global_position)
		
	_current_route = 0
		
