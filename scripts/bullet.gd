extends Sprite2D
#this script is particularly rigid, mixing optimization and godot's ease of use, ends up being a mess to edit
#Because of collision checking, the script is still needed for the player bullets, as there will be many enemies on screen at once
@export var speed : int
@export var max_distance : float
@export var shape_obj : Shape2D
@export var rough_area : int #for collision margin (width)
@export var scaling : float = 1 #SCALE HITBOX what does scaling hitbox mean???

var query : PhysicsShapeQueryParameters2D #neat little feature

var distance_left : float = max_distance #got too lazy to reimplement in optimized spawners, best mistake ever

func _ready() -> void:
	query = PhysicsShapeQueryParameters2D.new() 
	query.shape = shape_obj #shape obhject should ideally be a raycast or a circle
	query.margin = rough_area * scaling #margin would act as radius for circle shape or length for raycast
	query.transform = Transform2D(0, Vector2.ZERO) #just a default value
	
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 1 #ASSIGN COLLISION CHECKING HERE

func _physics_process(delta: float) -> void:
	distance_left -= speed * delta
	position -= transform.y * speed * delta

func _process(_delta: float) -> void:
	query.origin = global_position #this position

	var collision = get_world_2d().direct_space_state.intersect_shape(query, 1) #intersect shape with 1 result max
	if (collision):
		collision[0].get("collider").Hit()
		Switch(false)
	elif  (distance_left <= 0):
		Switch(false)

func Switch(on : bool):
	if (on):
		distance_left = max_distance

		self.show()
		set_physics_process(true)
		set_process(true)
	else:
		self.hide()
		set_physics_process(false)
		set_process(false)
