extends Node
#simple timer for lightweight timing needs... i deleted my better one

@export var start : bool = false
@export var loop : bool = false

var _time_left : float


signal timeout


func _process(delta: float) -> void:
	if start:
		if _time_left > 0:
			_time_left -= delta
		else:
			timeout.emit()
			print("Timeout")
			start = false

func Start(time : float):
	_time_left = time
	start = true

func Stop():
	start = false
	_time_left = 0

func Pause():
	start = false
func Resume():
	start = true
