extends Node
@export var fade_step : float = 0.5

var _displayed_nodes : Array[Dictionary] = []
var _queued_nodes : Array[Dictionary] = []

enum _status {WAIT_FOR_FADEOUT, WAIT_FOR_SNAPOUT, FADE_IN, FADE_OUT, SNAP_IN, SNAP_OUT, EXITED}

signal opaque(node : Node)
signal clear(node : Node)
signal next_in_queue(node_parent : String, new_node : Node)


func _process(delta: float) -> void:
	var exited_nodes : Array = [] #Any node that exits will be placed on queue
	for index in _displayed_nodes.size():
		var node = _displayed_nodes[index]["node"]

		if is_instance_valid(node) && !node.is_queued_for_deletion() && node.is_inside_tree():
			match (_displayed_nodes[index]["status"]): #manage according to a status
				_status.EXITED:
					exited_nodes.append(node)

				_status.FADE_IN:
					node.modulate.a += fade_step * delta

					if node.modulate.a >= 1:
						opaque.emit(node)

						_displayed_nodes[index]["status"] = _status.WAIT_FOR_FADEOUT
				
				_status.SNAP_IN:
					node.modulate.a = 1
					_displayed_nodes[index]["status"] = _status.WAIT_FOR_SNAPOUT

					opaque.emit(node)

				_status.FADE_OUT:
					node.modulate.a -= fade_step * delta

					if node.modulate.a <= 0:
						_displayed_nodes[index]["status"] = _status.EXITED

				_status.SNAP_OUT:
					node.modulate.a = 0
					_displayed_nodes[index]["status"] = _status.EXITED

				_: #If waiting
					if _displayed_nodes[index]["display_time_left"] == -1: #if it's -1 leave it be, else
						continue

					elif _displayed_nodes[index]["display_time_left"] >= 0: # if time left is not 0, take away from it, else
						_displayed_nodes[index]["display_time_left"] -= delta

					else: #tag it as exiting
						match _displayed_nodes[index]["status"]:
							_status.WAIT_FOR_FADEOUT:
								_displayed_nodes[index]["status"] = _status.FADE_OUT
							_status.WAIT_FOR_SNAPOUT:
								_displayed_nodes[index]["status"] = _status.SNAP_OUT

	_ExitedQueue(exited_nodes)



func ShowNewAt(scene_path : String,  parent_path : String, free_when_clear : bool = false, display_timeout : float = 0, fade_in : bool = true) -> Node: #single animation entry, directly into _displayed_nodes
	if get_node(parent_path) == null:
		push_error("Non existent node path: " + parent_path)
		return

	var scene : Node = load(scene_path).instantiate()
	scene.modulate.a = 0

	get_node(parent_path).add_child(scene)

	var entry : Dictionary = {
		"node": scene,
		"status": _status.FADE_IN if fade_in else _status.SNAP_IN,
		"delete_at_exit": free_when_clear,
		"display_time_left" : -1.0 if display_timeout <= 0 else display_timeout
	}

	_displayed_nodes.push_back(entry)
	return scene


#If a node has more than one queue, it will have somewhat unintended behaviour
func QueueNewAt(scene_paths : Array[String], parent_path : String, free_when_clear : bool = false, display_timeout : float = 0, fade_in : bool = true): #single animation entry, directly into _displayed_nodes
	if get_node(parent_path) == null:
		push_error("Non existent node path: " + parent_path)
		return

	ShowNewAt(scene_paths[0], parent_path, free_when_clear, display_timeout, fade_in)		

	var scene_paths_index = 1	
	while scene_paths_index < scene_paths.size():
		var entry : Dictionary = {
			"parent_path": parent_path,
			"status": _status.FADE_IN if fade_in else _status.SNAP_IN,
			"delete_at_exit": free_when_clear,
			"display_time_left" : -1.0 if display_timeout <= 0 else display_timeout,
			"scene_path": scene_paths[scene_paths_index]
		}
		_queued_nodes.push_back(entry)

		scene_paths_index += 1



