extends Node

##Time at the very start of the level (or this script's _ready call)
@export var level_start_delay : float = 0.0

##Enemies must inherit from RoutableEnemy2D
@export var game_rounds : Array[RoutableEnemy2DRound]

var _round_index : int = 0
var _round_amount : int = 0
var _enemies_left : int = 0

var _timer : TimerCustom = TimerCustom.new()


signal finished_level_rounds




func _ready() -> void:
    _round_amount = game_rounds.size()

    if _round_amount < 1:
        push_error("No rounds setup: " + str(get_path()))
        return

    _timer.timeout.connect(_OnTimeOut)
    _timer.StartNewTime(level_start_delay)


func _OnTimeOut():
    if _enemies_left > 1:
        var round_data = game_rounds[_round_index]
        var new_enemy = round_data.enemy.instantiate()

        new_enemy.route = round_data.enemy_route
        new_enemy.global_position = round_data.enemy_spawn_position
        _enemies_left -= 1
        
        self.add_child(new_enemy)
        _timer.Start()
    
    elif _round_index < _round_amount:
        var round_data = game_rounds[_round_index]
        
        _enemies_left = round_data.enemy_count
        _round_index += 1

        _timer.StartNewTime(round_data.round_delay)
        _timer.time = round_data.enemy_spawn_timer
    
    else:
        finished_level_rounds.emit()