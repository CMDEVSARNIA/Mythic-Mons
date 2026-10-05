class_name MonsterSummary
extends Control
## Two-page summary of one monster: INFO (picture, level, EXP, ability) and
## SKILLS (stats and moves). Left/right flips pages, up/down steps through the
## party, A or B closes.
##
##     var last_index: int = await summary.view(GameState.party, index)

signal _closed

const PAGES := ["INFO", "SKILLS"]

var _party: Array[Monster] = []
var _index := 0
var _page := 0

@onready var _art: TextureRect = $Art
@onready var _orb: TextureRect = $Orb
@onready var _header: Label = $Header
@onready var _info: Label = $InfoText
@onready var _skills: Label = $SkillsText
@onready var _footer: Label = $Footer


func _ready() -> void:
	hide()


## Shows the summary and returns the index of the monster last viewed.
func view(party: Array[Monster], index: int) -> int:
	_party = party
	_index = index
	_page = 0
	_refresh()
	show()
	await _closed
	hide()
	return _index


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"move_left", true) or event.is_action_pressed(&"move_right", true):
		_page = 1 - _page
	elif event.is_action_pressed(&"move_up", true):
		_index = wrapi(_index - 1, 0, _party.size())
	elif event.is_action_pressed(&"move_down", true):
		_index = wrapi(_index + 1, 0, _party.size())
	elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"cancel"):
		Audio.play_sfx(&"select")
		get_viewport().set_input_as_handled()
		_closed.emit()
		return
	else:
		return
	get_viewport().set_input_as_handled()
	_refresh()


func _refresh() -> void:
	var monster := _party[_index]
	var species := monster.species
	_art.texture = species.front_texture
	var orb := GameData.item(monster.orb)
	_orb.texture = orb.icon if orb else null
	_header.text = "%s\nLv%d  %s\nHP %d/%d\n%s nature" % [monster.get_display_name(), monster.level,
		species.element.to_upper(), monster.hp, monster.max_hp(), monster.nature]
	var next := "MAX" if monster.level >= Monster.MAX_LEVEL else str(monster.exp_to_next_level())
	var ability := species.ability
	_info.text = "EXP %d\nNEXT LV %s EXP\nABILITY: %s\n%s" % [monster.experience, next,
		ability.display_name if ability else "NONE", ability.description if ability else ""]
	var lines := PackedStringArray()
	for stat: StringName in [&"attack", &"defense", &"special", &"speed"]:
		# The nature's raised stat gets a +, its lowered one a -.
		var mark: String = ["-", " ", "+"][monster.nature_effect(stat) + 1]
		lines.append("%-8s%s%3d" % [Battle.STAT_NAMES[stat], mark, monster.stat(stat)])
	lines.append("")
	for i in monster.moves.size():
		var move := monster.moves[i]
		lines.append("%-10s %2d/%2d %s" % [move.display_name, monster.pp[i], move.max_pp, move.element.to_upper()])
	_skills.text = "\n".join(lines)
	_info.visible = _page == 0
	_skills.visible = _page == 1
	_art.visible = _page == 0
	_orb.visible = _page == 0
	_header.visible = _page == 0
	_footer.text = "%s %d/%d   <> PAGE  B BACK" % [PAGES[_page], _page + 1, PAGES.size()]
