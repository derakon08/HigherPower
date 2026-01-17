extends Node
#simple timer for lightweight timing needs... i deleted my better one

@export var time : float
@export var start : bool = false
@export var loop : bool = false

var time_left : float

signal timeout


func _ready() -> void:
	time_left = time

	if start: Start()


func _process(delta: float) -> void:
	if start:
		if time_left > 0:
			time_left -= delta
		else:
			timeout.emit()
			print("Timeout")
			start = false

			if loop: 
				time_left = time
				start = true

func Start():
	time_left = time
	start = true
func Stop():
	start = false
	time_left = time

func Pause():
	start = false
func Resume():
	start = true
