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
	_test_trainer_battles()
	_test_status_conditions()
	_test_trainer_ai()
	_test_items()
	_test_move_effects()
	_test_confusion_and_flinch()
	_test_shift()
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


func _test_trainer_battles() -> void:
	var lass: TrainerData = load("res://data/trainers/lass_mia.tres")
	var team := lass.build_party()
	_check(team.size() == 2 and team[0].species == GameData.species(&"sproutle") and team[1].level == 5, "a trainer's team is built from its data")
	_check(lass.build_party()[0].ivs == team[0].ivs, "...the same way every time")
	var rival: TrainerData = load("res://data/trainers/rival_ren.tres")
	_check(rival.build_party(&"flamlet")[0].species.display_name == "AQUAPUP" and rival.build_party(&"sproutle")[0].species.display_name == "FLAMLET", "the rival picks the starter that beats yours")
	var rival_again: TrainerData = load("res://data/trainers/rival_ren_2.tres")
	_check(rival_again.build_party(&"flamlet")[0].species.display_name == "TIDEHOUND" and rival_again.build_party(&"aquapup")[0].species.display_name == "GROVETLE", "...evolved once its level is high enough")
	_check(lass.defeat_flag() == &"beat_lass_mia" and lass.title() == "LASS MIA", "trainers have a title and a defeat flag")

	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var hero := _monster(&"flamlet", 50)
	_only_move(hero, &"scratch")
	var battle := Battle.against_trainer([hero], lass, team, rng)
	_check(battle.enemy.name == "Foe SPROUTLE", "a trainer's monsters are called Foe")
	var events := battle.take_turn(Battle.run_away())
	_check(_has_text(events, "no running") and not _used_move(events, "Foe SPROUTLE") and battle.turns == 0, "you can't run from a trainer, and trying doesn't cost the turn")
	events = battle.take_turn(Battle.use_item(GameData.item(&"mon_orb")))
	_check(_count(events, &"throw_blocked") == 1 and _has_text(events, "Don't be a thief!") and _count(events, &"caught") == 0, "the trainer blocks thrown orbs")
	_check(_used_move(events, "Foe SPROUTLE") and battle.outcome == Battle.Outcome.ONGOING, "...and the throw still costs the turn")

	team[0].hp = 1
	events = battle.take_turn(Battle.fight(0))
	_check(_count(events, &"faint") == 1 and battle.outcome == Battle.Outcome.ONGOING and battle.foe_must_switch(), "the battle goes on while the trainer has monsters left")
	var sproutle := GameData.species(&"sproutle")
	_check(battle.exp_reward() == floori(sproutle.exp_yield * 4 * 1.5 / 7.0), "a trainer's monsters give 1.5x EXP")
	events = battle.send_next_foe()
	_check(_has_text(events, "LASS MIA sent\nout ZAPKIT!") and _count(events, &"send_out") == 1 and battle.enemy.monster == team[1], "the trainer sends out its next monster")
	_check(not battle.foe_must_switch(), "...and the battle carries on")
	team[1].hp = 1
	battle.take_turn(Battle.fight(0))
	_check(battle.outcome == Battle.Outcome.WON, "beating the last one wins")
	_check(battle.prize_money() == 16 * 5, "prize money is payout x the last monster's level")


