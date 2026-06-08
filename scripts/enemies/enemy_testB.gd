##Keep in mind the sprite's forward should still be positive x
class_name ENEMYb
extends RoutableEnemy2D

@export_category("Stats")
@export var health : int = 100
@export var fire_rate : float = 0.0
@export_range(0.0, 1.0) var speed_easing_strength : float = 1
##this variable affects how fast the enemy turns towards the player
@export var turning_speed : float = 0.01 :
	set (value):
		_turning_speed = deg_to_rad(value)
	
	get:
		return rad_to_deg(_turning_speed)

@export_subgroup("Flags")
@export var allow_shooting : bool = true
@export var look_at_player : bool = false

@export_subgroup("Hit Effects")
@export var bullet_hit_sprite : int = 0
@export var bullet_hit_duration : float = 0
@export var bullet_hit_size : float = 50



var radius : float = 0.0

var _turning_speed : float
var _speed_objective : float = 0.0
var _current_speed : float = 0.0
var _current_direction : Vector2 = Vector2.ZERO

var _Attack : Callable = _ModeOne
var _attack_mode : bool = true

var _free_at_screen_edge : bool = false
var _move : bool = true
var _game_area : Rect2
var _to_be_fired : float = 0.0


#Obligatory overrides
func _ModeOne():
	push_error("NO BEHAVIOUR DEFINED FOR ENEMY ATTACK")

func _ModeTwo():
	push_error("NO BEHAVIOUR DEFINED FOR ENEMY ATTACK")

func _ReachedRouter():
	push_error("NO BEHAVIOUR DEFINED FOR ENEMY BEHAVIOUR")




func _ready() -> void:
	radius = self.get_node("CollisionShape2D").shape.radius
	#radius = 50
	_speed_objective = base_speed

	_game_area = Main.game_area.grow(radius * 1.5)
	_free_at_screen_edge = _game_area.has_point(global_position)
	BulletMap.AddObjectiveToGroup("enemies", self, radius)
	Main.warp.connect(_OnWarpAction)


func _physics_process(delta: float) -> void:
	if look_at_player:
		breakpoint
		global_rotation = lerp_angle(global_rotation, (Main.player.global_position - global_position).angle(), _turning_speed)

	if _move:
		_current_speed = lerp(_current_speed, _speed_objective, speed_easing_strength)
		_current_direction = lerp(_current_direction, direction, speed_easing_strength)

		global_position += _current_direction * _current_speed * delta
		distance_left -= (_current_direction * _current_speed * delta).length()

		if distance_left < 0:
			if !EnemyRouter.EnrouteNode(self):
				_Death(true)

			_ReachedRouter()


func _process(delta: float) -> void:
	if _free_at_screen_edge && !_game_area.has_point(global_position):
		_Death()
	
	elif !_free_at_screen_edge:
		_free_at_screen_edge = _game_area.has_point(global_position)


	if allow_shooting && Main.enemies_dead_zone.has_point(global_position):
		_to_be_fired += delta * fire_rate

		_Attack.call()    


func _OnWarpAction() -> void:
	_attack_mode = !_attack_mode
	if (_attack_mode):
		_Attack = _ModeOne
	else:
		_Attack = _ModeTwo


func _Death(silent : bool = false) -> void:
	BulletMap.RemoveObjectiveFromGroup("enemies", self)
	if !silent:
		print("BOOM!")
		#death animation and such... perhaps use the bulletmap and make a Bounce movement type
		pass
	
	queue_free()




func Hit(bullet : Vector2i):
	health -= 1
	BulletMap.TouchCollisionGroup(bullet, true)
	BulletMap.TouchSprite(bullet, true, bullet_hit_sprite)
	BulletMap.TouchLifetime(bullet, true, bullet_hit_duration)
	BulletMap.TouchSize(bullet, true, bullet_hit_size)

	if health < 1:
		_Death()


func SetMovement(on : bool):
	_move = on

##Equivalent to setting shoot directly
func SetShooting(on : bool):
	allow_shooting = on
		
