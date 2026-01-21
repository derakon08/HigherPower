extends Control
@export var tabs_node : Control
@export var tutorial_button : Button

var _loading_level : bool = false


func _ready() -> void:
	$SelfDestruct.call_deferred("grab_focus")
	_LoadLevelButtons()
	tabs_node.current_tab = -1 #Set to empty

	$MarginContainer/HBoxContainer/MenuButtons/Quit.pressed.connect(Main._GameClose)


func _button_pressed(index : int): #This one takes an assigned button index and loads the corresponding tab in the sidebar
	var node = tabs_node.get_child(index)

	if index != 0: #NOT start button means any of the other tabs which use text or animations... which can't be seen if placed on the background
		tabs_node.self_modulate.a = 1
	else:
		tutorial_button.grab_focus()
		tabs_node.self_modulate.a = 0
	
	node.visible = true

func _level_button_pressed(scene : String):
	if (_loading_level):
		return
	else:
		_loading_level = true
		var path : String = "res://scenes/levels/" + scene + '/' + scene + ".tscn"
		print(path)
		await Main.LoadNode(path, true)
		queue_free() #Wait for root to obscure the screen


func _LoadLevelButtons():

	if !Savestate.IsTutorialClear(): #Hide levels
		var levels_list = get_node("MarginContainer/HBoxContainer/SidePanelMargin/SidePanel/Levels").get_children()
		for node in levels_list:
			if node.name != "Tutorial":
				node.visible = false
				node.focus_mode = Control.FOCUS_NONE
	
	if Savestate.AllLevelsClear():
		get_node("MarginContainer/HBoxContainer/MenuButtons/Prologue").visible = true
		

func SelfDestructButton():
	$SelfDestruct.queue_free()