func _test_status_conditions() -> void:
	var hero := _monster(&"sproutle", 20)
	_only_move(hero, &"poison_dust")
	var foe := _monster(&"pebblet", 20)
	_only_move(foe, &"harden")
	var battle := _battle([hero], foe)
	var events: Array[Dictionary] = []
	for i in 10: # POISON DUST is 75% accurate.
		events = battle.take_turn(Battle.fight(0))
		if foe.status == &"poison":
			break
	_check(foe.status == &"poison" and _count(events, &"status") == 1 and _has_text(events, "poisoned!"), "POISON DUST poisons the foe")
	var hurt := maxi(1, floori(foe.max_hp() / 8.0))
	_check(_has_text(events, "hurt\nby poison"), "poison hurts at the end of the turn")
	var before := foe.hp
	events = battle.take_turn(Battle.fight(0))
	_check(foe.hp == before - hurt, "poison costs 1/8 of max HP each turn")
	var already := _has_text(events, "already poisoned")
	while not already and battle.outcome == Battle.Outcome.ONGOING:
		already = _has_text(battle.take_turn(Battle.fight(0)), "already poisoned")
	_check(already and foe.status == &"poison", "a monster can't be poisoned twice")

	var flamlet := _monster(&"flamlet", 20)
	var wisp := _battle([_monster(&"shadeling", 20)], flamlet)
	_check(not wisp.inflict(wisp.enemy, &"burn") and flamlet.status.is_empty(), "fire monsters can't be burned")

	var attacker := Battler.new(_monster(&"flamlet", 20), Battle.PLAYER)
	var target := Battler.new(_monster(&"sproutle", 20), Battle.ENEMY)
	var scratch := GameData.move(&"scratch")
	var normal := battle.calculate_damage(attacker, target, scratch, false, 1.0, 100)
	attacker.monster.status = &"burn"
	_check(battle.calculate_damage(attacker, target, scratch, false, 1.0, 100) == floori(normal / 2.0) or battle.calculate_damage(attacker, target, scratch, false, 1.0, 100) <= ceili(normal / 2.0), "a burn halves physical damage")
	var ember := GameData.move(&"ember")
	attacker.monster.status = &""
	var special := battle.calculate_damage(attacker, target, ember, false, 1.0, 100)
	attacker.monster.status = &"burn"
	_check(battle.calculate_damage(attacker, target, ember, false, 1.0, 100) == special, "...but not special damage")

	var runner := Battler.new(_monster(&"zapkit", 30), Battle.PLAYER)
	var fast := runner.stat(&"speed")
	runner.monster.status = &"paralysis"
	_check(runner.stat(&"speed") == floori(fast / 4.0), "paralysis quarters SPEED")
	var stuck := 0
	for i in 400:
		if not battle._can_act(runner):
			stuck += 1
	_check(stuck > 70 and stuck < 130, "paralysis stops about 1 turn in 4 (%d of 400)" % stuck)

	var sleeper := _monster(&"aquapup", 20)
	_only_move(sleeper, &"tackle")
	var dozer := _monster(&"pebblet", 20)
	_only_move(dozer, &"harden")
	battle = _battle([sleeper], dozer)
	battle.inflict(battle.player, &"sleep")
	_check(sleeper.status == &"sleep" and sleeper.sleep_turns >= 2 and sleeper.sleep_turns <= 5, "sleep lasts 2 to 5 turns")
	events = battle.take_turn(Battle.fight(0))
	_check(_has_text(events, "fast asleep") and not _used_move(events, "AQUAPUP"), "a sleeping monster can't move")
	var woke := false
	for i in 5:
		events = battle.take_turn(Battle.fight(0))
		if _has_text(events, "woke up!"):
			woke = _used_move(events, "AQUAPUP") and sleeper.status.is_empty()
			break
	_check(woke, "...then wakes up and acts that turn")

	var ice := _monster(&"sproutle", 20)
	ice.status = &"freeze"
	var torch := _monster(&"flamlet", 20)
	_only_move(torch, &"ember")
	battle = _battle([torch], ice)
	_only_move(ice, &"harden")
	events = battle.take_turn(Battle.fight(0))
	_check(ice.status.is_empty() or ice.is_fainted(), "fire thaws a frozen monster")

	var poisoned := _monster(&"sproutle", 5)
	poisoned.status = &"poison"
	battle = _battle([_monster(&"flamlet", 50)], poisoned)
	poisoned.hp = 1
	battle.take_turn(Battle.fight(0))
	_check(poisoned.is_fainted() and poisoned.status.is_empty(), "fainting clears a status")

	var patient := _monster(&"flamlet", 10)
	patient.status = &"burn"
	_only_move(patient, &"growl")
	battle = _battle([patient], _monster(&"pebblet", 5))
	_only_move(battle.enemy.monster, &"harden")
	events = battle.take_turn(Battle.use_item(GameData.item(&"antidote")))
	_check(patient.status == &"burn" and _has_text(events, "no effect"), "an ANTIDOTE doesn't heal a burn")
	events = battle.take_turn(Battle.use_item(GameData.item(&"full_heal")))
	_check(patient.status.is_empty() and _has_text(events, "burn\nwas healed"), "a FULL HEAL cures anything")
	_check(GameData.item(&"awakening").cures_status(&"sleep") and not GameData.item(&"awakening").cures_status(&"poison"), "each cure knows what it cures")

	battle = _battle([_monster(&"flamlet", 5)], _monster(&"sproutle", 3))
	var awake_rate := _catch_rate(battle, 1.0, 1)
	battle.enemy.monster.status = &"sleep"
	_check(_catch_rate(battle, 1.0, 1) > awake_rate, "sleeping monsters are easier to catch")

	var carried := _monster(&"sproutle", 10)
	carried.status = &"paralysis"
	carried.heal_full()
	_check(carried.status.is_empty(), "healing (MOM, the MONSTER CENTER) clears a status")


