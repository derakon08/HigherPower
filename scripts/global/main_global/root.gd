extends Node
@export var player : Node
@export var enemies_dead_zone : Rect2i
@export var pause_menu : Control
@export var bg : ColorRect
@export var transition_decor : Control
@export var narrator : Control
@export var world_freeze_timer : Timer

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
signal warp
signal DEBUG

enum game_state {ON_MENU, ON_GAME, ON_PAUSE}


#built in
func _ready() -> void:
	_player_normal_speed = player.normal_speed
	_player_focus_speed = player.focus_speed
	_player_fire_rate = player.fire_rate
	_transition_node_abs_path = get_node("NonPausable/Control/Transitions").get_path()
	screen_slots = get_node("Pauseable/Control/ScreenSlots").get_path()
	game_area = $MainCamera.get_viewport().get_visible_rect()

	BulletMap.AddNewCollisionGroup("enemies")
	BulletMap.AddNewCollisionGroup("player")

	world_freeze_timer.timeout.connect(unfreeze_world.emit)

func _input(event: InputEvent) -> void:
	if event.is_action_released("pause"):
		match _game_state_flag:
			game_state.ON_MENU:
				pass
			game_state.ON_PAUSE:
				_ResumeGame()
			game_state.ON_GAME:
				_PauseGame()


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
	
	_ResumeGame()
	narrator.Talk(" ")
	_game_state_flag = game_state.ON_MENU
	player.Switch(false)

	LoadNode("res://scenes/main_menu/main_menu.tscn", false)
	BulletMap.Reset()
	BulletMap.AddObjectiveToGroup("player", Main.player, get_node("/root/Main/Pauseable/Player/CollisionShape2D").shape.radius)
	_current_level_node.queue_free()
	_current_level_node = null
	_current_level_scene = &""

func Restart() -> void:
	if _current_level_scene.is_empty():
		push_error("No current level is playing")
		return

	player.Switch(false)
	_ResumeGame()
	narrator.Talk(" ")

	LoadNode(_current_level_scene, true)
	BulletMap.Reset()
	BulletMap.AddObjectiveToGroup("player", Main.player, get_node("/root/Main/Pauseable/Player/CollisionShape2D").shape.radius)
	_current_level_node.queue_free()

#helpers
func _PauseGame() -> void:
	_game_state_flag = game_state.ON_PAUSE
	BulletMap.Pause()
	pause_menu.visible = true
	pause_menu.grab_focus()
	$Pauseable.process_mode = Node.PROCESS_MODE_DISABLED

func _ResumeGame() -> void:
	BulletMap.Unpause()
	_game_state_flag = game_state.ON_GAME
	pause_menu.visible = false
	$Pauseable.process_mode = Node.PROCESS_MODE_PAUSABLE

func _GameClose() -> void:
	FadeModulator.ShowNodeAtSafe(transition_decor)
	await FadeModulator.AwaitOpaque(transition_decor)

	get_tree().quit()