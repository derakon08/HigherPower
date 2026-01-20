extends Node2D
@export var fire_rate : float

var to_fire : float = 0.0
var rot : float
var sprite : int = -1

func _ready():
	pass

func _process(delta: float) -> void:
	to_fire += fire_rate * delta

	while to_fire > 1:
		if sprite > 29:
			sprite = 0

		rot += 0.1
		to_fire = 0
		BulletMap.Shoot(global_position, 100, 120, rot, 50, "player", sprite)

		sprite += 1

func Hit():
	pass
