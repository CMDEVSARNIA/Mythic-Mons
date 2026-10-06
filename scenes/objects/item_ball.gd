class_name ItemBall
extends StaticBody2D
## An orb lying on the ground with an item inside, like Emerald's item balls.
## Pressing A picks it up ("KAI found a SUPER ORB!") and it's gone for good:
## `flag` is set, and a ball whose flag is already set frees itself on load.
## tools/build_world.gd names the flag after the map and cell.

@export var item: StringName = &"potion"
@export_range(1, 99) var count := 1
@export var flag: StringName


func _ready() -> void:
	if not flag.is_empty() and GameState.has_flag(flag):
		queue_free()


func interact(_player: GridActor) -> void:
	var data := GameData.item(item)
	if data == null:
		return
	GameState.add_item(item, count)
	if not flag.is_empty():
		GameState.set_flag(flag)
	Audio.play_sfx(&"level_up")
	hide()
	var what := data.display_name if count == 1 else "%d %ss" % [count, data.display_name]
	await Dialogue.say(["%s found\n%s!" % [GameState.player_name, what],
		"%s put the %s\nin the BAG." % [GameState.player_name, data.display_name]])
	queue_free()
