extends SceneTree
## Unit tests for the battle rules (Battle, Battler, Monster, abilities).
## No scene or input involved, so it runs in well under a second:
##   godot --headless --path . --script res://tests/battle_test.gd
## Exits with code 0 when every check passes, 1 otherwise.

var _failures := 0


func _initialize() -> void:
	_test_stats()
	_test_type_chart()
	_test_damage_formula()
	_test_stat_stages()
	_test_turn_order()
	_test_abilities()
	_test_win_lose_switch_run()
	_test_pp_and_struggle()
	_test_experience()
	_test_catching()
	_test_special_orbs()
	_test_items()
	print("\nBATTLE TEST %s (%d failed)" % ["PASSED" if _failures == 0 else "FAILED", _failures])
	quit(1 if _failures > 0 else 0)


func _test_stats() -> void:
	var flamlet := _monster(&"flamlet", 5)
	_check(flamlet.max_hp() == 18, "HP formula: (2*39)*5/100 + 5 + 10 = 18")
	_check(flamlet.stat(&"attack") == 10, "stat formula: (2*52)*5/100 + 5 = 10")
	_check(_names(flamlet.moves) == ["SCRATCH", "GROWL"], "new monsters know their learnset up to their level")


func _test_type_chart() -> void:
	_check(TypeChart.multiplier("fire", "grass") == 2.0, "fire is super effective on grass")
	_check(TypeChart.multiplier("water", "water") == 0.5, "water resists water")
	_check(TypeChart.multiplier("normal", "ghost") == 0.0, "normal can't touch ghost")
	_check(TypeChart.multiplier("grass", "normal") == 1.0, "unlisted matchups are neutral")


func _test_damage_formula() -> void:
	var battle := _battle([_monster(&"flamlet", 5)], _monster(&"sproutle", 5))
	var ember := GameData.move(&"ember")
	# floor(floor(4 * 40 * 10 / 11) / 50) + 2 = 4, then x2 (type) x1.5 (STAB) = 12
	_check(battle.calculate_damage(battle.player, battle.enemy, ember, false, 2.0, 100) == 12, "Gen 3 damage formula with STAB and type bonus")
	_check(battle.calculate_damage(battle.player, battle.enemy, ember, true, 2.0, 100) == 24, "critical hits double damage")
	_check(battle.calculate_damage(battle.player, battle.enemy, ember, false, 2.0, 85) == 10, "the random roll scales damage down to 85%")
	battle.player.monster.hp = 6
	_check(battle.calculate_damage(battle.player, battle.enemy, ember, false, 2.0, 100) == 18, "KINDLE boosts fire moves at low HP")


func _test_stat_stages() -> void:
	_check(is_equal_approx(Battler.stage_multiplier(-1), 2.0 / 3.0), "stage -1 is 2/3")
	_check(Battler.stage_multiplier(2) == 2.0 and Battler.stage_multiplier(-6) == 0.25, "stages +2 and -6")
	var battle := _battle([_monster(&"flamlet", 5)], _monster(&"sproutle", 5))
	_only_move(battle.enemy.monster, &"harden")
	var events := battle.take_turn(Battle.fight(_index(battle.player.monster, "GROWL")))
	_check(battle.enemy.stages[&"attack"] == -1 and _has_text(events, "ATTACK\nfell!"), "GROWL lowers the foe's ATTACK")
	_check(battle.enemy.stages[&"defense"] == 1, "HARDEN raises the user's DEFENSE")
	battle.enemy.stages[&"attack"] = Battler.MIN_STAGE
	events = battle.take_turn(Battle.fight(_index(battle.player.monster, "GROWL")))
	_check(battle.enemy.stages[&"attack"] == Battler.MIN_STAGE and _has_text(events, "won't go\nlower"), "stages stop at -6")


func _test_turn_order() -> void:
	var battle := _battle([_monster(&"pebblet", 5)], _monster(&"zapkit", 5))
	_only_move(battle.enemy.monster, &"growl")
	var events := battle.take_turn(Battle.fight(_index(battle.player.monster, "TACKLE")))
	_check(_first_user(events) == "Wild ZAPKIT", "the faster monster moves first")
	battle.player.monster.replace_move(0, GameData.move(&"quick_hit"))
	events = battle.take_turn(Battle.fight(0))
	_check(_first_user(events) == "PEBBLET", "priority moves go first regardless of speed")


