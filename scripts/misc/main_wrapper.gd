extends Node

func _ready() -> void:
    Main.player.Switch(false)
    Main.LoadNode("res://scenes/levels/main_menu/main_menu.tscn", false)
    get_viewport().grab_focus()
