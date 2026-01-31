extends Node
@export var thelabel : Label
@export var dialog : FileDialog
var display_in : int = 0

const ITERATIONS := 10000
var _acc := 0.0
var color : Color

var _right_click_position : Vector2

func _ready():
	_init_thing()
	

func _init_thing():
	pass


func StartTest(line : String, accuracy : float, function : Callable) -> void:
	_acc = 0

	var t0 := Time.get_ticks_usec()
	function.call()
	var t1 := Time.get_ticks_usec()

	print(line + " time: ", t1 - t0, " Var: " + str(accuracy))
	_acc = 0


func _input(event : InputEvent):
	if event is InputEventMouseButton && event.get(&"button_index") == 2 && event.get(&"pressed") == true:
		_right_click_position = event.get(&"position")
		dialog.visible = true



func _process(_delta):
	display_in += 1

	if display_in > 60:
		thelabel.text = str(Engine.get_frames_per_second())


func _OnFileDialogFileSelected(path: String) -> void:
	if FileAccess.file_exists(path):
		var new_scene : PackedScene = load(path)
		var new_instance = new_scene.instantiate()

		if new_instance is Node2D:
			new_instance.global_position = _right_click_position
		
		add_child.call_deferred(new_instance)