func _test_abilities() -> void:
	# DREAD: lowers the foe's ATTACK on entry.
	var battle := _battle([_monster(&"flamlet", 5)], _monster(&"shadeling", 5))
	var events := battle.start()
	_check(battle.player.stages[&"attack"] == -1 and _has_text(events, "DREAD"), "DREAD lowers the foe's ATTACK on entry")

	# SOAK UP: water moves heal instead of hurting.
	battle = _battle([_monster(&"flamlet", 5)], _monster(&"aquapup", 5))
	_only_move(battle.enemy.monster, &"growl")
	battle.player.monster.replace_move(0, GameData.move(&"water_gun"))
	battle.enemy.monster.hp = 5
	events = battle.take_turn(Battle.fight(0))
	_check(battle.enemy.monster.hp > 5 and _has_text(events, "SOAK UP"), "SOAK UP turns water damage into healing")

	# SUNSOAK: heals a little every turn.
	battle = _battle([_monster(&"flamlet", 5)], _monster(&"sproutle", 5))
	_only_move(battle.enemy.monster, &"growl")
	battle.enemy.monster.hp = 5
	battle.take_turn(Battle.fight(_index(battle.player.monster, "GROWL")))
	_check(battle.enemy.monster.hp == 6, "SUNSOAK restores 1/16 HP at the end of the turn")

	# STURDY SHELL: survives a one-hit KO from full HP.
	battle = _battle([_monster(&"aquapup", 40)], _monster(&"pebblet", 5))
	_only_move(battle.enemy.monster, &"harden")
	events = battle.take_turn(Battle.fight(_index(battle.player.monster, "BUBBLEBEAM")))
	_check(battle.enemy.monster.hp == 1 and _has_text(events, "endured"), "STURDY SHELL survives a hit at full HP")

	# JOLT: may lower the attacker's SPEED (forced to 100% here).
	var zapkit := _monster(&"zapkit", 5)
	zapkit.species = zapkit.species.duplicate()
	zapkit.species.ability = zapkit.species.ability.duplicate()
	zapkit.species.ability.chance = 1.0
	battle = _battle([_monster(&"flamlet", 5)], zapkit)
	_only_move(battle.enemy.monster, &"growl")
	battle.take_turn(Battle.fight(_index(battle.player.monster, "SCRATCH")))
	_check(battle.player.stages[&"speed"] == -1, "JOLT lowers the attacker's SPEED")

	# Element immunity.
	battle = _battle([_monster(&"flamlet", 5)], _monster(&"shadeling", 5))
	_only_move(battle.enemy.monster, &"scary_face")
	var hp := battle.enemy.monster.hp
	events = battle.take_turn(Battle.fight(_index(battle.player.monster, "SCRATCH")))
	_check(battle.enemy.monster.hp == hp and _has_text(events, "doesn't affect"), "normal moves can't hit ghosts")


func _test_win_lose_switch_run() -> void:
	var battle := _battle([_monster(&"flamlet", 20)], _monster(&"sproutle", 2))
	battle.take_turn(Battle.fight(_index(battle.player.monster, "EMBER")))
	_check(battle.outcome == Battle.Outcome.WON, "knocking out the wild monster wins")
	_check(battle.exp_reward() == 14, "EXP reward is exp_yield * level / 7")

	var weak := _monster(&"flamlet", 3)
	weak.hp = 1
	battle = _battle([weak], _monster(&"zapkit", 30))
	_only_move(battle.enemy.monster, &"spark") # 100% accurate, so the KO is certain.
	battle.take_turn(Battle.fight(_index(weak, "GROWL")))
	_check(battle.outcome == Battle.Outcome.LOST, "losing your only monster loses the battle")

	var backup := _monster(&"aquapup", 5)
	weak.hp = 1
	battle = _battle([weak, backup], _monster(&"zapkit", 30))
	_only_move(battle.enemy.monster, &"spark") # 100% accurate, so the KO is certain.
	battle.take_turn(Battle.fight(_index(weak, "GROWL")))
	_check(battle.player_must_switch() and battle.outcome == Battle.Outcome.ONGOING, "a fainted lead forces a switch when others can fight")
	var events := battle.switch_after_faint(1)
	_check(battle.player.monster == backup and _has_text(events, "Go! AQUAPUP!"), "switching in sends out the chosen monster")

	battle = _battle([_monster(&"zapkit", 5)], _monster(&"pebblet", 5))
	battle.take_turn(Battle.run_away())
	_check(battle.outcome == Battle.Outcome.FLED, "a faster monster always escapes")


