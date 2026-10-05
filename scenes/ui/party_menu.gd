class_name PartyMenu
extends Control
## Full-screen party view: the party on the left, a big picture of the
## highlighted monster on the right.
##
##     await party_menu.browse()   # SUMMARY / SWITCH (reorder) until B
##     var index: int = await party_menu.pick("Use on which MONSTER?")  # -1 = cancelled

signal _closed(index: int)

enum Mode { BROWSE, PICK }

const BROWSE_HINT := "Choose a MONSTER."

var _mode := Mode.BROWSE
var _index := 0
## Party slot being moved, or -1. Set by SWITCH, cleared by the second pick.
var _moving := -1
## True while a submenu or the summary has the input.
var _busy := false
var _hint_text := ""

@onready var _rows: VBoxContainer = $List/Rows
@onready var _art: TextureRect = $Preview/Info/Art
@onready var _details: Label = $Preview/Info/Details
@onready var _hint: Label = $Hint/Label
@onready var _actions: ChoiceBox = $ActionArea/Actions
@onready var _summary: MonsterSummary = $Summary


func _ready() -> void:
	hide()


func browse() -> void:
	_mode = Mode.BROWSE
	await _open(BROWSE_HINT)


func pick(hint: String) -> int:
	_mode = Mode.PICK
	return await _open(hint)


func _open(hint: String) -> int:
	_index = 0
	_moving = -1
	_hint_text = hint
	_rebuild()
	show()
	var result: int = await _closed
	hide()
	return result


func _input(event: InputEvent) -> void:
	if not visible or _busy:
		return
	if event.is_action_pressed(&"move_up", true):
		_move(-1)
	elif event.is_action_pressed(&"move_down", true):
		_move(1)
	elif event.is_action_pressed(&"confirm"):
		Audio.play_sfx(&"select")
		_select()
	elif event.is_action_pressed(&"cancel"):
		Audio.play_sfx(&"select")
		if _moving >= 0:
			_moving = -1
			_refresh()
		else:
			_closed.emit(-1)
	else:
		return
	get_viewport().set_input_as_handled()


func _move(step: int) -> void:
	_index = wrapi(_index + step, 0, GameState.party.size())
	_refresh()


func _select() -> void:
	if _mode == Mode.PICK:
		_closed.emit(_index)
		return
	if _moving >= 0:
		var party := GameState.party
		var moved := party[_moving]
		party[_moving] = party[_index]
		party[_index] = moved
		_moving = -1
		_rebuild()
		return
	_busy = true
	var choice: int = await _actions.choose(["SUMMARY", "SWITCH", "CANCEL"])
	match choice:
		0:
			_index = await _summary.view(GameState.party, _index)
		1:
			_moving = _index
	_busy = false
	_refresh()


func _rebuild() -> void:
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.free()
	for monster in GameState.party:
		var row := VBoxContainer.new()
		row.add_theme_constant_override(&"separation", 2)
		row.add_child(Label.new())
		var bar_margin := MarginContainer.new()
		bar_margin.add_theme_constant_override(&"margin_left", 16)
		var bar := StatBar.new()
		bar.custom_minimum_size = Vector2(0, 4)
		bar.ratio = float(monster.hp) / monster.max_hp()
		bar_margin.add_child(bar)
		row.add_child(bar_margin)
		_rows.add_child(row)
	_index = clampi(_index, 0, maxi(GameState.party.size() - 1, 0))
	_refresh()


func _refresh() -> void:
	var party := GameState.party
	for i in party.size():
		var label: Label = _rows.get_child(i).get_child(0)
		var marker := "▶" if i == _index else ("*" if i == _moving else " ")
		label.text = "%s %-9s Lv%d" % [marker, party[i].get_display_name(), party[i].level]
	if party.is_empty():
		return
	var monster := party[_index]
	_art.texture = monster.species.front_texture
	var status := "FAINTED" if monster.is_fainted() else monster.species.element.to_upper()
	_details.text = "%d/%d\n%s" % [monster.hp, monster.max_hp(), status]
	_hint.text = "Move to where?" if _moving >= 0 else _hint_text
