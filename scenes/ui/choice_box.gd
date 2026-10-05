class_name ChoiceBox
extends PanelContainer
## An option list with a ▶ cursor, used by the start menu, Dialogue.ask()
## and battle menus. `await choose([...])` returns the picked index, or -1
## when the player cancels with B. Set `columns` for a grid (e.g. FIGHT/BAG
## over MON/RUN), or `max_rows` to scroll a long single-column list.

signal cursor_moved(index: int)
signal _chosen(index: int)

const CURSOR := "▶"
const MORE_ABOVE := "▲"
const MORE_BELOW := "▼"

@export_range(1, 4) var columns := 1:
	set(value):
		columns = value
		if is_node_ready():
			_list.columns = value
## Rows shown at once in a one-column list; longer lists scroll, with ▲ and ▼
## marking more options above or below. 0 shows every option.
@export_range(0, 20) var max_rows := 0

var _options: PackedStringArray = []
var _index := 0
## First option on screen while scrolling.
var _top := 0
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
	for i in (mini(options.size(), max_rows) if _scrolls() else options.size()):
		_list.add_child(Label.new())
	_index = clampi(start_index, 0, maxi(options.size() - 1, 0))
	_top = 0
	_follow_cursor()
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
	_follow_cursor()
	_refresh()
	cursor_moved.emit(_index)


func _scrolls() -> bool:
	return max_rows > 0 and columns == 1 and _options.size() > max_rows


## Scrolls just enough to keep the cursor on screen.
func _follow_cursor() -> void:
	if not _scrolls():
		_top = 0
	elif _index < _top:
		_top = _index
	elif _index >= _top + max_rows:
		_top = _index - max_rows + 1


func _refresh() -> void:
	var scrolls := _scrolls()
	var width := 0
	if scrolls: # Pad options to one width so the ▲ ▼ marks line up.
		for option in _options:
			width = maxi(width, option.length())
	var rows := _list.get_child_count()
	for row in rows:
		var i := _top + row
		var label: Label = _list.get_child(row)
		var cursor := CURSOR if i == _index else " "
		if not scrolls:
			label.text = "%s %s" % [cursor, _options[i]]
			continue
		var mark := " "
		if row == 0 and _top > 0:
			mark = MORE_ABOVE
		elif row == rows - 1 and _top + rows < _options.size():
			mark = MORE_BELOW
		label.text = "%s %s %s" % [cursor, _options[i].rpad(width), mark]
