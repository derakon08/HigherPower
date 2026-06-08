extends Button
@export var highlighted_texture : Texture
@export var overshadowed_texture : Texture
@export var pointer_texture : Texture
@export var button_height : float

var _icon : NinePatchRect
var _pointer : TextureRect

func _ready() -> void:
	_icon = get_node("Textures/Icon")
	_pointer = get_node("Textures/Pointer")

	_ConnectSignals()

	_icon.texture = overshadowed_texture
	_pointer.texture = pointer_texture

	self.custom_minimum_size.y = max(button_height, get_theme_default_font_size())
	_pointer.custom_minimum_size = Vector2(button_height, button_height)


func _pressed() -> void:
	_attention_caught.call_deferred()

func _attention_lost():
	_icon.texture = overshadowed_texture
	_pointer.visible = false

func _attention_caught():
	_icon.texture = highlighted_texture
	_pointer.visible = true



func _ConnectSignals(): #Iterates over all the parent's child nodes and connects their focus_entered to self._attention_lost
	var siblings : Array[Node] = get_parent().get_children()
	#It also automatically fills in top and bottom focus neighbors
	var last_button_in_group : NodePath #Top by using the last button before itself
	var first_button_in_group : NodePath 

	var neighbor_top_very_last_button_in_group : bool = false #If this is the first button, then tag it to the very last button
	var connect_neighbor_bottom : bool = false #Bottom by tagging the next node, if no node is next then resort to the first one in the tree

	for index in siblings.size():
		if !siblings[index].is_in_group("menu_button"):
			continue
		elif !first_button_in_group:
			first_button_in_group = siblings[index].get_path()

		if siblings[index] != self:
			if connect_neighbor_bottom:
				self.focus_neighbor_bottom = siblings[index].get_path()
				connect_neighbor_bottom = false

			siblings[index].focus_entered.connect(_attention_lost)
			siblings[index].mouse_entered.connect(_attention_lost)

		else:
			if last_button_in_group:
				self.focus_neighbor_top = last_button_in_group
				self.focus_neighbor_left = last_button_in_group
			else:
				neighbor_top_very_last_button_in_group = true

			connect_neighbor_bottom = true
		
		last_button_in_group = siblings[index].get_path()
	

	if connect_neighbor_bottom:
		self.focus_neighbor_bottom = first_button_in_group
	if neighbor_top_very_last_button_in_group:
			self.focus_neighbor_top = last_button_in_group
		
	#And of course the node's own signals
	self.focus_exited.connect(_attention_lost)
	self.mouse_exited.connect(_attention_lost)
	self.mouse_entered.connect(_attention_caught)
	self.focus_entered.connect(_attention_caught)
