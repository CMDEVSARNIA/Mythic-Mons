class_name DexMenu
extends Control
## The MONDEX: every species in number order, with what the player has seen
## and caught (GameState.seen / GameState.caught). Up/down picks an entry,
## A opens its page, B goes back.
##
##     await dex_menu.browse()

signal _closed

const VISIBLE_ROWS := 8
const UNKNOWN := "----------"

var _species: Array[MonsterSpecies] = []
var _index := 0
var _top := 0
var _on_page := false

@onready var _header: Label = $Header/Label
@onready var _rows: VBoxContainer = $List/Rows
@onready var _art: TextureRect = $Preview/Info/Art
@onready var _details: Label = $Preview/Info/Details
@onready var _page: Control = $Page
@onready var _page_art: TextureRect = $Page/Layout/Top/Art
@onready var _page_title: Label = $Page/Layout/Top/Title
@onready var _page_text: Label = $Page/Layout/Text


func _ready() -> void:
	hide()


func browse() -> void:
	_species = GameData.all_species()
	_index = 0
	_top = 0
	_on_page = false
	_page.hide()
	_refresh()
	show()
	await _closed
	hide()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"move_up", true):
		_move(-1)
	elif event.is_action_pressed(&"move_down", true):
		_move(1)
	elif event.is_action_pressed(&"confirm"):
		Audio.play_sfx(&"select")
		if not _on_page and _is_seen(_index):
			_on_page = true
			_refresh()
		elif _on_page:
			_on_page = false
			_refresh()
	elif event.is_action_pressed(&"cancel"):
		Audio.play_sfx(&"select")
		if _on_page:
			_on_page = false
			_refresh()
		else:
			_closed.emit()
	else:
		return
	get_viewport().set_input_as_handled()


## On the list, moves the cursor; on a page, flips to the next seen entry.
func _move(step: int) -> void:
	var index := _index
	for i in _species.size():
		index = wrapi(index + step, 0, _species.size())
		if not _on_page or _is_seen(index):
			break
	_index = index
	_top = clampi(_top, _index - VISIBLE_ROWS + 1, _index)
	_refresh()


func _refresh() -> void:
	_header.text = "MONDEX   SEEN %3d   OWN %3d" % [GameState.seen.size(), GameState.caught.size()]
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	var orb := GameData.item(&"mon_orb").icon
	for i in range(_top, mini(_top + VISIBLE_ROWS, _species.size())):
		var row := HBoxContainer.new()
		var cursor := Label.new()
		cursor.text = ChoiceBox.CURSOR if i == _index else " "
		row.add_child(cursor)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(8, 8)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = orb if _is_caught(i) else null
		row.add_child(icon)
		var label := Label.new()
		label.text = "%03d %s" % [_species[i].dex_number, _species[i].display_name if _is_seen(i) else UNKNOWN]
		row.add_child(label)
		_rows.add_child(row)

	var species := _species[_index]
	_art.texture = species.front_texture if _is_seen(_index) else null
	if not _is_seen(_index):
		_details.text = "No.%03d\n?????" % species.dex_number
	else:
		_details.text = "No.%03d\n%s" % [species.dex_number, "CAUGHT" if _is_caught(_index) else "SEEN"]

	_page.visible = _on_page
	if _on_page:
		_page_art.texture = species.front_texture
		if _is_caught(_index):
			_page_title.text = "No.%03d\n%s\n%s\n%s\nHT %.1fm WT %.1fkg" % [species.dex_number, species.display_name,
				species.category, species.element.to_upper(), species.height, species.weight]
			_page_text.text = species.dex_entry
		else:
			_page_title.text = "No.%03d\n%s\n???\n???\nHT ??? WT ???" % [species.dex_number, species.display_name]
			_page_text.text = "Catch one to learn more about it."


func _id(index: int) -> StringName:
	return GameData.id_of(_species[index])


func _is_seen(index: int) -> bool:
	return GameState.seen.has(_id(index))


func _is_caught(index: int) -> bool:
	return GameState.caught.has(_id(index))
