extends SceneTree
## Unit tests for GameState: party, BOX, BAG, flags and save/load. Uses its
## own GameState instance and save file, so a real save is never touched.
##   godot --headless --path . --script res://tests/game_state_test.gd
## Exits with code 0 when every check passes, 1 otherwise.

const TEST_SAVE := "user://test_save.json"
const STATE_SCRIPT := "res://autoload/game_state.gd"

var _failures := 0


func _initialize() -> void:
	_test_party_and_bag()
	_test_mondex()
	_test_monster_round_trip()
	_test_save_and_load()
	_test_bad_saves()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("\nGAME STATE TEST %s (%d failed)" % ["PASSED" if _failures == 0 else "FAILED", _failures])
	quit(1 if _failures > 0 else 0)


func _test_party_and_bag() -> void:
	var state := _new_state()
	_check(state.party.is_empty() and not state.has_flag(state.STARTER_FLAG), "a new game starts without monsters")
	for i in 6:
		state.add_monster(_monster(&"sproutle", 2))
	_check(state.party.size() == 6 and state.storage.is_empty(), "the party holds up to six monsters")
	_check(not state.add_monster(_monster(&"zapkit", 2)) and state.storage.size() == 1, "a 7th monster goes to the BOX")
	state.bag.assign({&"potion": 1})
	_check(state.remove_item(&"potion") and not state.bag.has(&"potion"), "using the last item removes it from the BAG")
	_check(not state.remove_item(&"potion"), "you can't use an item you don't have")
	state.add_item(&"mon_orb", 60)
	state.add_item(&"mon_orb", 60)
	_check(state.item_count(&"mon_orb") == state.MAX_ITEM_COUNT, "the BAG holds at most 99 of an item")
	_check(not state.remove_item(&"mon_orb", 100) and state.item_count(&"mon_orb") == 99, "removing more than you have removes nothing")
	_check(state.remove_item(&"mon_orb", 98) and state.item_count(&"mon_orb") == 1, "items can be removed several at a time")
	_check(state.money == state.START_MONEY, "a new game starts with $%d" % state.START_MONEY)
	_check(not state.spend_money(state.money + 1) and state.money == state.START_MONEY, "you can't spend more than you have")
	_check(state.spend_money(1000) and state.money == state.START_MONEY - 1000, "spending takes the money")
	state.add_money(state.MAX_MONEY)
	_check(state.money == state.MAX_MONEY, "money is capped at $%d" % state.MAX_MONEY)
	state.set_flag(&"met_rival")
	_check(state.has_flag(&"met_rival") and not state.has_flag(&"unknown"), "story flags default to off")
	state.free()


func _test_mondex() -> void:
	var state := _new_state()
	state.mark_seen(&"zapkit")
	state.add_monster(_monster(&"aquapup", 5))
	_check(state.seen.has(&"zapkit") and not state.caught.has(&"zapkit"), "meeting a monster marks it as seen")
	_check(state.caught.has(&"aquapup") and state.seen.has(&"aquapup"), "getting a monster marks it as caught and seen")
	var numbers := GameData.all_species().map(func(species: MonsterSpecies) -> int: return species.dex_number)
	_check(numbers == range(1, 13), "the MONDEX lists all 12 species in number order")
	state.free()


func _test_monster_round_trip() -> void:
	var original := _monster(&"flamlet", 12)
	original.nickname = "BLAZE"
	original.nature = &"ADAMANT"
	original.orb = &"dive_orb"
	original.hp = 7
	original.pp[0] = 3
	var copy := Monster.from_dict(JSON.parse_string(JSON.stringify(original.to_dict())))
	_check(copy != null and copy.species == original.species and copy.nickname == "BLAZE", "a monster survives a save/load round trip")
	_check(copy.level == 12 and copy.hp == 7 and copy.experience == original.experience, "level, HP and EXP are kept")
	_check(copy.moves == original.moves and copy.pp == original.pp and copy.ivs == original.ivs, "moves, PP and IVs are kept")
	_check(copy.nature == &"ADAMANT", "the nature is kept")
	_check(copy.orb == &"dive_orb", "the orb it was caught in is kept")
	var old_save := original.to_dict()
	old_save.erase("nature")
	old_save.erase("orb")
	var old_monster := Monster.from_dict(old_save)
	_check(old_monster.nature == &"HARDY", "monsters from older saves get a neutral nature")
	_check(old_monster.orb == &"mon_orb", "...and a MON ORB")
	_check(Monster.from_dict({"species": "missingno"}) == null, "unknown species are skipped instead of crashing")


func _test_save_and_load() -> void:
	var state := _new_state()
	state.add_monster(_monster(&"aquapup", 9))
	state.add_monster(_monster(&"zapkit", 4))
	state.storage.append(_monster(&"pebblet", 3))
	state.bag.assign({&"mon_orb": 4, &"potion": 2})
	state.money = 1234
	state.mark_seen(&"shadeling")
	state.set_flag(state.STARTER_FLAG)
	state.mark_town_visited("res://scenes/maps/town_emberfall.tscn", "EMBERFALL TOWN")
	var location := {"map": "res://scenes/maps/route_01.tscn", "cell": Vector2i(9, 12), "facing": Vector2i.LEFT, "surfing": true}
	_check(state.save_game(location) == OK and state.has_save(), "saving writes the save file")
	state.free()

	var loaded := _new_state()
	var where: Dictionary = loaded.load_game()
	_check(where.map == location.map and where.cell == location.cell and where.facing == Vector2i.LEFT and where.surfing, "the player's position is restored")
	_check(loaded.party.size() == 2 and loaded.party[0].get_display_name() == "AQUAPUP" and loaded.party[0].level == 9, "the party is restored in order")
	_check(loaded.storage.size() == 1 and loaded.storage[0].get_display_name() == "PEBBLET", "the BOX is restored")
	_check(loaded.bag.get(&"mon_orb") == 4 and loaded.bag.get(&"potion") == 2, "the BAG is restored")
	_check(loaded.money == 1234, "money is restored")
	_check(loaded.seen.has(&"shadeling") and loaded.caught.has(&"aquapup") and not loaded.caught.has(&"shadeling"), "the MONDEX is restored")
	_check(loaded.caught.has(&"pebblet"), "monsters owned before the MONDEX existed count as caught")
	_check(loaded.has_flag(loaded.STARTER_FLAG) and loaded.visited_towns.has("res://scenes/maps/town_emberfall.tscn"), "flags and Fly destinations are restored")
	loaded.free()


func _test_bad_saves() -> void:
	var state := _new_state()
	_write(TEST_SAVE, "this is not json {")
	_check(state.load_game().is_empty() and state.party.is_empty(), "a corrupt save is ignored")
	_write(TEST_SAVE, JSON.stringify({"version": 999}))
	_check(state.load_game().is_empty(), "a save from a newer version is ignored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	_check(not state.has_save() and state.load_game().is_empty(), "no save file means nothing to load")
	state.free()


# --- Helpers -------------------------------------------------------------------

func _new_state() -> Node:
	var state: Node = load(STATE_SCRIPT).new()
	state.save_path = TEST_SAVE
	return state


func _monster(id: StringName, level: int) -> Monster:
	return Monster.create(GameData.species(id), level)


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _check(passed: bool, what: String) -> void:
	print("%s  %s" % ["PASS" if passed else "FAIL", what])
	if not passed:
		_failures += 1
