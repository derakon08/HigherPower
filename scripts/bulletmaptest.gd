extends Node2D
@export var fire_rate : float
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

@export_range(0, 30) var sprite : int

var _spacing : float = 0
var _angle : float

var to_fire : float = 0.0

func _process(delta: float) -> void:
	var temp_angle : float = _angle
	to_fire += fire_rate * delta

	while to_fire > 1:
		to_fire -= 1

		for bullet in bullet_density:
			temp_angle += _spacing
			BulletMap.Shoot(global_position, 10, 120, temp_angle, 50, "dummy", sprite, 5 * 0.001)

func Hit():
	pass
