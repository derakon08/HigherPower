extends Area2D
@export var loop : bool = false #should loop back to the start or stop
@export var exit_after_path : bool = false #should it queue free at the last location
@export var wait_to_move : bool = false

@export var speed : float
@export var wait_time : float #in each position

@export var directions_node : Node
@export var to_balance_node : Node2D #will keep at rotation 0
@export var look_at_player : bool

@export var life : int

var directions : PackedVector2Array
var directions_index : int = -1
var cooldown : float = 0 #i probably should use the custom timer
var velocity : Vector2 = Vector2.ZERO

var _move_now : bool

signal enemy_destroyed

signal reached_position #being that this will likely be the parent node, this signal is probably useless
signal reached_path_end

func _ready() -> void:
	_move_now = !wait_to_move
	reached_position.connect(ReachedPosition)

	for node in directions_node.get_children(): #fill array with node positions
			directions.append(node.global_position)

	if (directions_node.get_parent() == self): #delete if it's only for this node
		directions_node.queue_free()

	if directions.size() > 0:
		cooldown = wait_time
		ReachedPosition()
	else:
		print("No destination for " + get_parent().name + '/' + name)
		queue_free()


func _physics_process(delta: float) -> void:
	if (_move_now || (cooldown >= 0 && !wait_to_move)): #a timer would keep this cleaner, instead focusing on movement
		position -= velocity * speed * delta

		if ((global_position - directions[directions_index]).length() <= speed * delta):
			_move_now = false
			emit_signal("reached_position")
	elif (!wait_to_move):
		cooldown -= delta
	
	if (look_at_player):
			to_balance_node.set_global_rotation(
				atan2(
					global_position.y - Main.player.global_position.y,
					global_position.x - Main.player.global_position.x
				)
			)

func ReachedPosition():
	if (directions_index < directions.size() - 1):
		_move_now = !wait_to_move
		directions_index += 1

		cooldown = wait_time #reset timer
		#consider adding a feature to teleport back to the start

		velocity = Vector2(1,0).rotated(atan2(
			position.y - directions[directions_index].y,
			position.x - directions[directions_index].x))

	elif (loop):
		_move_now = !wait_to_move
		directions_index = 0

		velocity = Vector2(1,0).rotated(atan2(
			position.y - directions[directions_index].y,
			position.x - directions[directions_index].x))

	elif (exit_after_path):
		reached_path_end.emit()
		queue_free()
	else:
		reached_path_end.emit()
		velocity = Vector2.ZERO

func Move():
	_move_now = true


func Hit():
	life -= 1

	if life <= 0:
		enemy_destroyed.emit()
		queue_free()
