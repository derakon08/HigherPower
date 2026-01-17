extends Node2D
#The entirety of this script is to make a looping border for the player
@export var top : Area2D
@export var bottom : Area2D
@export var left : Area2D
@export var right : Area2D

func _on_top_bottom_area_entered(area: Area2D) -> void:
	if (area.name == "Player"): area.global_position.y = bottom.global_position.y - 70

func _on_left_side_area_entered(area: Area2D) -> void:
	if (area.name == "Player"): area.global_position.x = right.global_position.x - 100

func _on_right_side_area_entered(area: Area2D) -> void:
	if (area.name == "Player"): area.global_position.x = left.global_position.x + 100
