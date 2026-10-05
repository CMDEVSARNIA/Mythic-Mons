class_name Warp
extends Area2D
## Step-on trigger that sends the player to another map (doors, map edges).
## The player checks for these when it finishes a step, so a player who spawns
## on a warp isn't bounced straight back.

@export_file("*.tscn") var target_map := ""
## Name of a SpawnPoint in the target map's Spawns node.
@export var target_spawn: StringName = &"default"
## Played on use. Leave empty for seamless map-edge exits.
@export var sfx: StringName = &"door"

@export_group("Story Gate")
## While this GameState flag is unset, the player is stopped and turned back.
@export var required_flag: StringName = &""
@export var blocked_lines := PackedStringArray()


func on_player_entered(player: Player) -> void:
	if not required_flag.is_empty() and not GameState.has_flag(required_flag):
		_turn_back(player)
		return
	if target_map.is_empty():
		push_warning("Warp %s has no target_map." % get_path())
		return
	Audio.play_sfx(sfx)
	Events.warp_requested.emit(target_map, target_spawn)


func _turn_back(player: Player) -> void:
	player.lock()
	await Dialogue.say(blocked_lines)
	var back := -player.facing
	if player.can_step(back):
		player.start_step(back)
	player.unlock()
