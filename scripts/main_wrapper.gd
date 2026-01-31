extends Node

func _ready() -> void:
    Main.player.Switch(false)
    Main.LoadNode("res://scenes/main_menu/main_menu.tscn", false)
