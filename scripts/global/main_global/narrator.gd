extends Node
@export var narration_box : Label
@export var text_speed : float = 0.1
@export var clear_wait : float = 1.0
@export var puntuation_wait : float = 0.5

var _narration : PackedStringArray
var _narration_index : int = 0

var _is_talking : bool = false
var _is_clearing : bool = false

var _clock : float = 0.0
var _puntuation_marks : PackedStringArray = [".", ";", "!", "\n"]
var _current_text : String

signal end_of_narration
signal finished_talking
signal clearing
signal interrupted

func _process(delta: float) -> void:
	if _is_talking: #Active during all text
		var visible_characters_left = _current_text.length() - narration_box.visible_characters
		_clock += delta

		if !_is_clearing && visible_characters_left > 0 && _clock >= text_speed:
			if (_puntuation_marks.has(_current_text[narration_box.visible_characters]) && _clock <= puntuation_wait): #If it's a special character, wait a little longer
				return

			_clock = 0
			narration_box.visible_characters += 1
		elif !_is_clearing && _clock >= clear_wait: #wait while the text is fully out
				_clock = 0
				_is_clearing = true
				clearing.emit()
		elif _is_clearing:
			if (_clock >= text_speed && narration_box.visible_characters > 0):
				_clock = 0
				narration_box.visible_characters -= 1
			elif (narration_box.visible_characters == 0):
				_is_talking = false
				_is_clearing = false

				finished_talking.emit()
				if (_narration_index >= _narration.size()):
					end_of_narration.emit()



func LoadNarration(narration : PackedStringArray):
	if _is_talking:
		_is_talking = false
		_is_clearing = false
		interrupted.emit()
		push_warning("You interrupted the reading! Consider using the end_of_narration and finished_talking signals to wait until done.")
	_narration = narration
	_narration_index = 0

func Talk(passing_speech : String = "") -> void:
	if _narration_index >= _narration.size() && passing_speech == "":
		push_warning("No valid speech given.")
		return
	elif _is_talking:
		_clock = 0
		interrupted.emit()

	if (passing_speech != ""):
		narration_box.text = passing_speech
		_current_text = passing_speech
	else:
		_current_text = _narration[_narration_index]
		narration_box.text = _narration[_narration_index]
		_narration_index += 1

	_is_clearing = false
	_clock = 0
	narration_box.visible_characters = 0
	_is_talking = true

func GetNarrationInOrder() -> Array:
	if _narration_index >= _narration.size():
		return [-1, _narration]
	return [_narration_index, _narration[_narration_index], _current_text]

func IsTalking():
	return _is_talking