func _test_trainer_ai() -> void:
	var lass: TrainerData = load("res://data/trainers/lass_mia.tres")
	var hero := _monster(&"aquapup", 10)
	hero.status = &"poison"
	var foe := _monster(&"sproutle", 10)
	foe.moves.assign([GameData.move(&"poison_dust"), GameData.move(&"tackle")])
	foe.pp = [35, 35]
	var team: Array[Monster] = [foe]
	var battle := Battle.against_trainer([hero], lass, team)
	_check(battle.move_score(battle.enemy, battle.player, GameData.move(&"poison_dust")) == 0.0, "trainer AI sees a status move would fail")
	var picks := {}
	for i in 30:
		picks[battle._enemy_move().display_name] = true
	_check(picks.keys() == ["TACKLE"], "...and never wastes a turn on it")
	foe.moves.assign([GameData.move(&"tackle"), GameData.move(&"vine_whip")])
	hero.status = &""
	var vine := 0
	for i in 200:
		if battle._enemy_move().display_name == "VINE WHIP":
			vine += 1
	_check(vine > 140, "trainer AI favors super effective moves (%d of 200)" % vine)


func _test_items() -> void:
	var battle := _battle([_monster(&"flamlet", 5)], _monster(&"sproutle", 3))
	_only_move(battle.enemy.monster, &"growl")
	battle.player.monster.hp -= 10
	var events := battle.take_turn(Battle.use_item(GameData.item(&"potion")))
	_check(battle.player.monster.hp == battle.player.monster.max_hp(), "POTION heals up to its amount")
	_check(_has_text(events, "restored by 10 points"), "POTION reports how much it healed")

	var team: Array[Monster] = [_monster(&"flamlet", 10), _monster(&"aquapup", 10)]
	battle = _battle(team, _monster(&"sproutle", 3))
	_only_move(battle.enemy.monster, &"growl")
	var bench := team[1]
	bench.hp -= 10
	events = battle.take_turn(Battle.use_item(GameData.item(&"potion"), 1))
	_check(bench.hp == bench.max_hp() and _has_text(events, "AQUAPUP's HP"), "items can be used on a monster that isn't battling")
	bench.hp = 0
	events = battle.take_turn(Battle.use_item(GameData.item(&"revive"), 1))
	_check(bench.hp == floori(bench.max_hp() / 2.0) and _has_text(events, "back on"), "REVIVE brings a fainted monster back with half its HP")
	events = battle.take_turn(Battle.use_item(GameData.item(&"revive"), 1))
	_check(_has_text(events, "no effect"), "...and does nothing for one that hasn't fainted")
	var lead := team[0]
	lead.pp[0] = 0
	events = battle.take_turn(Battle.use_item(GameData.item(&"ether"), 0, 0))
	_check(lead.pp[0] == mini(10, lead.moves[0].max_pp) and _has_text(events, "PP"), "ETHER restores 10 PP to the chosen move")
	var max_revive := GameData.item(&"max_revive")
	bench.hp = 0
	_check(max_revive.can_use_on(bench) and not max_revive.can_use_on(lead), "MAX REVIVE only works on fainted monsters")
	max_revive.use_on(bench)
	_check(bench.hp == bench.max_hp(), "...and restores all of their HP")
	_check(not GameData.item(&"repel").targets_monster() and GameData.item(&"repel").repel_steps == 100, "a REPEL lasts 100 steps and isn't used on a monster")


