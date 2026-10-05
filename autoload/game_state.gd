extends Node
## Save-worthy data that outlives any single map (autoload "GameState").

## Field moves that change how the player can traverse the world.
const FIELD_MOVES: Array[StringName] = [&"cut", &"rock_smash", &"surf", &"fly"]

var player_name := "KAI"
## Until the party and badge systems exist every field move is unlocked so each
## traversal mechanic can be tested. Later: derive this from the party's moves.
var unlocked_field_moves: Array[StringName] = FIELD_MOVES.duplicate()
## Fly destinations: town map scene path -> display name, in visit order.
var visited_towns: Dictionary[String, String] = {}
var current_map_path := ""
## Story/progress switches, e.g. flags[&"got_starter"] = true.
var flags: Dictionary[StringName, bool] = {}


func can_use_field_move(move: StringName) -> bool:
	return move in unlocked_field_moves


func mark_town_visited(map_path: String, display_name: String) -> void:
	visited_towns[map_path] = display_name
