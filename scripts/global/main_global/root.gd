extends Node
@export var player : Node
@export var pause_menu : Control
@export var bg : ColorRect
@export var transition_decor : Control
@export var narrator : Control
@export var world_freeze_timer : Timer

@export_group("Debug")
@export var debug : bool = false
@export var debug_camera : bool = false

var _player_normal_speed : int
var _player_focus_speed : int
var _player_fire_rate : int

var game_area : Rect2
var screen_slots : NodePath
var _transition_node_abs_path : NodePath

var _game_state_flag : game_state = game_state.ON_MENU
var _current_level_scene : StringName
var _current_level_node : Node
 
#The idea to use the signal is to add a freeze function to every node that needs it
signal freeze_world
signal unfreeze_world
signal DEBUG

enum game_state {ON_MENU, ON_GAME, ON_PAUSE}


#built in
func _ready() -> void:
	_player_normal_speed = player.normal_speed
	_player_focus_speed = player.focus_speed
	_player_fire_rate = player.fire_rate
	_transition_node_abs_path = get_node("NonPausable/Control/Transitions").get_path()
	screen_slots = get_node("Pauseable/Control/ScreenSlots").get_path()

	world_freeze_timer.timeout.connect(unfreeze_world.emit)

	if (!debug):
		player.Switch(false)
		game_area = $MainCamera.get_viewport().get_visible_rect()
		LoadNode("res://scenes/main_menu/main_menu.tscn", false)
	else:
		player.Switch(true)
		_game_state_flag = game_state.ON_GAME

		if (debug_camera):
			$MainCamera.enabled = false
			$NonPausable/Border.position = $DebugCamera.position
			game_area = Rect2($DebugCamera.global_position, get_viewport().size)
		
		for index in 7:
			Savestate.CompletedLevel(index)
			return

func _input(event: InputEvent) -> void:
	if event.is_action_released("pause"):
		match _game_state_flag:
			game_state.ON_MENU:
				pass
			game_state.ON_PAUSE:
				_ResumeGame()
			game_state.ON_GAME:
				_PauseGame()

	elif (event.is_action_released("debug_button") && debug):
		player.get_node("BombCooldown").wait_time = 3
		DEBUG.emit()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if debug: Savestate.WipeData()
		get_tree().quit()


#global methods
func TimeStop(timeout : float):
	freeze_world.emit()
	world_freeze_timer.start(timeout)

func SetBackgroundColor(color : Color) -> void:
	transition_decor.get_node("BG").color = color
	bg.color = color

func InvertBackgroundColor() -> void:
	var inverted_color = Color(
		abs(bg.color.r - 1.0),
		abs(bg.color.g - 1.0),
		abs(bg.color.b - 1.0),
		bg.color.a
	)
	SetBackgroundColor(inverted_color)

func LoadNode(path : String, can_pause : bool) -> void:
	var scene = load(path)
	FadeModulator.ShowNodeAtSafe(transition_decor)

	await FadeModulator.AwaitOpaque(transition_decor)
	var scene_instance = scene.instantiate()

	if can_pause:
		$Pauseable.add_child(scene_instance)

		if scene_instance.is_in_group("game_level"):
			_current_level_node = get_node("Pauseable/" + scene_instance.name)
			_current_level_scene = path

	else:
		$NonPausable.add_child(scene_instance)
	
	FadeModulator.ExitAt(transition_decor)

func ResetPlayerSettings() -> void:
	player.normal_speed = _player_normal_speed
	player.focus_speed = _player_focus_speed
	player.fire_rate = _player_fire_rate

func GameStart(spawn : Vector2) -> void:
	_ResumeGame()
	_game_state_flag = game_state.ON_GAME
	player.global_position = spawn
	player.Switch(true)

func GameEnd() -> void:
	if _current_level_node == null:
		push_error("No current level is playing")
		return

	LoadNode("res://scenes/main_menu/main_menu.tscn", false)
	_current_level_node.queue_free()
	_ResumeGame()
	_game_state_flag = game_state.ON_MENU
	player.Switch(false)

	_current_level_node = null
	_current_level_scene = &""
	narrator.Talk(" ")

func Restart() -> void:
	if _current_level_scene.is_empty():
		push_error("No current level is playing")
		return

	player.Switch(false)
	LoadNode(_current_level_scene, true)
	_current_level_node.queue_free()
	_ResumeGame()
	narrator.Talk(" ")

#helpers
func _PauseGame() -> void:
	_game_state_flag = game_state.ON_PAUSE
	pause_menu.visible = true
	pause_menu.grab_focus()
	$Pauseable.process_mode = Node.PROCESS_MODE_DISABLED

func _ResumeGame() -> void:
	_game_state_flag = game_state.ON_GAME
	pause_menu.visible = false
	$Pauseable.process_mode = Node.PROCESS_MODE_PAUSABLE