func _test_move_effects() -> void:
	var drainer := _monster(&"zapkit", 26) # Not SPROUTLE: its SUNSOAK would heal it too.
	_only_move(drainer, &"giga_drain")
	drainer.hp -= 30
	var battle := _battle([drainer], _monster(&"aquapup", 20))
	_only_move(battle.enemy.monster, &"growl")
	var hp_before := drainer.hp
	var foe_before := battle.enemy.monster.hp
	var events := battle.take_turn(Battle.fight(0))
	var dealt := foe_before - battle.enemy.monster.hp
	_check(drainer.hp == mini(hp_before + maxi(1, floori(dealt / 2.0)), drainer.max_hp()) and _has_text(events, "energy drained"), "GIGA DRAIN heals half the damage it deals")

	var charger := _monster(&"pebblet", 30)
	_only_move(charger, &"take_down")
	battle = _battle([charger], _monster(&"bouldron", 40))
	_only_move(battle.enemy.monster, &"harden")
	for i in 10: # TAKE DOWN is 85% accurate.
		foe_before = battle.enemy.monster.hp
		hp_before = charger.hp
		events = battle.take_turn(Battle.fight(0))
		if _has_text(events, "recoil"):
			break
	dealt = foe_before - battle.enemy.monster.hp
	_check(charger.hp == hp_before - maxi(1, floori(dealt / 4.0)), "TAKE DOWN costs the user a quarter of the damage")
	charger.hp = 1
	charger.pp[0] = 20
	for i in 10:
		events = battle.take_turn(Battle.fight(0))
		if battle.outcome != Battle.Outcome.ONGOING:
			break
	_check(charger.is_fainted() and battle.outcome == Battle.Outcome.LOST, "recoil can make the user faint")

	var healer := _monster(&"zapkit", 25)
	_only_move(healer, &"synthesis")
	battle = _battle([healer], _monster(&"pebblet", 5))
	_only_move(battle.enemy.monster, &"harden")
	healer.hp = 10
	battle.take_turn(Battle.fight(0))
	_check(healer.hp == mini(10 + ceili(healer.max_hp() / 2.0), healer.max_hp()), "SYNTHESIS restores half of max HP")
	healer.hp = healer.max_hp()
	events = battle.take_turn(Battle.fight(0))
	_check(_has_text(events, "HP is full"), "...and fails at full HP")
	_check(battle.move_score(battle.player, battle.enemy, GameData.move(&"synthesis")) == 0.0, "trainer AI doesn't heal at full HP")
	healer.hp = 5
	_check(battle.move_score(battle.player, battle.enemy, GameData.move(&"synthesis")) > 90.0, "...but wants to when nearly out of HP")
	_check(GameData.move(&"rock_slide").flinch_chance == 30 and GameData.move(&"headbutt").flinch_chance == 30, "ROCK SLIDE and HEADBUTT may make the foe flinch")


