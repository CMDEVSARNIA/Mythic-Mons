class_name QuantityBox
extends PanelContainer
## Picks how many of an item to buy or sell, showing the total price.
## Up/down change the count by 1 (wrapping around), left/right by 10.
##
##     var count: int = await quantity_box.pick(most, unit_price)  # 0 = cancelled

signal _picked(count: int)

var _count := 1
var _most := 1
var _unit_price := 0
var _active := false

@onready var _label: Label = $Label


func _ready() -> void:
	hide()


func pick(most: int, unit_price: int) -> int:
	_count = 1
	_most = maxi(most, 1)
	_unit_price = unit_price
	_refresh()
	show()
	_active = true
	var count: int = await _picked
	_active = false
	hide()
	return count


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed(&"move_up", true):
		_count = wrapi(_count + 1, 1, _most + 1)
	elif event.is_action_pressed(&"move_down", true):
		_count = wrapi(_count - 1, 1, _most + 1)
	elif event.is_action_pressed(&"move_right", true):
		_count = mini(_count + 10, _most)
	elif event.is_action_pressed(&"move_left", true):
		_count = maxi(_count - 10, 1)
	elif event.is_action_pressed(&"confirm"):
		Audio.play_sfx(&"select")
		_picked.emit(_count)
	elif event.is_action_pressed(&"cancel"):
		Audio.play_sfx(&"select")
		_picked.emit(0)
	else:
		return
	get_viewport().set_input_as_handled()
	_refresh()


func _refresh() -> void:
	_label.text = "x%2d %7s" % [_count, "$%d" % (_count * _unit_price)]
