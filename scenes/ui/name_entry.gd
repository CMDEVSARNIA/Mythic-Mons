extends CanvasLayer
## The naming screen (autoload "NameEntry"), like Emerald's: a keyboard of
## letters, digits and marks above SPACE / BACK / OK. The arrows move, A types
## the key (or picks SPACE, BACK or OK), B deletes the last letter and START
## jumps to OK. Typing the last letter that fits jumps to OK too.
##
##     var typed: String = await NameEntry.ask("YOUR NAME?", 7, picture)
##
## Returns the name with outer spaces trimmed, or "" if it was left empty, so
## each caller picks its own default.
##
## offer_nickname() asks "Give a nickname to X?" first (after a catch, or
## when a monster is received); rename() goes straight to the screen.

signal _finished

const ROWS := ["ABCDEFGHIJ", "KLMNOPQRST", "UVWXYZ.,-'", "0123456789"]
const ACTIONS := ["SPACE", "BACK", "OK"]
## The keyboard column each action sits under; moving down from a column
## lands on the action whose span covers it.
const ACTION_COLUMNS := [1, 5, 8]
const BLANK := "_"
const HIGHLIGHT := Color(0.231, 0.365, 0.788)

var is_open := false

var _text := ""
var _max_length := 10
var _row := 0
var _column := 0
var _keys: Array[Label] = [] # Row by row, then the actions.
var _selected_box: StyleBoxFlat

@onready var _screen: Control = $Screen
@onready var _picture: TextureRect = $Screen/Top/Layout/Picture
@onready var _prompt: Label = $Screen/Top/Layout/Text/Prompt
@onready var _name: Label = $Screen/Top/Layout/Text/Name
@onready var _grid: GridContainer = $Screen/Keys/Layout/Grid
@onready var _actions: HBoxContainer = $Screen/Keys/Layout/Actions


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen.hide()
	_selected_box = StyleBoxFlat.new()
	_selected_box.bg_color = HIGHLIGHT
	_selected_box.set_corner_radius_all(2)
	_grid.columns = ROWS[0].length()
	for row in ROWS:
		for letter in row:
			_keys.append(_add_key(_grid, letter, Vector2(16, 11)))
	for action in ACTIONS:
		_keys.append(_add_key(_actions, action, Vector2(56, 11)))


## Opens the screen and waits for OK. `picture` (a monster, the player) is
## shown next to `prompt`; `start_text` is pre-filled.
func ask(prompt: String, max_length: int, picture: Texture2D = null, start_text := "") -> String:
	_max_length = max_length
	_text = start_text.left(max_length)
	_row = 0
	_column = 0
	_prompt.text = prompt
	_picture.texture = picture
	_picture.visible = picture != null
	_refresh()
	_screen.show()
	is_open = true
	await _finished
	is_open = false
	_screen.hide()
	return _text.strip_edges()


## "Give a nickname to X?" and, on YES, the naming screen.
func offer_nickname(monster: Monster) -> void:
	if await Dialogue.ask("Give a nickname to\n%s?" % monster.species.display_name) == 0:
		await rename(monster)


## Opens the naming screen for `monster`. An empty name, or the species
## name, clears the nickname.
func rename(monster: Monster) -> void:
	var species_name := monster.species.display_name
	var typed: String = await ask("%s'S NAME?" % species_name, Monster.MAX_NICKNAME_LENGTH,
		monster.species.front_texture, monster.nickname)
	monster.nickname = "" if typed == species_name else typed


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(&"move_up", true):
		_move(Vector2i.UP)
	elif event.is_action_pressed(&"move_down", true):
		_move(Vector2i.DOWN)
	elif event.is_action_pressed(&"move_left", true):
		_move(Vector2i.LEFT)
	elif event.is_action_pressed(&"move_right", true):
		_move(Vector2i.RIGHT)
	elif event.is_action_pressed(&"confirm"):
		_press()
	elif event.is_action_pressed(&"cancel"):
		_delete()
	elif event.is_action_pressed(&"menu"):
		_go_to_ok()
	else:
		return
	get_viewport().set_input_as_handled()


func _move(direction: Vector2i) -> void:
	var on_actions := _row == ROWS.size()
	if direction.x != 0 and on_actions:
		var action := wrapi(_action_index() + direction.x, 0, ACTIONS.size())
		_column = ACTION_COLUMNS[action]
	elif direction.x != 0:
		_column = wrapi(_column + direction.x, 0, ROWS[0].length())
	else:
		_row = wrapi(_row + direction.y, 0, ROWS.size() + 1)
	_refresh()


func _press() -> void:
	Audio.play_sfx(&"select")
	if _row < ROWS.size():
		_type(ROWS[_row][_column])
		return
	match ACTIONS[_action_index()]:
		"SPACE":
			_type(" ")
		"BACK":
			_delete()
		"OK":
			_finished.emit()


func _type(letter: String) -> void:
	if _text.length() >= _max_length:
		return
	_text += letter
	if _text.length() == _max_length:
		_go_to_ok()
	_refresh()


func _delete() -> void:
	if _text.is_empty():
		return
	Audio.play_sfx(&"select")
	_text = _text.left(-1)
	_refresh()


func _go_to_ok() -> void:
	_row = ROWS.size()
	_column = ACTION_COLUMNS[ACTIONS.find("OK")]
	_refresh()


## Which action the cursor is on when it's on the bottom row.
func _action_index() -> int:
	for i in range(ACTION_COLUMNS.size() - 1, -1, -1):
		if _column >= ACTION_COLUMNS[i] - 1:
			return i
	return 0


func _refresh() -> void:
	_name.text = _text + BLANK.repeat(_max_length - _text.length())
	var selected := _row * ROWS[0].length() + _column
	if _row == ROWS.size():
		selected = ROWS.size() * ROWS[0].length() + _action_index()
	for i in _keys.size():
		var key := _keys[i]
		if i == selected:
			key.add_theme_stylebox_override(&"normal", _selected_box)
			key.add_theme_color_override(&"font_color", Color.WHITE)
		else:
			key.remove_theme_stylebox_override(&"normal")
			key.remove_theme_color_override(&"font_color")


func _add_key(parent: Control, text: String, size: Vector2) -> Label:
	var key := Label.new()
	key.text = text
	key.custom_minimum_size = size
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(key)
	return key