func _test_confusion_and_flinch() -> void:
	var confuser := _monster(&"shadeling", 20)
	_only_move(confuser, &"dizzy_ray")
	var battle := _battle([confuser], _monster(&"pebblet", 20))
	_only_move(battle.enemy.monster, &"harden")
	var events := battle.take_turn(Battle.fight(0))
	_check(battle.enemy.confused_turns >= 1 and battle.enemy.confused_turns <= 5 and _has_text(events, "became\nconfused"), "DIZZY RAY confuses the foe")
	battle.enemy.confused_turns = 5
	events = battle.take_turn(Battle.fight(0))
	_check(_has_text(events, "already confused"), "...but not twice")
	var self_hits := 0
	var lost_turn := true
	for i in 40:
		battle.enemy.confused_turns = 5
		battle.enemy.monster.hp = battle.enemy.monster.max_hp()
		events = battle.take_turn(Battle.fight(0))
		if _has_text(events, "hurt itself"):
			self_hits += 1
			lost_turn = lost_turn and not _used_move(events, "Wild PEBBLET")
	_check(self_hits > 8 and self_hits < 32, "a confused monster hurts itself about half the time (%d of 40)" % self_hits)
	_check(lost_turn, "...and loses its move when it does")
	battle.enemy.confused_turns = 1
	events = battle.take_turn(Battle.fight(0))
	_check(_has_text(events, "snapped") and _used_move(events, "Wild PEBBLET") and battle.enemy.confused_turns == 0, "confusion wears off and the monster acts again")

	var butter := _monster(&"zapkit", 30)
	var always_flinch: MoveData = GameData.move(&"headbutt").duplicate()
	always_flinch.flinch_chance = 100
	butter.moves.assign([always_flinch, GameData.move(&"growl")])
	butter.pp = [15, 40]
	battle = _battle([butter], _monster(&"bouldron", 30))
	_only_move(battle.enemy.monster, &"harden")
	events = battle.take_turn(Battle.fight(0))
	_check(_has_text(events, "flinched") and not _used_move(events, "Wild BOULDRON"), "a faster hit can make the foe flinch and lose its move")
	events = battle.take_turn(Battle.fight(1))
	_check(_used_move(events, "Wild BOULDRON") and not battle.enemy.flinched, "...for that turn only")
	var slowpoke := _monster(&"pebblet", 5)
	slowpoke.moves.assign([always_flinch])
	slowpoke.pp = [15]
	battle = _battle([slowpoke], _monster(&"zapkit", 30))
	_only_move(battle.enemy.monster, &"growl")
	battle.take_turn(Battle.fight(0))
	events = battle.take_turn(Battle.fight(0))
	_check(not _has_text(events, "flinched"), "a slower monster's hit can't cause a flinch")
	_check(battle.move_score(battle.enemy, battle.player, GameData.move(&"supersonic")) > 0.0, "trainer AI likes confusing a foe...")
	battle.player.confused_turns = 3
	_check(battle.move_score(battle.enemy, battle.player, GameData.move(&"supersonic")) == 0.0, "...unless it's already confused")


func _test_shift() -> void:
	var lass: TrainerData = load("res://data/trainers/lass_mia.tres")
	var team: Array[Monster] = [_monster(&"blazard", 40), _monster(&"tidehound", 40)]
	var foes: Array[Monster] = [_monster(&"sproutle", 3), _monster(&"zapkit", 3)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var battle := Battle.against_trainer(team, lass, foes, rng)
	_only_move(team[0], &"ember")
	battle.take_turn(Battle.fight(0))
	_check(battle.foe_must_switch() and battle.next_foe() == foes[1] and battle.can_shift(), "before the next foe comes out, you may switch")
	var events := battle.shift_to(1)
	_check(battle.player.monster == team[1] and _count(events, &"withdraw") == 1 and _count(events, &"send_out") == 1, "...which swaps your monster in")
	_check(not _has_text(events, "used"), "...without the foe getting a free hit")
	events = battle.send_next_foe()
	_check(battle.enemy.monster == foes[1], "then the trainer sends out the next one")
	team[0].hp = 0
	_check(not battle.can_shift(), "no switch is offered when nobody else can fight")


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
