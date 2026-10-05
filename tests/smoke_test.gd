extends SceneTree
## Automated walkthrough of the prototype. It plays the real game by injecting
## input events and checks the results, from the first steps through getting
## a starter, battling, catching, the start menu, saving and continuing.
##
## Logic only (fast, no window):
##   godot --headless --path . --fixed-fps 60 --script res://tests/smoke_test.gd
## With a window it also saves screenshots to user://screenshots/
## (or to the folder in the SCREENSHOT_DIR environment variable):
##   godot --path . --fixed-fps 60 --script res://tests/smoke_test.gd
##
## Uses its own save file, so a real save is never read or overwritten.
## Exits with code 0 when every check passes, 1 otherwise.

const MAPS := "res://scenes/maps/"
const MAIN_SCENE := "res://scenes/main/main.tscn"
const TEST_SAVE := "user://smoke_test_save.json"

var _failures := 0
# Game objects stay untyped on purpose: game scripts must compile after the
# autoloads exist, and globals aren't visible to a --script main loop.
var _main: Node
var _player: Node2D
var _dialogue: Node
var _game_state: Node
var _shots_taken := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game_state = root.get_node(^"GameState")
	_game_state.save_path = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	_dialogue = root.get_node(^"Dialogue")
	await _start_game()

	# --- Grid movement -------------------------------------------------------
	_check(_map_name() == "EMBERFALL TOWN", "starts in Emberfall")
	_check(_player.get_cell() == Vector2i(5, 5), "starts on the default spawn")
	_check(_game_state.party.is_empty(), "a new game starts without monsters")
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

	var lass: Node2D = _main.current_map.entities.get_node(^"NPC_Lass2")
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

	# --- Getting a starter ---------------------------------------------------
	await _place(Vector2i(9, 1), Vector2i.UP)
	await _tap(&"move_up")
	_check(_dialogue.is_open, "PROF. ASTER stops you at the edge of town")
	await _close_dialogue()
	await _wait(0.4)
	_check(_map_name() == "EMBERFALL TOWN" and _player.get_cell() == Vector2i(9, 1), "...and turns you back until you have a MONSTER")

	await _place(Vector2i(15, 6), Vector2i.UP)
	await _tap(&"confirm")
	for i in 25: # Every A press takes the first option: FLAMLET, then YES.
		if _game_state.has_flag(&"got_starter") and not _dialogue.is_open:
			break
		if _dialogue.get_node(^"Picture").visible:
			_shot_once("05_starter")
		await _tap(&"confirm")
	_check(_game_state.party.size() == 1 and _game_state.party[0].species.display_name == "FLAMLET", "PROF. ASTER gives you a starter")
	_check(_game_state.bag.get(&"mon_orb", 0) == 5, "...along with 5 MON ORBs")

	await _place(Vector2i(9, 1), Vector2i.UP)
	await _tap(&"move_up")
	await _wait(1.0)
	_check(_map_name() == "ROUTE 1" and _player.get_cell() == Vector2i(9, 22), "with a MONSTER, the town edge leads to Route 1")
	_shot("06_route")

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

	# --- Wild battles --------------------------------------------------------
	var route: Node2D = _main.current_map
	route.encounter_rate = 1.0
	route.wild_monsters.assign([&"sproutle"])
	route.wild_levels = Vector2i(2, 2)
	await _place(Vector2i(3, 1), Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(2.5)
	_check(_battle_scene() != null, "tall grass starts a wild battle")
	_shot("07_battle_intro")
	await _press_through_battle()
	_check(_battle_scene() == null and _map_name() == "ROUTE 1" and not _player.is_locked(), "winning a battle returns to the overworld")
	var lead: Resource = _game_state.party[0]
	_check(lead.experience > 125, "the winner earns EXP")

	# --- Catching ------------------------------------------------------------
	_game_state.bag.assign({&"master_orb": 1})
	await _place(Vector2i(3, 1), Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(2.5)
	await _until_action_menu()
	await _tap(&"move_right") # FIGHT -> BAG
	await _tap(&"confirm")
	_shot_once("10_battle_bag")
	await _tap(&"confirm") # MASTER ORB
	await _wait(3.2) # Message, throw and landing; the orb is now shaking.
	_shot_once("11_catch")
	await _press_through_battle()
	_check(_game_state.party.size() == 2 and _game_state.party[1].species.display_name == "SPROUTLE", "a caught monster joins the party")
	_check(not _game_state.bag.has(&"master_orb"), "throwing an orb uses it up")

	# --- Losing --------------------------------------------------------------
	_game_state.party[1].hp = 0 # Only the lead can fight, so losing it ends the battle.
	lead.hp = 1
	route.wild_monsters.assign([&"zapkit"])
	route.wild_levels = Vector2i(30, 30)
	await _place(Vector2i(3, 1), Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(2.5)
	await _press_through_battle()
	await _close_dialogue()
	_check(_map_name() == "YOUR HOUSE" and lead.hp == lead.max_hp() and _game_state.party[1].hp > 0, "losing whites out at home with the party healed")
	_check(not _player.is_locked(), "control returns after whiting out")

	lead.hp = 3
	var mom: Node2D = _main.current_map.entities.get_node(^"NPC_Mom1")
	mom.wander_radius = 0
	mom.place_at(Vector2i(6, 3), Vector2i.DOWN)
	await _place(Vector2i(6, 4), Vector2i.UP)
	await _tap(&"confirm")
	await _close_dialogue()
	_check(lead.hp == lead.max_hp(), "MOM heals your MONSTERS")

	# --- Start menu: party, summary, BAG, save -------------------------------
	var party_menu: Control = _main.party_menu
	await _tap(&"menu")
	await _tap(&"confirm") # MONSTERS
	_check(party_menu.visible, "MONSTERS opens the party screen")
	_shot_once("12_party")
	await _tap(&"confirm") # FLAMLET -> SUMMARY / SWITCH / CANCEL
	await _tap(&"confirm") # SUMMARY
	_check(party_menu.get_node(^"Summary").visible, "SUMMARY shows a monster's details")
	_shot_once("13_summary")
	await _tap(&"move_right")
	_shot_once("14_summary_skills")
	await _tap(&"cancel")
	await _tap(&"confirm") # FLAMLET -> actions
	await _tap(&"move_down")
	await _tap(&"confirm") # SWITCH
	await _tap(&"move_down")
	await _tap(&"confirm") # ...with the second slot
	_check(_game_state.party[0].species.display_name == "SPROUTLE", "SWITCH reorders the party")
	await _tap(&"cancel") # Close the party screen,
	await _tap(&"cancel") # then the start menu.
	_check(not party_menu.visible and not _player.is_locked(), "closing the menus returns control")

	_game_state.bag.assign({&"potion": 1})
	var hurt: Resource = _game_state.party[0]
	hurt.hp = 1
	await _tap(&"menu")
	await _tap(&"move_down") # BAG
	await _tap(&"confirm")
	_shot_once("15_bag")
	await _tap(&"confirm") # POTION
	await _tap(&"confirm") # On the first party member.
	await _close_dialogue()
	_check(hurt.hp == mini(21, hurt.max_hp()) and not _game_state.bag.has(&"potion"), "POTIONs work from the BAG")
	await _tap(&"cancel")

	await _tap(&"menu")
	for i in 3: # MONSTERS, BAG, FLY, SAVE
		await _tap(&"move_down")
	await _tap(&"confirm")
	for i in 6: # Finish the question, then YES.
		if FileAccess.file_exists(TEST_SAVE):
			break
		await _tap(&"confirm")
	await _close_dialogue()
	await _tap(&"cancel")
	_check(FileAccess.file_exists(TEST_SAVE), "SAVE writes the game to disk")
	var saved_map := _map_name()
	var saved_cell: Vector2i = _player.get_cell()

	# --- Continue ------------------------------------------------------------
	await _start_game()
	_check(_main.title_screen.visible, "with a save, the game opens on the title screen")
	_shot_once("16_title")
	await _tap(&"confirm") # CONTINUE
	await _wait(0.6)
	_check(_map_name() == saved_map and _player.get_cell() == saved_cell, "CONTINUE resumes where you saved")
	_check(_game_state.party.size() == 2 and _game_state.party[0].species.display_name == "SPROUTLE", "...with your party as you left it")

	# --- SURF ----------------------------------------------------------------
	_main.change_map(MAPS + "town_tidewater.tscn", &"from_route")
	await _wait(1.0)
	_check(_map_name() == "TIDEWATER CITY", "Route 1 connects to Tidewater")
	await _place(Vector2i(5, 6), Vector2i.UP)
	await _tap(&"confirm")
	await _wait(1.6)
	_shot("17_surf_prompt")
	await _tap(&"confirm") # YES
	await _wait(0.6)
	_check(_player.is_surfing and _player.get_cell() == Vector2i(5, 5), "SURF hops onto the water")
	await _tap(&"move_up")
	await _wait(0.3)
	_shot("18_surfing")
	await _tap(&"move_up")
	await _wait(0.6)
	_check(not _player.is_surfing and _player.get_cell() == Vector2i(5, 3), "surfing into land dismounts")

	# --- FLY -----------------------------------------------------------------
	await _place(Vector2i(9, 14), Vector2i.DOWN)
	await _tap(&"menu")
	_check(_main.start_menu.visible, "ENTER opens the start menu")
	await _tap(&"move_down")
	await _tap(&"move_down")
	await _tap(&"confirm") # FLY
	await _wait(0.2)
	_shot("19_fly_menu")
	await _tap(&"confirm") # First visited town: Emberfall.
	await _wait(1.2)
	_check(_map_name() == "EMBERFALL TOWN" and _player.get_cell() == Vector2i(10, 7), "FLY returns to a visited town")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("\nSMOKE TEST %s (%d failed)" % ["PASSED" if _failures == 0 else "FAILED", _failures])
	quit(1 if _failures > 0 else 0)


## (Re)starts the main scene and waits for it to be ready.
func _start_game() -> void:
	change_scene_to_file(MAIN_SCENE)
	await _wait(0.6)
	_main = current_scene
	_player = _main.player


## Presses A until the battle is over, taking screenshots of the menus.
func _press_through_battle() -> void:
	for i in 150:
		var battle: Control = _battle_scene()
		if battle == null:
			break
		if battle.get_node(^"Menus/ActionArea/ActionMenu").visible:
			_shot_once("08_battle_menu")
		elif battle.get_node(^"Menus/MoveArea/MoveMenu").visible:
			_shot_once("09_battle_moves")
		await _tap(&"confirm")
	await _wait(1.0)


## Presses A through the intro until FIGHT/BAG/MON/RUN is showing.
func _until_action_menu() -> void:
	for i in 40:
		var battle: Control = _battle_scene()
		if battle == null or battle.get_node(^"Menus/ActionArea/ActionMenu").visible:
			return
		await _tap(&"confirm")


func _battle_scene() -> Control:
	var layer: CanvasLayer = _main.battle_layer
	for child in layer.get_children():
		if not child.is_queued_for_deletion():
			return child
	return null


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


func _shot_once(shot_name: String) -> void:
	if not _shots_taken.has(shot_name):
		_shots_taken[shot_name] = true
		_shot(shot_name)


func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var dir := OS.get_environment("SCREENSHOT_DIR")
	if dir.is_empty():
		dir = "user://screenshots"
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_png(dir.path_join(shot_name + ".png"))
