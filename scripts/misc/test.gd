extends Node
@export var thelabel : Label
@export var dialog : FileDialog
var display_in : int = 0

const ITERATIONS := 1000
var dict : Dictionary[String, int]
var dictint : Dictionary[int, int]
var arrstr : Array[String]
var arrint : Array[int]
var _acc := 0.0
var color : Color

var _right_click_position : Vector2

func _ready():
	get_viewport().grab_focus()
	_init_thing()
	

func _init_thing():
	Main.player.Switch(true)
	Main._game_state_flag = Main.game_state.ON_GAME


func StartTest(line : String, accuracy : float, function : Callable) -> void:
	_acc = 0

	var t0 := Time.get_ticks_usec()
	function.call()
	var t1 := Time.get_ticks_usec()

	print(line + " time: ", t1 - t0, " Var: " + str(accuracy))
	_acc = 0

func test1():
	for repeater in ITERATIONS:
		for thing in ITERATIONS:
			dict.has(arrstr[thing])
			_acc += 1

func test2():
	for repeater in ITERATIONS:
		for thing in ITERATIONS:
			arrstr.has(arrstr[thing])
			_acc += 1

func test3():
	for repeater in ITERATIONS:

		for thing in ITERATIONS:
			arrint.has(arrint[thing])
			_acc += 1

func test4():
	for repeater in ITERATIONS:
		
		for thing in ITERATIONS:
			dictint.has(arrint[thing])
			_acc += 1


func _input(event : InputEvent):
	if event is InputEventMouseButton && event.get(&"button_index") == 2 && event.get(&"pressed") == true:
		_right_click_position = event.get(&"position")
		dialog.visible = true
	elif (event.is_action_released("debug_button")):
		get_node("/root/Main/Rainbow").current_animation = "effects/rainbow"
		Main.player.get_node("BombCooldown").wait_time = 3
		Main.DEBUG.emit()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Savestate.WipeData()



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