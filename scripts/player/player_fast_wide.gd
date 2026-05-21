extends "res://scripts/player/player_base.gd"
@export var bullet_speed : float = 2000
@export var bullet_distance : float = 2
@export var bullets_in_arc : int

func _ModeOne():
	if (_to_be_fired > 1 && _focus) || (_to_be_fired > 0.9 && !_focus):
		var aim : float = _GetPlayerAim()

		BulletMap.Shoot(
			global_position + Vector2.RIGHT.rotated(aim) * aprox_radius,
			bullet_speed,
			bullet_distance, 
			aim if _focus else aim + randf_range(-20,20) * 0.01745,
			50,
			"enemies",
			_atlas_sprite)

		_to_be_fired = 0

func _ModeTwo():
	if (!_focus && _to_be_fired > bullets_in_arc) || (_focus && _to_be_fired > bullets_in_arc + bullets_in_arc * 0.3):
		var angle = deg_to_rad(-2 if _focus else -30)
		var angle_step = abs((angle * 2) / (bullets_in_arc))
		var aim : float = _GetPlayerAim()

		for bullet in bullets_in_arc:
			BulletMap.Shoot(
				global_position + Vector2.RIGHT.rotated(aim + angle) * aprox_radius,
				bullet_speed,
				bullet_distance, 
				aim + angle,
				50,
				"enemies",
				_atlas_sprite)

			angle += angle_step
		_to_be_fired = 0
