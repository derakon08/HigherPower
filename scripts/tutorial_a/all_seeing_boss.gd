extends Node2D
var life : int = 2000
var count : int = 0


signal boss_death

func _on_pattern_stream_over() -> void:
	count += 1

	if count == 3:
		for child in get_node("./SubpatternBody").get_children():
			child.SetSpawner(true)

func Hit():
	life -= 1

	if life < 0:
		boss_death.emit()
		queue_free()
	elif life == 1000:
		$Pattern2.SetSpawner(true)


func _on_area_entered(area: Area2D) -> void:
	area.Hit()


func _on_simple_shape_spawner_2_stream_over() -> void:
	var spawner = $SimpleShapeSpawner2
	spawner.stream_over.disconnect(_on_simple_shape_spawner_2_stream_over)

	spawner.delay_spawns = false
	spawner.stream_number = 1