func _test_pp_and_struggle() -> void:
	var battle := _battle([_monster(&"flamlet", 5)], _monster(&"sproutle", 5))
	_only_move(battle.enemy.monster, &"growl")
	var growl := _index(battle.player.monster, "GROWL")
	battle.take_turn(Battle.fight(growl))
	_check(battle.player.monster.pp[growl] == GameData.move(&"growl").max_pp - 1, "using a move spends 1 PP")
	for i in battle.player.monster.pp.size():
		battle.player.monster.pp[i] = 0
	_check(not battle.player.monster.has_usable_move(), "no PP left is detected")
	var events := battle.take_turn(Battle.fight(-1))
	_check(_has_text(events, "STRUGGLE"), "STRUGGLE is used when every move is out of PP")


func _test_experience() -> void:
	var flamlet := _monster(&"flamlet", 6)
	flamlet.hp -= 3
	var missing := flamlet.max_hp() - flamlet.hp
	var levels := flamlet.gain_exp(flamlet.exp_for_level(7) - flamlet.experience)
	_check(levels == 1 and flamlet.level == 7, "EXP follows the n^3 curve")
	_check("EMBER" in _names(flamlet.moves), "level-ups teach the learnset's moves")
	_check(flamlet.max_hp() - flamlet.hp == missing, "levelling up keeps the damage already taken")


func _test_catching() -> void:
	var battle := _battle([_monster(&"flamlet", 5)], _monster(&"sproutle", 3))
	_check(battle.catch_shakes(battle.enemy.monster, 255.0) == 4, "a MASTER ORB always catches")

	# Odds rise as HP falls: ~25% at full HP, ~74% at 1 HP for SPROUTLE.
	var full_rate := _catch_rate(battle, 1.0, battle.enemy.monster.max_hp())
	var low_rate := _catch_rate(battle, 1.0, 1)
	_check(full_rate > 0.18 and full_rate < 0.32, "MON ORB at full HP catches about 1 in 4 (got %.2f)" % full_rate)
	_check(low_rate > 0.65 and low_rate < 0.82, "MON ORB at 1 HP catches about 3 in 4 (got %.2f)" % low_rate)
	_check(_catch_rate(battle, 1.5, 1) > low_rate, "SUPER ORB beats MON ORB")

	var events := battle.take_turn(Battle.use_item(GameData.item(&"master_orb")))
	_check(battle.outcome == Battle.Outcome.CAUGHT, "a caught monster ends the battle")
	_check(_count(events, &"shake") == 3 and _count(events, &"caught") == 1 and _has_text(events, "Gotcha!"), "a catch shakes three times then clicks")
	_check(not _used_move(events, "Wild SPROUTLE"), "the wild monster doesn't act after being caught")
	_check(battle.enemy.monster.orb == &"master_orb", "a caught monster remembers its orb")

	var tough := _monster(&"shadeling", 3)
	tough.species = tough.species.duplicate()
	tough.species.catch_rate = 3
	battle = _battle([_monster(&"flamlet", 5)], tough)
	events = battle.take_turn(Battle.use_item(GameData.item(&"mon_orb")))
	_check(_count(events, &"break_free") == 1 and battle.outcome == Battle.Outcome.ONGOING, "a failed catch breaks free")
	_check(_used_move(events, "Wild SHADELING"), "the wild monster acts after breaking free")


