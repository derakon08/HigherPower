extends Node2D

##Class for node2D enemies. This is an interface, check the script directly.
class_name RoutableEnemy2D

@export var base_speed : float

##Route xy coordinates for the route_grid. 0 indexed.
@export var route : Array[Vector2i]

#Used for movement. direction will be a normalized vector and along with distance_left, are set everytime EnemyRoute.EnrouteNode(self) is called
var direction : Vector2
var distance_left : float

@warning_ignore("unused_private_class_variable")
var _route_index : int = 0



func _init() -> void:
    self.ready.connect(_SetRoute)


func _SetRoute() -> void:
    if route.size() > _route_index:
        EnemyRouter._SetNodeDirection(self)
    
    else:
        push_error("Routable enemy has no set route")
        breakpoint
