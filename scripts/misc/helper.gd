class_name Helper

static func _SwapItemBackAndPop(array : Array, index : int) -> void:
	array[index] = array[array.size() - 1] #copy the last item of the array at the index to delete
	array.resize(array.size() -1) #delete duplicate


static func _SwapItemBackAndPopArray(arrays : Array[Array], index : int) -> void:
	for external_index in arrays.size(): #for each array passed
		arrays[external_index][index] = arrays[external_index][arrays[external_index].size() - 1] #place the item (arrays) in last place to the index given
		arrays[external_index].resize(arrays[external_index].size() -1) #delete duplicate


static func _JaggedSwapItemBackAndPopArray(arrays : Array[Array], index : int) -> void:
	for parameter_array in arrays: #for each jagged array passed
		for inner_index in parameter_array.size() - 1: #for each array inside the array passed
			parameter_array[inner_index][index] = parameter_array[inner_index][parameter_array.size() - 1] #place the item (nodes) in the last place to the index given
			parameter_array[inner_index].resize(parameter_array[inner_index].size() -1) #delete the duplicate