func _test_special_orbs() -> void:
	var water := _battle([_monster(&"flamlet", 5)], _monster(&"aquapup", 25))
	var land := _battle([_monster(&"flamlet", 5)], _monster(&"sproutle", 25))
	var orb := func(id: StringName) -> ItemData: return GameData.item(id)
	_check(water.ball_multiplier(orb.call(&"mon_orb")) == 1.0 and water.ball_multiplier(orb.call(&"super_orb")) == 1.5 and water.ball_multiplier(orb.call(&"hyper_orb")) == 2.0, "MON, SUPER and HYPER ORBs are 1x, 1.5x and 2x")
	_check(water.ball_multiplier(orb.call(&"net_orb")) == 3.0 and land.ball_multiplier(orb.call(&"net_orb")) == 1.0, "a NET ORB is 3x on WATER monsters only")
	_check(water.ball_multiplier(orb.call(&"dive_orb")) == 1.0, "a DIVE ORB is 1x on land")
	water.in_water = true
	_check(water.ball_multiplier(orb.call(&"dive_orb")) == 3.5, "...and 3.5x in the water")
	_check(land.ball_multiplier(orb.call(&"repeat_orb")) == 1.0, "a REPEAT ORB is 1x on a new species")
	land.already_caught = true
	_check(land.ball_multiplier(orb.call(&"repeat_orb")) == 3.0, "...and 3x on one caught before")
	_check(land.ball_multiplier(orb.call(&"nest_orb")) == 1.5, "a NEST ORB is (40 - level) / 10: 1.5x at level 25")
	land.enemy.monster.level = 5
	_check(land.ball_multiplier(orb.call(&"nest_orb")) == 3.5, "...3.5x at level 5")
	land.enemy.monster.level = 35
	_check(land.ball_multiplier(orb.call(&"nest_orb")) == 1.0, "...and never below 1x")
	_check(land.ball_multiplier(orb.call(&"timer_orb")) == 1.0, "a TIMER ORB starts at 1x")
	land.turns = 15
	_check(land.ball_multiplier(orb.call(&"timer_orb")) == 2.5, "...grows by 0.1x a turn")
	land.turns = 50
	_check(land.ball_multiplier(orb.call(&"timer_orb")) == 4.0, "...up to 4x")
	var turns_before := water.turns
	water.take_turn(Battle.fight(0))
	_check(water.turns == turns_before + 1, "each turn counts toward the TIMER ORB")


func _test_items() -> void:
	var battle := _battle([_monster(&"flamlet", 5)], _monster(&"sproutle", 3))
	_only_move(battle.enemy.monster, &"growl")
	battle.player.monster.hp -= 10
	var events := battle.take_turn(Battle.use_item(GameData.item(&"potion")))
	_check(battle.player.monster.hp == battle.player.monster.max_hp(), "POTION heals up to its amount")
	_check(_has_text(events, "restored by 10 points"), "POTION reports how much it healed")


# --- Helpers -------------------------------------------------------------------

## A monster with zero IVs and a neutral nature so stats are predictable.
func _monster(id: StringName, level: int) -> Monster:
	var monster := Monster.create(GameData.species(id), level)
	monster.nature = &"HARDY"
	for stat in Monster.STATS:
		monster.ivs[stat] = 0
	monster.hp = monster.max_hp()
	return monster


func _battle(party: Array[Monster], wild: Monster) -> Battle:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return Battle.new(party, wild, rng)


## Makes the monster know only `move_id`, so a test controls what the foe does.
func _only_move(monster: Monster, move_id: StringName) -> void:
	var move := GameData.move(move_id)
	monster.moves = [move]
	monster.pp = [move.max_pp]


func _index(monster: Monster, move_name: String) -> int:
	return _names(monster.moves).find(move_name)


func _names(moves: Array[MoveData]) -> Array[String]:
	var names: Array[String] = []
	for move in moves:
		names.append(move.display_name)
	return names


## Fraction of 2000 throws that catch, at `hp` HP, with a seeded RNG.
func _catch_rate(battle: Battle, ball: float, hp: int) -> float:
	var target := battle.enemy.monster
	var saved_hp := target.hp
	target.hp = hp
	var caught := 0
	for i in 2000:
		if battle.catch_shakes(target, ball) == 4:
			caught += 1
	target.hp = saved_hp
	return caught / 2000.0


func _count(events: Array[Dictionary], type: StringName) -> int:
	var total := 0
	for event in events:
		if event.type == type:
			total += 1
	return total


func _has_text(events: Array[Dictionary], fragment: String) -> bool:
	for event in events:
		if event.type == &"message" and fragment in event.text:
			return true
	return false


func _used_move(events: Array[Dictionary], user: String) -> bool:
	return _has_text(events, user + " used\n")


## Who acted first this turn, from the first "X used ..." message.
func _first_user(events: Array[Dictionary]) -> String:
	for event in events:
		if event.type == &"message" and " used\n" in event.text:
			return event.text.get_slice(" used\n", 0)
	return ""


func _check(passed: bool, what: String) -> void:
	print("%s  %s" % ["PASS" if passed else "FAIL", what])
	if not passed:
		_failures += 1
