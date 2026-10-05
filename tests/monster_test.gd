extends SceneTree
## Rule tests for individual monsters: growth rates, IVs, natures and
## evolution. No scenes.
##   godot --headless --path . --script res://tests/monster_test.gd
## Exits with code 0 when every check passes, 1 otherwise.

var _failures := 0


func _initialize() -> void:
	_test_growth_rates()
	_test_ivs_and_natures()
	_test_evolution()
	print("\nMONSTER TEST %s (%d failed)" % ["PASSED" if _failures == 0 else "FAILED", _failures])
	quit(1 if _failures > 0 else 0)


func _test_growth_rates() -> void:
	var species := GameData.species(&"flamlet").duplicate() as MonsterSpecies
	var totals := {}
	for growth in MonsterSpecies.Growth.values():
		species.growth = growth
		totals[growth] = species.exp_for_level(100)
	_check(totals == {0: 800000, 1: 1000000, 2: 1059860, 3: 1250000}, "growth rates match Gen 3 at level 100")
	species.growth = MonsterSpecies.Growth.MEDIUM_SLOW
	_check(species.exp_for_level(1) == 0 and species.exp_for_level(5) == 135, "medium slow starts at 0 and needs 135 EXP for level 5")
	var zapkit := Monster.create(GameData.species(&"zapkit"), 10)
	var flamlet := Monster.create(GameData.species(&"flamlet"), 10)
	_check(zapkit.experience == 1000 and flamlet.experience == 560, "each species levels on its own curve")
	flamlet.gain_exp(flamlet.exp_to_next_level())
	_check(flamlet.level == 11 and flamlet.experience == flamlet.exp_for_level(11), "gaining exactly enough EXP levels up once")


func _test_ivs_and_natures() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var highest := 0
	var natures := {}
	for i in 200:
		var monster := Monster.create(GameData.species(&"sproutle"), 5, rng)
		natures[monster.nature] = true
		for stat in Monster.STATS:
			highest = maxi(highest, monster.ivs[stat])
			if monster.ivs[stat] < 0 or monster.ivs[stat] > Monster.MAX_IV:
				highest = 99
	_check(highest == 31, "IVs range from 0 to 31")
	_check(natures.size() == Monster.NATURES.size(), "all %d natures turn up" % Monster.NATURES.size())

	var plain := _monster(&"flamlet", 50, &"HARDY")
	var adamant := _monster(&"flamlet", 50, &"ADAMANT")
	_check(adamant.stat(&"attack") == plain.stat(&"attack") * 11 / 10, "ADAMANT raises ATTACK by 10%")
	_check(adamant.stat(&"special") == plain.stat(&"special") * 9 / 10, "...and lowers SPECIAL by 10%")
	_check(adamant.stat(&"speed") == plain.stat(&"speed") and adamant.max_hp() == plain.max_hp(), "...and leaves the rest alone")
	var bashful := _monster(&"flamlet", 50, &"BASHFUL")
	_check(bashful.stat(&"special") == plain.stat(&"special"), "natures that raise and lower the same stat are neutral")


func _test_evolution() -> void:
	var flamlet := _monster(&"flamlet", 11, &"BOLD")
	_check(flamlet.evolution_by_level() == null, "FLAMLET doesn't evolve before level 12")
	flamlet.level = 12
	var into := flamlet.evolution_by_level()
	_check(into == GameData.species(&"blazard"), "FLAMLET evolves into BLAZARD at level 12")
	flamlet.hp = flamlet.max_hp() - 5
	var old_max := flamlet.max_hp()
	var old_moves := flamlet.moves.duplicate()
	var ivs := flamlet.ivs.duplicate()
	flamlet.evolve(into)
	_check(flamlet.species == into and flamlet.level == 12 and flamlet.nature == &"BOLD", "evolving keeps the level and nature")
	_check(flamlet.ivs == ivs and flamlet.moves == old_moves, "...and the IVs and moves")
	_check(flamlet.max_hp() > old_max and flamlet.hp == flamlet.max_hp() - 5, "max HP grows and the damage taken stays")
	_check(flamlet.get_display_name() == "BLAZARD", "an un-nicknamed monster takes the new name")

	var zapkit := _monster(&"zapkit", 5, &"HARDY")
	_check(zapkit.evolution_by_level() == null, "ZAPKIT doesn't evolve by level")
	_check(zapkit.evolution_by_item(&"bolt_stone") == GameData.species(&"voltvix"), "a BOLT STONE evolves ZAPKIT into VOLTVIX")
	_check(zapkit.evolution_by_item(&"dusk_stone") == null, "the wrong stone does nothing")

	var shared_growth := true
	for species in GameData.all_species():
		for evolution in species.evolutions:
			shared_growth = shared_growth and evolution.into.growth == species.growth
	_check(shared_growth, "every evolution shares its pre-evolution's growth rate")


# --- Helpers -------------------------------------------------------------------

func _monster(id: StringName, level: int, nature: StringName) -> Monster:
	var monster := Monster.create(GameData.species(id), level)
	monster.nature = nature
	for stat in Monster.STATS:
		monster.ivs[stat] = 15
	monster.hp = monster.max_hp()
	return monster


func _check(passed: bool, what: String) -> void:
	print("%s  %s" % ["PASS" if passed else "FAIL", what])
	if not passed:
		_failures += 1
