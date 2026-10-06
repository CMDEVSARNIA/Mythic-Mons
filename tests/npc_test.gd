extends SceneTree
## Talks to every NPC and reads every sign on every map, the way a player
## would: standing on a neighboring cell the player can actually get to from
## the map's entrance, or across a counter. Fails for anyone who can't be
## reached or doesn't answer. Trainers count as already beaten, so they chat
## instead of battling. Also examines a bookshelf.
##
##   godot --headless --path . --fixed-fps 60 --script res://tests/npc_test.gd
##
## Uses its own save file, so a real save is never read or overwritten.
## Exits with code 0 when every check passes, 1 otherwise.

const MAPS := "res://scenes/maps/"
const MAIN_SCENE := "res://scenes/main/main.tscn"
const TEST_SAVE := "user://npc_test_save.json"

var _failures := 0
var _talked := 0
# Untyped on purpose; see smoke_test.gd.
var _main: Node
var _player: Node2D
var _dialogue: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_state: Node = root.get_node(^"GameState")
	game_state.save_path = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	_dialogue = root.get_node(^"Dialogue")
	game_state.set_flag(game_state.INTRO_FLAG) # Skip the new-game intro.
	change_scene_to_file(MAIN_SCENE)
	await _wait(0.6)
	_main = current_scene
	_player = _main.player
	# After the intro, so PROF. ASTER chats instead of offering starters.
	game_state.add_monster(Monster.create(GameData.species(&"flamlet"), 5))
	game_state.set_flag(&"got_starter")
	for trainer_file in DirAccess.get_files_at("res://data/trainers/"):
		if trainer_file.ends_with(".tres"):
			game_state.set_flag(StringName("beat_" + trainer_file.get_basename()))

	var files := Array(DirAccess.get_files_at(MAPS)).filter(func(f: String) -> bool: return f.ends_with(".tscn"))
	files.sort()
	for file: String in files:
		_main.change_map(MAPS + file, &"default")
		await _wait(1.0)
		await _talk_to_everyone(file.get_basename())

	# Furniture can be examined too.
	_main.change_map(MAPS + "house_emberfall.tscn", &"default")
	await _wait(1.0)
	await _place(Vector2i(2, 1), Vector2i.UP)
	await _tap(&"confirm")
	await _wait(0.2)
	_check(_dialogue.is_open, "house_emberfall: the bookshelf can be examined")
	await _dismiss()

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("\nNPC TEST %s (%d NPCs and signs, %d failed)" % ["PASSED" if _failures == 0 else "FAILED", _talked, _failures])
	quit(1 if _failures > 0 else 0)


func _talk_to_everyone(map_name: String) -> void:
	var map: Node = _main.current_map
	var talkers: Array[Node] = []
	for entity in map.entities.get_children():
		# NPCs and signs (not field obstacles, and not the player) have lines.
		if entity != _player and entity.get(&"lines") != null:
			talkers.append(entity)
		if entity.get(&"wander_radius") != null:
			entity.wander_radius = 0
	await _wait(0.4) # Let anyone mid-step finish.
	var reachable := _reachable_cells(map)
	for talker in talkers:
		var what := "%s: %s" % [map_name, talker.name]
		var spot := _spot_to_talk(map, Grid.world_to_cell(talker.position), reachable)
		if spot.is_empty():
			_check(false, "%s can be reached" % what)
			continue
		await _place(spot.cell, spot.facing)
		await _tap(&"confirm")
		await _wait(0.2)
		var answered: bool = _dialogue.is_open
		await _dismiss()
		_talked += 1
		_check(answered and not _player.is_locked(), "%s answers" % what)


## Cells the player can get to from where it arrived. Field moves count:
## CUT trees and boulders can be cleared and water can be surfed. Warps
## aren't walked through.
func _reachable_cells(map: Node) -> Dictionary:
	var start: Vector2i = _player.get_cell()
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for dir in Grid.DIRECTIONS:
			var next: Vector2i = cell + dir
			if seen.has(next) or not map.is_in_bounds(next):
				continue
			if not _player.query_cell(next, PhysicsLayers.WORLD).is_empty():
				continue
			seen[next] = true
			if _player.query_cell(next, PhysicsLayers.TRIGGERS, true).is_empty():
				queue.append(next)
	return seen


## Where to stand to talk to whoever is on `target`: a free, reachable land
## cell next to it, or across a counter. {} if there's none.
func _spot_to_talk(map: Node, target: Vector2i, reachable: Dictionary) -> Dictionary:
	for reach in [1, 2]:
		for dir in Grid.DIRECTIONS:
			var cell: Vector2i = target + dir * reach
			if reach == 2 and map.get_terrain(target + dir) != &"counter":
				continue
			if reachable.has(cell) and map.get_terrain(cell) != &"water" and _is_free(cell):
				return {"cell": cell, "facing": -dir}
	return {}


func _is_free(cell: Vector2i) -> bool:
	for body in _player.query_cell(cell, PhysicsLayers.ACTORS | PhysicsLayers.OBSTACLES | PhysicsLayers.TRIGGERS, true):
		if body != _player:
			return false
	return true


## Presses B until the conversation (and any menu it opened) is over.
func _dismiss() -> void:
	for i in 20:
		if not _dialogue.is_open and not _player.is_locked():
			return
		await _tap(&"cancel")


func _place(cell: Vector2i, dir: Vector2i) -> void:
	_player.place_at(cell, dir)
	await _wait(0.05)


func _tap(action: StringName) -> void:
	_send(action, true)
	await _wait(0.05)
	_send(action, false)
	await _wait(0.3)


func _send(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _check(passed: bool, what: String) -> void:
	print("%s  %s" % ["PASS" if passed else "FAIL", what])
	if not passed:
		_failures += 1
