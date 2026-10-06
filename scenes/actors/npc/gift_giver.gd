class_name GiftGiver
extends NPC
## An NPC who hands over `count` of an item the first time you talk, then just
## says `lines`. `flag` (named by tools/build_world.gd) remembers the gift.

@export var gift: StringName = &"potion"
@export_range(1, 99) var count := 1
@export var flag: StringName
## Said before handing the gift over.
@export var offer: PackedStringArray = []


func _talk() -> void:
	var item := GameData.item(gift)
	if item == null or GameState.has_flag(flag):
		await Dialogue.say(lines)
		return
	await Dialogue.say(offer)
	GameState.add_item(gift, count)
	GameState.set_flag(flag)
	Audio.play_sfx(&"level_up")
	var what := item.display_name if count == 1 else "%d %ss" % [count, item.display_name]
	await Dialogue.say(["%s received\n%s!" % [GameState.player_name, what]])
	await Dialogue.say(lines)
