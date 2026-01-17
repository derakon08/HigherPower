extends Node2D
@export var fire_rate : float

var to_fire : float = 0.0
var rot : float

func _ready():
	pass

func _process(delta: float) -> void:
	to_fire += fire_rate * delta

	while to_fire > 1:
		rot += 0.1
		to_fire = 0
		BulletMap.Shoot(global_position, 10, 120, rot, 20, "player")

func Hit():
	pass
