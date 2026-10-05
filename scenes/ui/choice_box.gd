class_name ChoiceBox
extends PanelContainer
## An option list with a ▶ cursor, used by the start menu, Dialogue.ask()
## and battle menus. `await choose([...])` returns the picked index, or -1
## when the player cancels with B. Set `columns` for a grid (e.g. FIGHT/BAG
## over MON/RUN).

signal cursor_moved(index: int)
signal _chosen(index: int)

const CURSOR := "▶"

@export_range(1, 4) var columns := 1:
	set(value):
		columns = value
		if is_node_ready():
			_list.columns = value

var _options: PackedStringArray = []
var _index := 0
var _active := false

@onready var _list: GridContainer = $List


func _ready() -> void:
	_list.columns = columns
	hide()


func choose(options: PackedStringArray, start_index := 0) -> int:
	for label in _list.get_children():
		_list.remove_child(label)
		label.free()
	_options = options
	for i in options.size():
		_list.add_child(Label.new())
	_index = clampi(start_index, 0, maxi(options.size() - 1, 0))
	_refresh()
	show()
	_active = true
	cursor_moved.emit(_index)
	var result: int = await _chosen
	_active = false
	hide()
	return result


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed(&"move_up", true):
		_move(-columns)
	elif event.is_action_pressed(&"move_down", true):
		_move(columns)
	elif event.is_action_pressed(&"move_left", true) and columns > 1:
		_move(-1)
	elif event.is_action_pressed(&"move_right", true) and columns > 1:
		_move(1)
	elif event.is_action_pressed(&"confirm"):
		Audio.play_sfx(&"select")
		_chosen.emit(_index)
	elif event.is_action_pressed(&"cancel"):
		Audio.play_sfx(&"select")
		_chosen.emit(-1)
	else:
		return
	get_viewport().set_input_as_handled()


func _move(step: int) -> void:
	_index = wrapi(_index + step, 0, _options.size())
	_refresh()
	cursor_moved.emit(_index)


func _refresh() -> void:
	for i in _options.size():
		var label: Label = _list.get_child(i)
		label.text = "%s %s" % [CURSOR if i == _index else " ", _options[i]]
