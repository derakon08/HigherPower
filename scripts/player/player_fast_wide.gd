extends "res://scripts/player/player_base.gd"
@export var bullets_in_arc : int

func _ModeOne():
	if (_to_be_fired > 1 && focus) || (_to_be_fired > 0.9 && !focus):
		BulletMap.Shoot(
			global_position + Vector2.UP * _aprox_radius,
			bullet_speed,
			bullet_distance, 
			_account_for_rotation if focus else _account_for_rotation + randf_range(-20,20) * 0.01745,
			50,
			"enemies",
			_atlas_sprite)

		_to_be_fired = 0

func _ModeTwo():
	var angle = deg_to_rad(-2 if focus else -30)
	var angle_step = abs((angle * 2) / (bullets_in_arc))

	if (!focus && _to_be_fired > bullets_in_arc) || (focus && _to_be_fired > bullets_in_arc + bullets_in_arc * 0.3):
		for bullet in bullets_in_arc:
			BulletMap.Shoot(
				global_position + Vector2.UP * _aprox_radius,
				bullet_speed,
				bullet_distance, 
				_account_for_rotation + angle,
				50,
				"enemies",
				_atlas_sprite)

			angle += angle_step
		_to_be_fired = 0
