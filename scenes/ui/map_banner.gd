class_name MapBanner
extends PanelContainer
## Emerald-style location name that slides in at the top-left on entering a map.

const HIDDEN_Y := -32.0
const SHOWN_Y := 2.0

var _tween: Tween

@onready var _label: Label = $Label


func _ready() -> void:
	position.y = HIDDEN_Y


func show_name(text: String) -> void:
	_label.text = text
	reset_size()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position:y", SHOWN_Y, 0.25)
	_tween.tween_interval(1.8)
	_tween.tween_property(self, "position:y", HIDDEN_Y, 0.25)
