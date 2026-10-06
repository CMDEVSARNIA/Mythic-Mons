extends SceneTree
## Automated walkthrough of the prototype. It plays the real game by injecting
## input events and checks the results, from naming the player and the first
## steps through getting a starter, battling, catching, evolving, trainers, the start menu, saving,
## continuing and the first GYM.
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
var _naming: CanvasLayer
var _choices: Control
var _shots_taken := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game_state = root.get_node(^"GameState")
	_game_state.save_path = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	_dialogue = root.get_node(^"Dialogue")
	_naming = root.get_node(^"NameEntry")
	_choices = _dialogue.get_node(^"ChoiceArea/Choices")
	await _start_game()

	# --- New game: PROF. ASTER asks your name ----------------------------------
	for i in 30:
		if _naming.is_open:
			break
		await _tap(&"confirm")
	_check(_naming.is_open, "a new game asks for your name")
	await _tap(&"move_down")
	await _tap(&"confirm") # K
	await _tap(&"move_up")
	await _tap(&"confirm") # A
	await _tap(&"move_left") # Wraps around to J...
	await _tap(&"move_left")
	await _tap(&"confirm") # ...then I.
	_shot("00_name_entry")
	await _tap(&"menu") # START jumps to OK.
	await _tap(&"confirm")
	await _close_dialogue()
	await _wait(0.8)
	_check(_game_state.player_name == "KAI" and not _naming.is_open, "...and the name you type is yours")

	# --- Grid movement -------------------------------------------------------
	_check(_map_name() == "EMBERFALL TOWN", "starts in Emberfall")
	_check(_player.get_cell() == Vector2i(5, 7), "starts on the default spawn")
	_check(_game_state.party.is_empty(), "a new game starts without monsters")
	_shot("01_emberfall")
	await _tap(&"move_left")
	_check(_player.get_cell() == Vector2i(5, 7) and _player.facing == Vector2i.LEFT, "a tap on a new direction only turns")
	await _tap(&"move_left")
	_check(_player.get_cell() == Vector2i(4, 7), "a tap in the facing direction walks one tile")
	await _tap(&"move_up")
	await _tap(&"move_up")
	_check(_player.get_cell() == Vector2i(4, 7), "houses block movement (bump)")
	await _hold(&"move_down", 0.6)
	_check(_player.get_cell().y >= 9, "holding a direction keeps walking")

	# --- Talking -------------------------------------------------------------
	await _place(Vector2i(9, 8), Vector2i.UP)
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
	await _place(Vector2i(4, 12), Vector2i.DOWN)
	await _tap(&"confirm")
	await _wait(1.2)
	_shot("03_cut_prompt")
	await _tap(&"confirm") # YES
	await _wait(1.0)
	_check(_main.current_map.entities.get_node_or_null(^"CutTree1") == null, "CUT removes the tree")
	await _tap(&"move_down")
	_check(_player.get_cell() == Vector2i(4, 13), "the path through the cut tree is open")

	# --- Warps ---------------------------------------------------------------
	await _place(Vector2i(5, 7), Vector2i.UP)
	await _tap(&"move_up")
	await _wait(1.0)
	_check(_map_name() == "YOUR HOUSE" and _player.get_cell() == Vector2i(4, 5), "doors warp into the house")
	_shot("04_house")
	await _tap(&"move_down")
	await _tap(&"move_down")
	await _wait(1.0)
	_check(_map_name() == "EMBERFALL TOWN" and _player.get_cell() == Vector2i(5, 7), "the exit mat warps back outside")
	await _visit(Vector2i(17, 14), "REN's HOUSE", Vector2i(17, 14))

	# --- Getting a starter ---------------------------------------------------
	await _place(Vector2i(11, 1), Vector2i.UP)
	await _tap(&"move_up")
	_check(_dialogue.is_open, "PROF. ASTER stops you at the edge of town")
	await _close_dialogue()
	await _wait(0.4)
	_check(_map_name() == "EMBERFALL TOWN" and _player.get_cell() == Vector2i(11, 1), "...and turns you back until you have a MONSTER")

	await _place(Vector2i(18, 7), Vector2i.UP)
	await _tap(&"move_up")
	await _wait(1.0)
	_check(_map_name() == "MONSTER LAB", "the lab door leads inside")
	await _place(Vector2i(5, 3), Vector2i.UP)
	await _tap(&"confirm")
	for i in 30: # Every A press takes the first option: FLAMLET, then YES, but no nickname.
		if _game_state.has_flag(&"got_starter") and not _dialogue.is_open and not _naming.is_open:
			break
		if _dialogue.get_node(^"Picture").visible:
			_shot_once("05_starter")
		if _choices.visible and "nickname" in _dialogue.get_node(^"Box/Text").text:
			await _tap(&"move_down") # NO
		await _tap(&"confirm")
	_check(_game_state.party.size() == 1 and _game_state.party[0].species.display_name == "FLAMLET", "PROF. ASTER gives you a starter")
	_check(_game_state.party[0].get_display_name() == "FLAMLET", "...and saying NO to a nickname keeps its name")
	_check(_game_state.bag.get(&"mon_orb", 0) == 5, "...along with 5 MON ORBs")
	await _place(Vector2i(5, 6), Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(1.0)
	_check(_map_name() == "EMBERFALL TOWN" and _player.get_cell() == Vector2i(18, 7), "the lab mat leads back outside")

	await _place(Vector2i(11, 1), Vector2i.UP)
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

	# --- Wild battles and evolution ------------------------------------------
	# FLAMLET is one EXP point short of level 12, where it evolves.
	var lead: Resource = _game_state.party[0]
	lead.level = 11
	lead.experience = lead.exp_for_level(12) - 1
	lead.hp = lead.max_hp()
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
	_check(lead.level == 12, "the winner earns EXP and levels up")
	_check(await _until_evolution_text(), "reaching level 12 after a battle starts FLAMLET's evolution")
	_shot("24_evolution_start")
	await _close_dialogue() # "What? FLAMLET is evolving!"
	await _wait(0.6)
	_shot("25_evolution_flash")
	await _hold(&"cancel", 0.5)
	_check(_dialogue.is_open and lead.species.display_name == "FLAMLET", "holding B stops the evolution")
	await _press_through_evolutions()
	_check(not _game_state.seen.has(&"blazard"), "...without registering BLAZARD")
	_check(_battle_scene() == null and _map_name() == "ROUTE 1" and not _player.is_locked(), "the battle returns to the overworld")

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
	await _until_choices(_choices)
	_check("nickname" in _dialogue.get_node(^"Box/Text").text, "a catch offers a nickname")
	await _tap(&"confirm") # YES
	_check(_naming.is_open, "...on the naming screen")
	await _tap(&"move_right")
	await _tap(&"confirm") # B
	await _tap(&"move_down")
	for i in 3:
		await _tap(&"move_right")
	await _tap(&"confirm") # O
	_shot("11_nickname")
	await _tap(&"menu")
	await _tap(&"confirm") # OK
	await _press_through_battle()
	_check(_game_state.party.size() == 2 and _game_state.party[1].species.display_name == "SPROUTLE", "a caught monster joins the party")
	_check(_game_state.party[1].get_display_name() == "BO", "...with the nickname you gave it")
	_check(_game_state.caught.has(&"sproutle") and _game_state.caught.has(&"flamlet"), "the starter and the catch are registered as caught")
	_check(not _game_state.bag.has(&"master_orb"), "throwing an orb uses it up")
	_check(_game_state.party[1].orb == &"master_orb", "...and the catch remembers which orb it came in")

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
	lead.status = &"burn"
	var mom: Node2D = _main.current_map.entities.get_node(^"NPC_Mom1")
	mom.wander_radius = 0
	mom.place_at(Vector2i(6, 3), Vector2i.DOWN)
	await _place(Vector2i(6, 4), Vector2i.UP)
	await _tap(&"confirm")
	await _close_dialogue()
	_check(lead.hp == lead.max_hp() and lead.status.is_empty(), "MOM heals your MONSTERS, burns and all")

	# --- Trainers --------------------------------------------------------------
	# A borrowed champion, so the fights are quick and nothing evolves mid-test.
	var team: Array = _game_state.party.duplicate()
	var champ: Resource = load("res://scripts/monsters/monster.gd").create(load("res://data/species/blazard.tres"), 30)
	_game_state.party.assign([champ])
	_main.change_map(MAPS + "route_01.tscn", &"south")
	await _wait(1.0)
	var route_one: Node2D = _main.current_map
	route_one.encounter_rate = 0.0
	var mia: Node2D = route_one.entities.get_node(^"NPC_Lass5")
	var money_before: int = _game_state.money
	await _place(Vector2i(10, 17), Vector2i.UP)
	await _tap(&"move_up") # Into LASS MIA's line of sight.
	await _wait(0.2)
	_check(_player.is_locked() and mia.visual.get_child_count() > 1, "stepping into a trainer's sight shows a \"!\"")
	_shot("27_spotted")
	await _wait(1.6)
	_check(mia.get_cell() == Vector2i(9, 16) and _dialogue.is_open, "...and the trainer walks up and talks")
	await _close_dialogue()
	await _wait(2.0)
	_check(_battle_scene() != null and _battle_scene().battle.is_trainer_battle(), "...then a trainer battle starts")
	_shot("28_trainer_intro")
	await _press_through_battle()
	_check(_game_state.has_flag(&"beat_lass_mia") and _game_state.money == money_before + 80, "beating LASS MIA pays $80 (payout 16 x level 5)")
	_check(_map_name() == "ROUTE 1" and not _player.is_locked(), "the trainer battle returns to the route")
	await _place(Vector2i(10, 16), Vector2i.LEFT)
	await _tap(&"confirm")
	await _wait(0.3)
	_check(_dialogue.is_open and "SPROUTLE" in _dialogue.get_node(^"Box/Text").text, "a beaten trainer just chats")
	await _close_dialogue()
	await _wait(0.5)
	_check(_battle_scene() == null and not _player.is_locked(), "...and doesn't battle again")

	await _place(Vector2i(11, 7), Vector2i.RIGHT) # Behind YOUNGSTER TIM: he can't see you.
	await _tap(&"confirm")
	await _close_dialogue()
	await _wait(2.0)
	await _until_action_menu()
	await _tap(&"move_right")
	await _tap(&"move_down")
	await _tap(&"confirm") # RUN
	await _wait(0.3)
	_check(_dialogue.is_open and "no running" in _dialogue.get_node(^"Box/Text").text, "talking to a trainer battles too, and you can't run")
	await _close_dialogue()
	await _until_action_menu()
	await _tap(&"move_up")
	await _tap(&"move_left") # Back to FIGHT for the rest.
	await _press_through_battle()
	_check(_game_state.has_flag(&"beat_youngster_tim"), "YOUNGSTER TIM is beaten")

	await _place(Vector2i(9, 2), Vector2i.UP)
	await _tap(&"move_up") # REN guards the way north.
	await _wait(2.4)
	_check(route_one.entities.get_node(^"NPC_Rival7").get_cell() == Vector2i(10, 1), "the rival REN spots you and walks over")
	await _close_dialogue()
	await _wait(2.0)
	await _until_action_menu()
	var rival_battle: RefCounted = _battle_scene().battle
	_check(rival_battle.enemy.monster.species.display_name == "AQUAPUP" and rival_battle.enemy.name == "Foe AQUAPUP", "REN leads with the starter that beats yours")
	await _press_through_battle()
	_check(_game_state.has_flag(&"beat_rival_ren"), "...and is beaten")
	_game_state.party.assign(team)
	_main.change_map(MAPS + "house_emberfall.tscn", &"entrance")
	await _wait(1.0)

	# --- Status conditions outside battle ------------------------------------------
	var sick: Resource = _game_state.party[0]
	sick.status = &"poison"
	sick.hp = 10
	for i in 4:
		_player.step_finished.emit(_player.get_cell())
	await _wait(0.3)
	_check(sick.hp == 9 and sick.status == &"poison", "poison costs 1 HP every 4 steps on the map")
	sick.hp = 2
	for i in 4:
		_player.step_finished.emit(_player.get_cell())
	await _wait(0.5)
	_check(sick.hp == 1 and sick.status.is_empty() and _dialogue.is_open, "...and fades at 1 HP instead of fainting")
	await _close_dialogue()
	sick.status = &"poison"
	_game_state.bag.assign({&"antidote": 1})
	await _tap(&"menu")
	await _tap(&"move_down")
	await _tap(&"move_down") # BAG
	await _tap(&"confirm")
	await _tap(&"confirm") # ANTIDOTE
	await _tap(&"confirm") # On the first party member.
	await _close_dialogue()
	_check(sick.status.is_empty() and not _game_state.bag.has(&"antidote"), "an ANTIDOTE from the BAG cures poison")
	await _tap(&"cancel")
	sick.heal_full()

	# --- Start menu: party, summary, BAG, save -------------------------------
	var party_menu: Control = _main.party_menu
	var dex_menu: Control = _main.dex_menu
	await _tap(&"menu")
	await _tap(&"confirm") # MONDEX
	_check(dex_menu.visible, "MONDEX opens from the start menu")
	await _tap(&"confirm") # No. 001 FLAMLET
	_check(dex_menu.get_node(^"Page").visible, "a caught entry opens its MONDEX page")
	_shot_once("12_mondex_page")
	await _tap(&"cancel")
	for i in 4: # No. 002 BLAZARD (unseen), 003 AQUAPUP, 004 TIDEHOUND, 005 SPROUTLE
		await _tap(&"move_down")
	_shot_once("12_mondex")
	await _tap(&"cancel")
	_check(not dex_menu.visible, "B closes the MONDEX")
	await _tap(&"move_down")
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

	_game_state.bag.assign({&"potion": 1, &"mon_orb": 3, &"super_orb": 2, &"hyper_orb": 1, &"net_orb": 1,
		&"dive_orb": 1, &"nest_orb": 1, &"repeat_orb": 1, &"timer_orb": 1, &"gala_orb": 1})
	var hurt: Resource = _game_state.party[0]
	hurt.hp = 1
	await _tap(&"menu")
	await _tap(&"move_down")
	await _tap(&"move_down") # BAG
	await _tap(&"confirm")
	_shot_once("15_bag")
	var rows: Node = _main.start_menu.get_node(^"List")
	_check(rows.get_child_count() == 8 and "▼" in rows.get_child(7).text, "a long BAG shows 8 rows and a ▼ for more")
	await _tap(&"move_up") # Wraps around to CANCEL at the bottom...
	_check("CANCEL" in rows.get_child(7).text and "▲" in rows.get_child(0).text, "...and scrolls to keep the cursor on screen")
	await _tap(&"move_down") # ...and back to the top.
	await _tap(&"confirm") # POTION
	await _tap(&"confirm") # On the first party member.
	await _close_dialogue()
	_check(hurt.hp == mini(21, hurt.max_hp()) and not _game_state.bag.has(&"potion"), "POTIONs work from the BAG")
	await _tap(&"cancel") # Close the BAG,
	await _tap(&"cancel") # then the start menu.

	await _tap(&"menu")
	for i in 5: # MONDEX, MONSTERS, BAG, CARD, FLY, SAVE
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
	_check(_game_state.caught.has(&"sproutle") and _game_state.seen.has(&"zapkit"), "...and your MONDEX")

	# --- GYM: SURF and FLY need the TIDE BADGE --------------------------------
	_main.change_map(MAPS + "town_tidewater.tscn", &"from_route")
	await _wait(1.0)
	_check(_map_name() == "TIDEWATER CITY", "Route 1 connects to Tidewater")
	var town: Node2D = _main.current_map
	town.water_encounter_rate = 0.0
	await _place(Vector2i(6, 5), Vector2i.UP)
	await _tap(&"confirm")
	await _close_dialogue()
	_check(not _player.is_surfing and _player.get_cell() == Vector2i(6, 5), "without the TIDE BADGE you can't SURF")
	await _tap(&"menu")
	for i in 4: # MONDEX, MONSTERS, BAG, CARD, FLY
		await _tap(&"move_down")
	await _tap(&"confirm")
	await _wait(0.3)
	_check(_dialogue.is_open and "TIDE BADGE" in _dialogue.get_node(^"Box/Text").text, "...or FLY")
	await _close_dialogue()
	await _tap(&"move_up")
	await _tap(&"confirm") # CARD
	var card: Control = _main.trainer_card
	var card_text: String = card.get_node(^"Card/Layout/Top/Info").text
	_check(card.visible and "BADGES  0" in card_text and "$%d" % _game_state.money in card_text, "the TRAINER CARD shows your money and badges")
	_check(_game_state.play_seconds > 10.0 and "TIME    0:0" in card_text, "...and the play time, which keeps counting")
	await _tap(&"cancel")
	await _tap(&"cancel")
	_check(not card.visible and not _player.is_locked(), "B closes the card and the menu")

	team = _game_state.party.duplicate()
	_game_state.party.assign([load("res://scripts/monsters/monster.gd").create(load("res://data/species/blazard.tres"), 30)])
	await _place(Vector2i(5, 20), Vector2i.UP)
	await _tap(&"move_up")
	await _wait(1.0)
	_check(_map_name() == "TIDEWATER GYM" and _player.get_cell() == Vector2i(5, 9), "the GYM door leads inside")
	_shot("30_gym")
	await _tap(&"move_up")
	await _tap(&"move_up") # SWIMMER NIA watches this crossing...
	await _until_dialogue()
	await _close_dialogue()
	await _wait(2.0)
	_check(_battle_scene() != null, "...and battles you on the walkway")
	await _press_through_battle()
	for i in 4: # Turn back up (you faced NIA), then on to SWIMMER LUCA's crossing.
		await _tap(&"move_up")
	await _until_dialogue()
	await _close_dialogue()
	await _wait(2.0)
	await _press_through_battle()
	_check(_game_state.has_flag(&"beat_swimmer_nia") and _game_state.has_flag(&"beat_swimmer_luca"), "both GYM SWIMMERs are beaten")
	var money_before_leader: int = _game_state.money
	for i in 3: # Turn up (you faced LUCA), then up to LEADER MARINA.
		await _tap(&"move_up")
	await _until_dialogue()
	await _close_dialogue()
	await _wait(2.0)
	_check(root.get_node(^"Audio").get(&"_wanted_track") == &"gym_battle", "the GYM LEADER has her own battle music")
	await _until_action_menu()
	_shot("31_gym_battle")
	await _press_through_battle()
	_check(_game_state.has_flag(&"beat_leader_marina") and _game_state.money == money_before_leader + 1400, "beating MARINA pays $1400 (payout 100 x level 14)")
	_check(_dialogue.is_open and "TIDE BADGE" in _dialogue.get_node(^"Box/Text").text, "...and she hands over the TIDE BADGE")
	_shot("32_badge")
	await _close_dialogue()
	_check(_game_state.has_flag(&"tide_badge") and not _player.is_locked(), "the badge is yours, and control returns")
	await _tap(&"menu")
	for i in 3: # MONDEX, MONSTERS, BAG, CARD
		await _tap(&"move_down")
	await _tap(&"confirm")
	_check("BADGES  1" in card.get_node(^"Card/Layout/Top/Info").text, "the TRAINER CARD shows the new badge")
	_shot("33_trainer_card")
	await _tap(&"cancel")
	await _tap(&"cancel")
	_game_state.party.assign(team)
	await _place(Vector2i(5, 9), Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(1.0)
	_check(_map_name() == "TIDEWATER CITY" and _player.get_cell() == Vector2i(5, 20), "the GYM mat leads back outside")
	town = _main.current_map
	town.water_encounter_rate = 0.0

	# --- SURF ----------------------------------------------------------------
	await _place(Vector2i(6, 5), Vector2i.UP)
	await _tap(&"confirm")
	await _wait(1.6)
	_shot("17_surf_prompt")
	await _tap(&"confirm") # YES
	await _wait(0.6)
	_check(_player.is_surfing and _player.get_cell() == Vector2i(6, 4), "SURF hops onto the water")
	town.water_encounter_rate = 1.0
	town.wild_levels = Vector2i(2, 2)
	var sprout: Resource = _game_state.party[0]
	sprout.level = 11
	sprout.experience = sprout.exp_for_level(12) - 1
	sprout.hp = sprout.max_hp()
	await _tap(&"move_up")
	await _wait(2.5)
	_check(_battle_scene() != null, "wild monsters can appear while surfing")
	await _press_through_battle()
	_check(_game_state.seen.has(&"aquapup") and not _game_state.caught.has(&"aquapup"), "monsters you battle are marked as seen")
	_check(await _until_evolution_text(), "SPROUTLE starts evolving after the battle")
	await _press_through_evolutions(func() -> void:
		if sprout.species.display_name == "GROVETLE" and _dialogue.is_open and not _dialogue.get(&"_typing"):
			_shot_once("26_evolved"))
	_check(sprout.species.display_name == "GROVETLE" and sprout.level == 12, "...and becomes GROVETLE at the same level")
	_check(_game_state.caught.has(&"grovetle"), "evolving registers the new form in the MONDEX")
	_check(not _player.is_locked() and _player.is_surfing, "control returns after evolving, still surfing")
	town.water_encounter_rate = 0.0
	_shot("18_surfing")
	await _tap(&"move_left")
	await _tap(&"move_left")
	await _wait(0.6)
	_check(not _player.is_surfing and _player.get_cell() == Vector2i(5, 3), "surfing into land dismounts")

	# --- MART ----------------------------------------------------------------
	await _place(Vector2i(4, 12), Vector2i.UP)
	await _tap(&"move_up")
	await _wait(1.0)
	_check(_map_name() == "TIDEWATER MART", "the MART door leads inside")
	_game_state.money = 5000
	_game_state.bag.assign({&"potion": 3})
	var clerk: Node = _main.current_map.entities.get_node(^"NPC_Clerk1")
	var choices: Control = _dialogue.get_node(^"ChoiceArea/Choices")
	await _place(Vector2i(3, 2), Vector2i.LEFT)
	await _tap(&"confirm")
	await _wait(0.8)
	var shop: Node = clerk.get_node_or_null(^"ShopMenu")
	_check(shop != null and choices.visible, "the clerk is reached across the counter and opens the shop")
	_shot("20_mart")
	await _tap(&"confirm") # BUY
	_check(shop.get_node(^"ListArea/List").visible, "BUY lists the clerk's stock")
	_shot("21_shop_buy")
	await _tap(&"confirm") # MON ORB
	await _tap(&"move_right") # +10: 11,
	await _tap(&"move_down") # then 10.
	_shot("22_shop_quantity")
	await _tap(&"confirm")
	await _wait(1.2)
	await _tap(&"confirm") # YES
	await _close_dialogue()
	_check(_game_state.money == 3000 and _game_state.item_count(&"mon_orb") == 10, "buying 10 MON ORBs costs $2000")
	_check(_game_state.item_count(&"gala_orb") == 1, "...and the clerk throws in a GALA ORB")
	await _tap(&"cancel") # Back to BUY / SELL / QUIT.
	await _wait(1.0)
	await _tap(&"move_down")
	await _tap(&"confirm") # SELL
	await _tap(&"confirm") # POTION
	await _tap(&"confirm") # Just one.
	await _wait(1.0)
	await _tap(&"confirm") # YES
	await _close_dialogue()
	_check(_game_state.money == 3150 and _game_state.item_count(&"potion") == 2, "selling a POTION pays half its price")
	await _tap(&"cancel")
	await _wait(1.0)
	await _tap(&"cancel") # QUIT
	await _close_dialogue()
	_check(not is_instance_valid(shop) and not _player.is_locked(), "leaving the shop returns control")
	var specialist: Node = _main.current_map.entities.get_node(^"NPC_Clerk2")
	await _place(Vector2i(3, 1), Vector2i.LEFT)
	await _tap(&"confirm")
	await _wait(0.8)
	await _tap(&"confirm") # BUY
	shop = specialist.get_node_or_null(^"ShopMenu")
	_check(shop != null and "NET ORB" in shop.get_node(^"ListArea/List/List").get_child(0).text, "the upper counter sells specialty orbs")
	await _tap(&"move_down") # DIVE ORB
	_shot("22_shop_orbs")
	await _tap(&"confirm")
	await _tap(&"confirm") # Just one.
	await _wait(1.2)
	await _tap(&"confirm") # YES
	await _close_dialogue()
	_check(_game_state.money == 2150 and _game_state.item_count(&"dive_orb") == 1, "a DIVE ORB costs $1000")
	await _tap(&"cancel")
	await _wait(1.0)
	await _tap(&"cancel") # QUIT
	await _close_dialogue()
	await _place(Vector2i(4, 5), Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(1.0)
	_check(_map_name() == "TIDEWATER CITY" and _player.get_cell() == Vector2i(4, 12), "the mat leads back out of the MART")

	# --- Evolution stones ----------------------------------------------------
	_game_state.add_monster(load("res://scripts/monsters/monster.gd").create(load("res://data/species/zapkit.tres"), 8))
	_game_state.bag.assign({&"bolt_stone": 1})
	await _open_bag_item()
	await _tap(&"confirm") # On GROVETLE, which no stone evolves.
	await _close_dialogue()
	_check(_game_state.item_count(&"bolt_stone") == 1, "a stone that won't work isn't used up")
	await _tap(&"cancel") # Close the BAG...
	await _tap(&"cancel") # ...and the start menu.
	await _open_bag_item()
	await _tap(&"move_down")
	await _tap(&"move_down")
	await _tap(&"confirm") # On ZAPKIT, in the third slot.
	_check(await _until_evolution_text(), "a BOLT STONE starts ZAPKIT's evolution")
	await _close_dialogue() # "What? ZAPKIT is evolving!"
	await _hold(&"cancel", 0.5)
	_check(not _dialogue.is_open, "B can't stop a stone evolution")
	await _press_through_evolutions()
	var zap: Resource = _game_state.party[2]
	_check(zap.species.display_name == "VOLTVIX" and not _game_state.bag.has(&"bolt_stone"), "...which makes VOLTVIX and uses up the stone")
	_check(_main.start_menu.visible, "...then returns to the start menu")
	await _tap(&"cancel")
	_check(not _player.is_locked(), "closing it returns control")

	# --- MONSTER CENTER and the other houses -----------------------------------
	await _place(Vector2i(19, 12), Vector2i.UP)
	await _tap(&"move_up")
	await _wait(1.0)
	_check(_map_name() == "MONSTER CENTER", "the MONSTER CENTER door leads inside")
	_shot("23_center")
	_game_state.party[0].hp = 1
	await _place(Vector2i(5, 3), Vector2i.UP)
	await _tap(&"confirm")
	await _close_dialogue()
	_check(_game_state.party[0].hp == _game_state.party[0].max_hp(), "the nurse heals your MONSTERS across the counter")
	var pc_choices: Control = _dialogue.get_node(^"ChoiceArea/Choices")
	var stored: Resource = _game_state.party[2]
	await _place(Vector2i(10, 3), Vector2i.RIGHT)
	await _tap(&"confirm") # The PC in the corner.
	await _until_choices(pc_choices)
	_check(pc_choices.visible, "the PC opens the MONSTER Storage System")
	await _tap(&"move_down")
	await _tap(&"confirm") # DEPOSIT
	await _tap(&"move_down")
	await _tap(&"move_down")
	_shot("29_pc")
	await _tap(&"confirm") # The third party member.
	await _until_choices(pc_choices)
	_check(_game_state.party.size() == 2 and _game_state.storage.has(stored), "DEPOSIT moves a monster into the BOX")
	await _tap(&"confirm") # WITHDRAW
	await _tap(&"confirm") # The only one in the BOX.
	await _until_choices(pc_choices)
	_check(_game_state.party.size() == 3 and _game_state.party[2] == stored and _game_state.storage.is_empty(), "WITHDRAW brings it back")
	for i in 3:
		await _tap(&"move_down")
	await _tap(&"confirm") # SEE YA!
	await _close_dialogue()
	_check(not _player.is_locked(), "logging off returns control")
	await _place(Vector2i(5, 6), Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(1.0)
	_check(_map_name() == "TIDEWATER CITY" and _player.get_cell() == Vector2i(19, 12), "the MONSTER CENTER mat leads back outside")

	# --- NAME RATER --------------------------------------------------------------
	var renamed: Resource = _game_state.party[0]
	await _place(Vector2i(18, 20), Vector2i.UP)
	await _tap(&"move_up")
	await _wait(1.0)
	_check(_map_name() == "SEASIDE HOUSE", "the seaside house can be entered")
	await _place(Vector2i(1, 5), Vector2i.UP)
	await _tap(&"confirm")
	await _until_choices(_choices)
	await _tap(&"confirm") # YES, rate a nickname.
	await _until_choices(_choices)
	await _tap(&"confirm") # BO, the first party member.
	await _until_choices(_choices)
	await _tap(&"confirm") # YES, give it a nicer one.
	_check(_naming.is_open and _naming.get_node(^"Screen/Top/Layout/Text/Name").text.begins_with("BO"), "the NAME RATER opens the naming screen with the old name")
	await _tap(&"cancel") # B deletes a letter at a time.
	await _tap(&"cancel")
	await _tap(&"menu")
	await _tap(&"confirm") # OK with nothing typed...
	await _close_dialogue()
	_check(renamed.nickname.is_empty() and renamed.get_display_name() == "GROVETLE", "...and an empty name clears the nickname")
	await _place(Vector2i(4, 5), Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(1.0)
	_check(_map_name() == "TIDEWATER CITY" and _player.get_cell() == Vector2i(18, 20), "the seaside house mat leads back outside")

	# --- FLY -----------------------------------------------------------------
	await _place(Vector2i(11, 15), Vector2i.DOWN)
	await _tap(&"menu")
	_check(_main.start_menu.visible, "ENTER opens the start menu")
	for i in 4: # MONDEX, MONSTERS, BAG, CARD, FLY
		await _tap(&"move_down")
	await _tap(&"confirm") # FLY
	await _wait(0.2)
	_shot("19_fly_menu")
	await _tap(&"confirm") # First visited town: Emberfall.
	await _wait(1.2)
	_check(_map_name() == "EMBERFALL TOWN" and _player.get_cell() == Vector2i(11, 9), "FLY returns to a visited town")

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
	return _on_battle_layer("battle_scene.tscn")


func _evolution_scene() -> Control:
	return _on_battle_layer("evolution_scene.tscn")


func _on_battle_layer(scene_file: String) -> Control:
	var layer: CanvasLayer = _main.battle_layer
	for child in layer.get_children():
		if not child.is_queued_for_deletion() and child.scene_file_path.get_file() == scene_file:
			return child
	return null


## Waits for the evolution screen's opening "What? X is evolving!" text.
## Returns false if it never shows up.
func _until_evolution_text() -> bool:
	for i in 40:
		if _evolution_scene() != null and _dialogue.is_open:
			return true
		await _wait(0.1)
	return false


## Presses A through the evolution screen (and any new moves) until it has
## closed. `on_page` runs before each press.
func _press_through_evolutions(on_page := Callable()) -> void:
	for i in 60:
		if _evolution_scene() == null and not _dialogue.is_open:
			break
		if on_page.is_valid():
			on_page.call()
		await _tap(&"confirm")
	await _wait(1.0)


## Opens the start menu's BAG and picks its first item, ending on the party
## screen's "Use on which MONSTER?".
func _open_bag_item() -> void:
	await _tap(&"menu")
	await _tap(&"move_down")
	await _tap(&"move_down") # BAG
	await _tap(&"confirm")
	await _tap(&"confirm")


## Walks in through the door above `outside`, checks the map name, and walks
## back out through the mat, expecting to arrive at `back`.
func _visit(outside: Vector2i, inside_name: String, back: Vector2i) -> void:
	await _place(outside, Vector2i.UP)
	await _tap(&"move_up")
	await _wait(1.0)
	var entered := _map_name() == inside_name
	var mat: Vector2i = _player.get_cell() + Vector2i.DOWN
	await _place(mat + Vector2i.UP, Vector2i.DOWN)
	await _tap(&"move_down")
	await _wait(1.0)
	_check(entered and _player.get_cell() == back, "%s can be entered and left" % inside_name)


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


## Presses A through text until a Dialogue.choose() list shows.
func _until_choices(choices: Control) -> void:
	for i in 25:
		if choices.visible:
			return
		await _tap(&"confirm")


## Waits for a text box, e.g. a trainer who spotted you walking over.
func _until_dialogue() -> void:
	for i in 40:
		if _dialogue.is_open:
			return
		await _wait(0.1)


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
