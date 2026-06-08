class_name RoutableEnemy2DRound
extends Resource

##RoutableEnemy2D scene
@export var enemy : PackedScene
##The amount of enemies this round
@export var enemy_count : int = 0
 ##The time it takes before starting to spawn enemies
@export var round_delay : float = 0.0
 ##The time between each enemy spawning
@export var enemy_spawn_timer : float = 0.0
#A vector2 position in space
@export var enemy_spawn_position : Vector2 = Vector2.ZERO
 ##This script works alongside enemy_router.gd
 ##The route the enemy takes in the grid
@export var enemy_route : PackedVector2Array