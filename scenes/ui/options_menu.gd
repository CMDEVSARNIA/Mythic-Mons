class_name OptionsMenu
extends Control
## The OPTION screen, from the start menu or the title screen: up/down picks
## a row, left/right (or A) changes it, and B or DONE saves and closes.
## Changes apply at once, so you hear a volume as you set it.
##
##     await options_menu.open()

signal _closed

const ROWS: Array[String] = ["TEXT SPEED", "BATTLE SCENE", "BATTLE STYLE", "MUSIC", "SOUND", "DONE"]
const CURSOR := "▶"

var _index := 0

@onready var _list: VBoxContainer = $Box/Layout/Rows
@onready var _hint: Label = $Box/Layout/Hint


func _ready() -> void:
	hide()
	for row in ROWS:
		var label := Label.new()
		_list.add_child(label)


func open() -> void:
	_index = 0
	_refresh()
	show()
	await _closed
	hide()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"move_up", true):
		_index = wrapi(_index - 1, 0, ROWS.size())
		Audio.play_sfx(&"select")
	elif event.is_action_pressed(&"move_down", true):
		_index = wrapi(_index + 1, 0, ROWS.size())
		Audio.play_sfx(&"select")
	elif event.is_action_pressed(&"move_left", true):
		_change(-1)
	elif event.is_action_pressed(&"move_right", true):
		_change(1)
	elif event.is_action_pressed(&"confirm"):
		if ROWS[_index] == "DONE":
			_close()
		else:
			_change(1)
	elif event.is_action_pressed(&"cancel") or event.is_action_pressed(&"menu"):
		_close()
	else:
		return
	get_viewport().set_input_as_handled()
	_refresh()


func _change(step: int) -> void:
	match ROWS[_index]:
		"TEXT SPEED":
			Settings.text_speed = wrapi(Settings.text_speed + step, 0, Settings.TEXT_SPEEDS.size())
		"BATTLE SCENE":
			Settings.battle_scene = not Settings.battle_scene
		"BATTLE STYLE":
			Settings.shift_style = not Settings.shift_style
		"MUSIC":
			Settings.music_volume = clampi(Settings.music_volume + step, 0, Settings.MAX_VOLUME)
		"SOUND":
			Settings.sound_volume = clampi(Settings.sound_volume + step, 0, Settings.MAX_VOLUME)
		_:
			return
	Settings.apply()
	Audio.play_sfx(&"select")


func _close() -> void:
	Settings.save_settings()
	Audio.play_sfx(&"menu")
	_closed.emit()


func _refresh() -> void:
	for i in ROWS.size():
		var label: Label = _list.get_child(i)
		var value := ""
		match ROWS[i]:
			"TEXT SPEED":
				value = Settings.TEXT_SPEEDS[Settings.text_speed]
			"BATTLE SCENE":
				value = "ON" if Settings.battle_scene else "OFF"
			"BATTLE STYLE":
				value = "SHIFT" if Settings.shift_style else "SET"
			"MUSIC":
				value = str(Settings.music_volume)
			"SOUND":
				value = str(Settings.sound_volume)
		var shown := "◀ %-5s ▶" % value if not value.is_empty() and i == _index else "  %-5s" % value
		label.text = "%s %-12s %s" % [CURSOR if i == _index else " ", ROWS[i], shown]
	_hint.text = {
		"TEXT SPEED": "How fast text appears.",
		"BATTLE SCENE": "OFF skips move\nanimations in battle.",
		"BATTLE STYLE": "SHIFT offers a switch\nwhen a foe sends out\nits next MONSTER.",
		"MUSIC": "Music volume (0-10).",
		"SOUND": "Sound effect volume\n(0-10).",
		"DONE": "Save and go back.",
	}[ROWS[_index]]