func ShowNodeAt(node : Node, free_when_clear : bool = false, display_timeout : float = 0, fade_in : bool = true): #single animation entry, directly into _displayed_nodes
	for entry in _displayed_nodes:
		if entry["node"] == node:
			push_warning("Node is already being displayed: " + node.name)
			return

	var entry : Dictionary = {
		"node": node,
		"status": _status.FADE_IN if fade_in else _status.SNAP_IN,
		"delete_at_exit": free_when_clear,
		"display_time_left" : -1.0 if display_timeout <= 0 else display_timeout
	}

	_displayed_nodes.push_back(entry)

func ShowNodeAtSafe(node : Node, free_when_clear : bool = false, display_timeout : float = 0, fade_in : bool = true): #Safe as in: will not mess it up and clog the displayed nodes
	for entry in _displayed_nodes:
		if entry["node"] == node:
			await AwaitClear(node)
			break
	ShowNodeAt(node, free_when_clear, display_timeout, fade_in)


func ExitAt(node : Node):
	_ExitAt.call_deferred(node)

func _ExitAt(node : Node):
	for index in _displayed_nodes.size():
		if _displayed_nodes[index]["node"] == node:
			match _displayed_nodes[index]["status"]:
				_status.WAIT_FOR_FADEOUT:
					_displayed_nodes[index]["status"] = _status.FADE_OUT
				_status.WAIT_FOR_SNAPOUT:
					_displayed_nodes[index]["status"] = _status.SNAP_OUT
				_status.FADE_IN:
					_displayed_nodes[index]["status"] = _status.FADE_OUT
				_status.SNAP_IN:
					_displayed_nodes[index]["status"] = _status.SNAP_OUT



func ClearAt(parent_path : String):
	_ClearAt.call_deferred(parent_path)

func _ClearAt(parent_path : String):
	var node_parent : Node = get_node(parent_path)

	for index in range(_displayed_nodes.size() - 1, -1, -1):
		if node_parent.is_ancestor_of(_displayed_nodes[index]["node"]):
			_displayed_nodes[index]["status"] = _status.EXITED

	for index in range(_queued_nodes.size() - 1, -1, -1):
		if _queued_nodes[index]["parent_path"] == parent_path:
			_queued_nodes.remove_at(index)



func _ExitedQueue(exited_nodes : Array): #cleanup helper
	for index in range(_displayed_nodes.size() - 1, -1, -1): #iterate backwards and erase nodes and info
		if exited_nodes.has(_displayed_nodes[index]["node"]):
			if _displayed_nodes[index]["delete_at_exit"]:
				_displayed_nodes[index]["node"].queue_free()

			clear.emit(_displayed_nodes[index]["node"])
			_displayed_nodes.erase(_displayed_nodes[index])

	for node in exited_nodes: #look for nodes in queue
		var node_parent_path : String = node.get_parent().get_path()

		for entry in _queued_nodes:
			if !(node_parent_path == entry["parent_path"]):
				continue
			
			var new_displayed_node : Node = ShowNewAt(entry["scene_path"], entry["parent_path"], entry["delete_at_exit"],  entry["display_time_left"], entry["status"] == _status.FADE_IN)

			next_in_queue.emit(entry["parent_path"], new_displayed_node)
			_queued_nodes.erase(entry)
			break #break if it finds a node in queue



func AwaitOpaque(node: Node):
	while true:
		var signal_args = await opaque
		
		if signal_args == node:
			return signal_args

func AwaitClear(node: Node):
	while true:
		var signal_args = await clear
		
		if signal_args == node:
			return signal_args

func AwaitNextInQueue(parent_path : String):
	while true:
		var signal_args = await next_in_queue
		print(signal_args)
		
		if signal_args[0] == parent_path:
			return signal_args[1]