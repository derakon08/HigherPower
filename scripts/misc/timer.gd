extends Node
class_name TimerCustom
#simple timer for lightweight timing needs... i deleted my better one

@export var time : float = 0.0
@export var loop : bool = false

var _time_left : float

signal timeout




func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_time_left -= delta
	
	if _time_left < 0:
		timeout.emit()

		if !loop:
			set_physics_process(false)

		else:
			_time_left = time



func StartNewTime(new_time : float):
	_time_left = new_time
	time = new_time
	set_physics_process(true)


func Start():
	_time_left = time
	set_physics_process(true)


func Stop():
	set_physics_process(false)
	_time_left = 0
