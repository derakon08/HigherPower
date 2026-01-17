extends Sprite2D

@export var speed : int
@export var max_distance : float
@export var rough_area : int #because i can't check by pixels lol

var query : PhysicsShapeQueryParameters2D
var shape_obj : Shape2D

var distance_left : float = max_distance

func _ready() -> void:
	shape_obj = SegmentShape2D.new()

	query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape_obj
	query.margin = rough_area
	query.transform = Transform2D(0, Vector2.ZERO)
	
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 2

func _physics_process(delta: float) -> void:
	distance_left -= speed * delta
	global_position -= Vector2(0, speed * delta).rotated(rotation)

func _process(_delta: float) -> void:
	shape_obj.a = global_position
	shape_obj.b = global_position + Vector2(1, 0).rotated(rotation)

	var collision = get_world_2d().direct_space_state.intersect_shape(query, 1)
	if (collision):
		collision[0].get("collider").Hit()
		Switch(false)
	elif  (distance_left <= 0):
		Switch(false)

func Switch(on : bool):
	if (on):
		distance_left = max_distance

	self.visible = on
	set_physics_process(on)
	set_process(on)
