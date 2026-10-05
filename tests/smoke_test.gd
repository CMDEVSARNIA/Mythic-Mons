extends SceneTree
## Automated walkthrough of the prototype's core mechanics. It plays the real
## game by injecting input events and checks the results.
##
## Logic only (fast, no window):
##   godot --headless --path . --fixed-fps 60 --script res://tests/smoke_test.gd
## With a window it also saves screenshots to user://screenshots/
## (or to the folder in the SCREENSHOT_DIR environment variable):
##   godot --path . --fixed-fps 60 --script res://tests/smoke_test.gd
##
## Exits with code 0 when every check passes, 1 otherwise.

const MAPS := "res://scenes/maps/"

var _failures := 0
var _main: Node
var _player: Node2D # Untyped on purpose: game scripts must compile after the autoloads exist.
var _dialogue: Node # The Dialogue autoload (globals aren't visible to a --script main loop).


func _initialize() -> void:
	change_scene_to_file("res://scenes/main/main.tscn")
	_run.call_deferred()


func _run() -> void:
	await _wait(0.6)
	_main = current_scene
	_player = _main.player
	_dialogue = root.get_node(^"Dialogue")

	# --- Grid movement -------------------------------------------------------
	_check(_map_name() == "EMBERFALL TOWN", "starts in Emberfall")
	_check(_player.get_cell() == Vector2i(5, 5), "starts on the default spawn")
	_shot("01_emberfall")
	await _tap(&"move_left")
	_check(_player.get_cell() == Vector2i(5, 5) and _player.facing == Vector2i.LEFT, "a tap on a new direction only turns")
	await _tap(&"move_left")
	_check(_player.get_cell() == Vector2i(4, 5), "a tap in the facing direction walks one tile")
	await _tap(&"move_up")
	await _tap(&"move_up")
	_check(_player.get_cell() == Vector2i(4, 5), "walls block movement (bump)")
	await _hold(&"move_down", 0.6)
	_check(_player.get_cell().y >= Vector2i(4, 7).y, "holding a direction keeps walking")

	# --- Talking -------------------------------------------------------------
	await _place(Vector2i(8, 8), Vector2i.UP)
	await _tap(&"confirm")
	_check(_dialogue.is_open, "pressing A on a sign opens the text box")
	await _wait(0.8)
	_shot("02_sign")
	await _close_dialogue()
	_check(not _dialogue.is_open and not _player.is_locked(), "the text box closes and control returns")

	var lass: Node2D = _main.current_map.entities.get_node(^"NPC_Lass1")
	lass.wander_radius = 0
	lass.place_at(Vector2i(14, 9), Vector2i.DOWN)
	await _place(Vector2i(13, 9), Vector2i.RIGHT)
	await _tap(&"confirm")
	_check(_dialogue.is_open and lass.facing == Vector2i.LEFT, "NPCs turn to face the player and talk")
	await _close_dialogue()

	# --- CUT -----------------------------------------------------------------
	await _place(Vector2i(4, 9), Vector2i.DOWN)
	await _tap(&"confirm")
	await _wait(1.2)
	_shot("03_cut_prompt")
	await _tap(&"confirm") # YES
	await _wait(1.0)
	_check(_main.current_map.entities.get_node_or_null(^"CutTree1") == null, "CUT removes the tree")
	await _tap(&"move_down")
	_check(_player.get_cell() == Vector2i(4, 10), "the path through the cut tree is open")

	# --- Warps ---------------------------------------------------------------
	await _place(Vector2i(5, 5), Vector2i.UP)
	await _tap(&"move_up")
	await _wait(1.0)
	_check(_map_name() == "YOUR HOUSE" and _player.get_cell() == Vector2i(4, 5), "doors warp into the house")
	_shot("04_house")
	await _tap(&"move_down")
	await _tap(&"move_down")
	await _wait(1.0)
	_check(_map_name() == "EMBERFALL TOWN" and _player.get_cell() == Vector2i(5, 5), "the exit mat warps back outside")

	await _place(Vector2i(9, 1), Vector2i.UP)
	await _tap(&"move_up")
	await _wait(1.0)
	_check(_map_name() == "ROUTE 1" and _player.get_cell() == Vector2i(9, 22), "the town edge leads to Route 1")
	_shot("05_route")

	# --- Ledges --------------------------------------------------------------
	await _place(Vector2i(5, 7), Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(0.6)
	_check(_player.get_cell() == Vector2i(5, 9), "ledges can be hopped down")
	await _tap(&"move_up")
	await _tap(&"move_up")
	_check(_player.get_cell() == Vector2i(5, 9), "ledges block climbing back up")

	# --- ROCK SMASH ----------------------------------------------------------
	await _place(Vector2i(2, 16), Vector2i.UP)
	await _tap(&"confirm")
	await _wait(1.2)
	await _tap(&"confirm") # YES
	await _wait(1.0)
	await _tap(&"move_up")
	_check(_player.get_cell() == Vector2i(2, 15), "ROCK SMASH opens the hidden pocket")

	# --- Wild encounters -----------------------------------------------------
	_main.current_map.encounter_rate = 1.0
	await _place(Vector2i(3, 1), Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(1.6)
	_check(_dialogue.is_open and _main.encounter_preview.visible, "tall grass triggers a wild encounter")
	_shot("06_encounter")
	await _close_dialogue()
	_main.current_map.encounter_rate = 0.0

	# --- SURF ----------------------------------------------------------------
	_main.change_map(MAPS + "town_tidewater.tscn", &"from_route")
	await _wait(1.0)
	_check(_map_name() == "TIDEWATER CITY", "Route 1 connects to Tidewater")
	await _place(Vector2i(5, 6), Vector2i.UP)
	await _tap(&"confirm")
	await _wait(1.6)
	_shot("07_surf_prompt")
	await _tap(&"confirm") # YES
	await _wait(0.6)
	_check(_player.is_surfing and _player.get_cell() == Vector2i(5, 5), "SURF hops onto the water")
	await _tap(&"move_up")
	await _wait(0.3)
	_shot("08_surfing")
	await _tap(&"move_up")
	await _wait(0.6)
	_check(not _player.is_surfing and _player.get_cell() == Vector2i(5, 3), "surfing into land dismounts")

	# --- FLY -----------------------------------------------------------------
	await _place(Vector2i(9, 14), Vector2i.DOWN)
	await _tap(&"menu")
	_check(_main.start_menu.visible, "ENTER opens the start menu")
	await _tap(&"confirm") # FLY
	await _wait(0.2)
	_shot("09_fly_menu")
	await _tap(&"confirm") # First visited town: Emberfall.
	await _wait(1.2)
	_check(_map_name() == "EMBERFALL TOWN" and _player.get_cell() == Vector2i(10, 7), "FLY returns to a visited town")

	print("\nSMOKE TEST %s (%d failed)" % ["PASSED" if _failures == 0 else "FAILED", _failures])
	quit(1 if _failures > 0 else 0)


func _map_name() -> String:
	return _main.current_map.display_name


func _place(cell: Vector2i, dir: Vector2i) -> void:
	_player.place_at(cell, dir)
	await _wait(0.05)


func _tap(action: StringName) -> void:
	await _hold(action, 0.05)
	await _wait(0.35)


func _hold(action: StringName, seconds: float) -> void:
	_send(action, true)
	await _wait(seconds)
	_send(action, false)


func _send(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _close_dialogue() -> void:
	for i in 10:
		if not _dialogue.is_open:
			break
		await _tap(&"confirm")
	await _wait(0.1)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _check(passed: bool, what: String) -> void:
	print("%s  %s" % ["PASS" if passed else "FAIL", what])
	if not passed:
		_failures += 1


func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var dir := OS.get_environment("SCREENSHOT_DIR")
	if dir.is_empty():
		dir = "user://screenshots"
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_png(dir.path_join(shot_name + ".png"))
