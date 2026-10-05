class_name BattlerPanel
extends PanelContainer
## Name, level and HP bar for one side of a battle. The player's panel also
## shows HP numbers and the EXP bar (`show_details`).

@export var show_details := false

var _monster: Monster
## The HP currently drawn; tweened so the bar and numbers count down together.
var _shown_hp := 0.0:
	set(value):
		_shown_hp = value
		_refresh_hp()

@onready var _name: Label = $Rows/Header/Name
@onready var _level: Label = $Rows/Header/Level
@onready var _hp_bar: StatBar = $Rows/HpRow/HpBar
@onready var _hp_text: Label = $Rows/HpText
@onready var _exp_bar: StatBar = $Rows/ExpBar


func _ready() -> void:
	_hp_text.visible = show_details
	_exp_bar.visible = show_details


## Shows `monster` immediately (no animation).
func show_monster(monster: Monster) -> void:
	_monster = monster
	_name.text = monster.get_display_name()
	_level.text = "Lv%d" % monster.level
	_shown_hp = monster.hp
	_exp_bar.ratio = monster.exp_progress()


func animate_hp(target_hp: int) -> void:
	var change := absf(target_hp - _shown_hp) / maxf(_monster.max_hp(), 1.0)
	var tween := create_tween()
	tween.tween_property(self, "_shown_hp", float(target_hp), clampf(change * 1.2, 0.15, 0.8))
	await tween.finished


func animate_exp() -> void:
	var tween := create_tween()
	tween.tween_property(_exp_bar, "ratio", _monster.exp_progress(), 0.5)
	await tween.finished


func _refresh_hp() -> void:
	if _monster == null or not is_node_ready():
		return
	var max_hp := _monster.max_hp()
	_hp_bar.ratio = _shown_hp / max_hp
	_hp_text.text = "%3d/%3d" % [roundi(_shown_hp), max_hp]
