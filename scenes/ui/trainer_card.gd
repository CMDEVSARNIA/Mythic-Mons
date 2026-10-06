class_name TrainerCard
extends Control
## The TRAINER CARD from the start menu: the player's name, money, MONDEX
## count, play time and badge case. Missing badges show as dark outlines.
## Any button closes it.
##
##     await trainer_card.show_card()

signal _closed

const PLAYER_SHEET := preload("res://assets/placeholder/characters/player.png")
const BADGE_DIR := "res://assets/placeholder/items/%s.png"
const MISSING := Color(0.0, 0.0, 0.0, 0.35)

@onready var _portrait: TextureRect = $Card/Layout/Top/Portrait
@onready var _info: Label = $Card/Layout/Top/Info
@onready var _badges: HBoxContainer = $Card/Layout/Badges


func _ready() -> void:
	hide()
	var face := AtlasTexture.new()
	face.atlas = PLAYER_SHEET
	face.region = Rect2(0, 0, Grid.TILE_SIZE, Grid.TILE_SIZE) # Standing, facing down.
	_portrait.texture = face


func show_card() -> void:
	_refresh()
	show()
	await _closed
	hide()


## "H:MM", as on Emerald's card.
static func format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	return "%d:%02d" % [mini(minutes / 60, 999), minutes % 60]


func _refresh() -> void:
	_info.text = "NAME    %s\nMONEY   $%d\nMONDEX  %d\nTIME    %s\nBADGES  %d" % [
		GameState.player_name, GameState.money, GameState.caught.size(),
		format_time(GameState.play_seconds), GameState.badge_count()]
	for child in _badges.get_children():
		child.free()
	for badge: StringName in GameState.BADGES:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = load(BADGE_DIR % badge)
		icon.tooltip_text = GameState.BADGES[badge][0]
		if not GameState.has_flag(badge):
			icon.modulate = MISSING
		_badges.add_child(icon)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"confirm") or event.is_action_pressed(&"cancel") or event.is_action_pressed(&"menu"):
		get_viewport().set_input_as_handled()
		Audio.play_sfx(&"select")
		_closed.emit()
