extends Node
var save_path : StringName = "res://.data/savestate.bin"
var save_dir_path : StringName = "res://.data/"
var _completed_levels : Array[bool] = [false, false, false, false, false]  
var _completed_tutorial : bool = false
var _completed_prologue : bool = false

func _ready() -> void:
	Load()
	Save()

func Save():
	if !DirAccess.open("res://").dir_exists(save_dir_path):
		DirAccess.open("res://").make_dir(save_dir_path)
	
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)

	if save_file:
		var dict : Dictionary = {
			"completed_levels": _completed_levels,
			"completed_tutorial": _completed_tutorial,
			"completed_prologue": _completed_prologue,
		}
		save_file.store_var(dict)
		save_file.close()

func Load():
	if !FileAccess.file_exists(save_path):
		return
	
	var save_file = FileAccess.open(save_path, FileAccess.READ)

	if !save_file:
		return
	
	var saved_data = save_file.get_var()

	if typeof(saved_data) != TYPE_DICTIONARY:
		push_warning("Saved data is not of the expected type. Expected: Dictionary. Got: " + str(typeof(saved_data)))
		save_file.close()
		return
	save_file.close()

	_completed_levels = saved_data["completed_levels"]
	_completed_tutorial = saved_data["completed_tutorial"]
	_completed_prologue = saved_data["completed_prologue"]

func WipeData():
	DirAccess.open(save_dir_path).remove(save_path)

func CompletedLevel(level : int):
	if level == 6:
		_completed_prologue = true
	elif level == 0:
		_completed_tutorial = true
	else:
		level -= 1
		_completed_levels[level] = true

func IsTutorialClear() -> bool:
	return _completed_tutorial

func IsPrologueClear() -> bool:
	return _completed_prologue

func AllLevelsClear() -> bool:
	return _completed_levels.all(func(a): return a == true)
