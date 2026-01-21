extends Control
@export var side_pointers : HBoxContainer
@export var top_pointer : TextureRect
@export var bottom_pointer : TextureRect
@export var HP_bar : TextureProgressBar
@export var hurt_color : ColorRect
@export var hurt_color_timeout : Timer
@export var hit_shake_value_max : Vector2
@export var hit_shake_strength : float
@export_range(0.0, 1.0) var hit_shake_easing : float

var _pointers_size_halved : Vector2
var _node_to_follow : Node
var _screen_size : Vector2
var _margin_size : Vector2
var _shake_value : Vector2
var _shake : bool = false

signal player_death

func _ready():
    randomize()
    _margin_size = get_node("Margin/Top/DotLeft").texture.get_size()
    _pointers_size_halved = top_pointer.texture.get_size()
    _pointers_size_halved /= 2

    _screen_size = Main.game_area.size
    _screen_size.x -= _margin_size.x * 2
    _screen_size.y -= _margin_size.y + _pointers_size_halved.y

    Main.player.player_hit.connect(PlayerHit)
    hurt_color_timeout.timeout.connect(_ResetHitEffects)
    Main.DEBUG.connect(DEBUG)

    if !_node_to_follow:
        bottom_pointer.visible = false


func _process(_delta: float) -> void:
    _MovePointers()

    if _shake:
        _Shake()
 

func _MovePointers() -> void:
    top_pointer.global_position.x = clamp(Main.player.global_position.x - _pointers_size_halved.x, _margin_size.x, _screen_size.x)
    side_pointers.global_position.y = clamp(Main.player.global_position.y - _pointers_size_halved.y, _margin_size.y, _screen_size.y - _pointers_size_halved.y)
    
    if _node_to_follow:
        bottom_pointer.global_position.x = _node_to_follow.global_position.x - _pointers_size_halved.x
    else:
        bottom_pointer.visible = false


func _Shake():
    _shake_value = lerp(_shake_value, Vector2.ZERO, hit_shake_easing)

    if _shake_value <= Vector2.ZERO:
        _shake = false
        position.x = 0
        position.y = 0

    else:
        position.x = randf_range(-1.0, 1.0) * _shake_value.x
        position.y = randf_range(-1.0, 1.0) * _shake_value.y


func _ResetHitEffects():
    hurt_color.visible = false

    if HP_bar.value <= 20:
        HP_bar.tint_progress = Color.WHITE





func PlayerHit():
    HP_bar.value -= HP_bar.step
    _shake_value += hit_shake_value_max * hit_shake_strength
    _shake = true
    hurt_color.visible = true
    hurt_color_timeout.start()

    if HP_bar.value <= 20:
        HP_bar.tint_progress = Color.RED
        hurt_color.color = Color.INDIAN_RED

    if HP_bar.value <= 0:
        player_death.emit()



func FollowEnemy(node : Node):
    _node_to_follow = node
    bottom_pointer.visible = true


func DEBUG():
    PlayerHit()
