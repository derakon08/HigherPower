extends Node
var thelabel : Label
var display_in : int = 0

const ITERATIONS := 10000
var acc := 0.0
var color : Color

func _ready():
	_init_thing()
	

func _init_thing():
	thelabel = $Label


func StartTest(line : String, accuracy : float, function : Callable) -> void:
	acc = 0

	var t0 := Time.get_ticks_usec()
	function.call()
	var t1 := Time.get_ticks_usec()

	print(line + " time: ", t1 - t0, " Var: " + str(accuracy))
	acc = 0



func _process(_delta):
	display_in += 1

	if display_in > 60:
		thelabel.text = str(Engine.get_frames_per_second())
