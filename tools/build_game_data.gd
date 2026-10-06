extends SceneTree
## Writes the starter game data (moves, abilities, species, items, trainers) to
## res://data/ as .tres files you can then tweak in the inspector.
##
## Usually run through tools/rebuild_placeholders.sh (it needs the monster PNGs
## to be imported first). To run it alone:
##   godot --headless --path . --script res://tools/build_game_data.gd
##
## Existing files are kept so inspector edits are safe. Pass `-- --force` to
## rewrite them all from the tables below.

const MOVE_DIR := "res://data/moves/"
const ABILITY_DIR := "res://data/abilities/"
const SPECIES_DIR := "res://data/species/"
const ITEM_DIR := "res://data/items/"
const SPRITE_DIR := "res://assets/placeholder/monsters/"
const ITEM_SPRITE_DIR := "res://assets/placeholder/items/"
const TRAINER_DIR := "res://data/trainers/"
const TRAINER_SPRITE_DIR := "res://assets/placeholder/trainers/"
const ABILITY_SCRIPT_DIR := "res://scripts/monsters/abilities/"

const PHYSICAL := MoveData.Category.PHYSICAL
const SPECIAL := MoveData.Category.SPECIAL
const STATUS := MoveData.Category.STATUS
const FOE := MoveData.Target.FOE
const SELF := MoveData.Target.SELF

## id: [name, element, category, power, accuracy, pp, priority, stat changes, target, effect %, description]
const MOVES := {
	"tackle": ["TACKLE", "normal", PHYSICAL, 40, 100, 35, 0, {}, FOE, 0, "A full-body charge."],
	"scratch": ["SCRATCH", "normal", PHYSICAL, 40, 100, 35, 0, {}, FOE, 0, "Rakes the foe with sharp claws."],
	"quick_hit": ["QUICK HIT", "normal", PHYSICAL, 40, 100, 30, 1, {}, FOE, 0, "So fast it always strikes first."],
	"growl": ["GROWL", "normal", STATUS, 0, 100, 40, 0, {&"attack": -1}, FOE, 100, "Lowers the foe's ATTACK."],
	"leer": ["LEER", "normal", STATUS, 0, 100, 30, 0, {&"defense": -1}, FOE, 100, "Lowers the foe's DEFENSE."],
	"harden": ["HARDEN", "normal", STATUS, 0, 100, 30, 0, {&"defense": 1}, SELF, 100, "Raises the user's DEFENSE."],
	"scary_face": ["SCARY FACE", "normal", STATUS, 0, 90, 10, 0, {&"speed": -2}, FOE, 100, "Sharply lowers the foe's SPEED."],
	"ember": ["EMBER", "fire", SPECIAL, 40, 100, 25, 0, {}, FOE, 0, "Small flames that may burn.", ["burn", 10]],
	"flame_dash": ["FLAME DASH", "fire", PHYSICAL, 60, 95, 20, 0, {}, FOE, 0, "A fiery charge that may burn.", ["burn", 10]],
	"water_gun": ["WATER GUN", "water", SPECIAL, 40, 100, 25, 0, {}, FOE, 0, "Squirts water at the foe."],
	"bubblebeam": ["BUBBLEBEAM", "water", SPECIAL, 65, 100, 20, 0, {&"speed": -1}, FOE, 10, "May lower the foe's SPEED."],
	"vine_whip": ["VINE WHIP", "grass", PHYSICAL, 45, 100, 25, 0, {}, FOE, 0, "Strikes with slender vines."],
	"razor_leaf": ["RAZOR LEAF", "grass", SPECIAL, 55, 95, 25, 0, {}, FOE, 0, "Launches sharp-edged leaves."],
	"rock_throw": ["ROCK THROW", "rock", PHYSICAL, 50, 90, 15, 0, {}, FOE, 0, "Hurls a small rock."],
	"spark": ["SPARK", "electric", SPECIAL, 40, 100, 30, 0, {}, FOE, 0, "A jolt that may paralyze.", ["paralysis", 30]],
	"volt_dash": ["VOLT DASH", "electric", PHYSICAL, 65, 95, 15, 0, {}, FOE, 0, "A crackling tackle; may paralyze.", ["paralysis", 10]],
	"lick": ["LICK", "ghost", PHYSICAL, 30, 100, 30, 0, {}, FOE, 0, "An eerie lick that may paralyze.", ["paralysis", 30]],
	"shade_orb": ["SHADE ORB", "ghost", SPECIAL, 60, 100, 15, 0, {&"special": -1}, FOE, 20, "May lower the foe's SPECIAL."],
	"heat_wave": ["HEAT WAVE", "fire", SPECIAL, 90, 90, 10, 0, {}, FOE, 0, "Scorching air that may burn.", ["burn", 10]],
	"aqua_blast": ["AQUA BLAST", "water", SPECIAL, 90, 90, 10, 0, {}, FOE, 0, "A crashing jet of seawater."],
	"leaf_storm": ["LEAF STORM", "grass", SPECIAL, 90, 90, 10, 0, {}, FOE, 0, "A whirlwind of razor leaves."],
	"rock_slide": ["ROCK SLIDE", "rock", PHYSICAL, 75, 90, 10, 0, {}, FOE, 0, "Buries the foe under boulders."],
	"thunder": ["THUNDER", "electric", SPECIAL, 110, 70, 10, 0, {}, FOE, 0, "A huge, wild bolt; may paralyze.", ["paralysis", 30]],
	"phantasm": ["PHANTASM", "ghost", SPECIAL, 85, 100, 10, 0, {&"attack": -1}, FOE, 20, "May lower the foe's ATTACK."],
	"gust": ["GUST", "normal", SPECIAL, 40, 100, 35, 0, {}, FOE, 0, "Whips up a strong gust of wind."],
	"wing_slash": ["WING SLASH", "normal", PHYSICAL, 60, 100, 25, 0, {}, FOE, 0, "Strikes with wings spread wide."],
	"aerial_dive": ["AERIAL DIVE", "normal", PHYSICAL, 90, 90, 10, 0, {}, FOE, 0, "Soars up high, then dives at the foe."],
	# Status moves: the last entry is [status condition, chance].
	"poison_dust": ["POISON DUST", "grass", STATUS, 0, 75, 35, 0, {}, FOE, 0, "Scatters a toxic dust that poisons.", ["poison", 100]],
	"sleep_dust": ["SLEEP DUST", "grass", STATUS, 0, 75, 15, 0, {}, FOE, 0, "Scatters a dust that causes sleep.", ["sleep", 100]],
	"volt_wave": ["VOLT WAVE", "electric", STATUS, 0, 100, 20, 0, {}, FOE, 0, "A weak jolt that paralyzes.", ["paralysis", 100]],
	"hypnosis": ["HYPNOSIS", "normal", STATUS, 0, 60, 20, 0, {}, FOE, 0, "A hypnotic gaze that causes sleep.", ["sleep", 100]],
	"wisp_fire": ["WISP FIRE", "fire", STATUS, 0, 75, 15, 0, {}, FOE, 0, "Ghostly flames that burn.", ["burn", 100]],
	"struggle": ["STRUGGLE", "normal", PHYSICAL, 50, 100, 1, 0, {}, FOE, 0, "Used only when no move has PP left."],
}

## id: [script file, name, description, {property: value}]
const ABILITIES := {
	"kindle": ["element_boost_ability.gd", "KINDLE", "Powers up fire moves when HP is low.", {"element": "fire", "hp_threshold": 0.34, "multiplier": 1.5}],
	"soak_up": ["absorb_element_ability.gd", "SOAK UP", "Water moves heal it instead of hurting it.", {"element": "water", "heal_fraction": 0.25}],
	"sunsoak": ["regenerate_ability.gd", "SUNSOAK", "Restores a little HP at the end of every turn.", {"heal_fraction": 0.0625}],
	"sturdy_shell": ["endure_ability.gd", "STURDY SHELL", "Survives any hit taken at full HP.", {}],
	"jolt": ["stat_on_hit_ability.gd", "JOLT", "When hit, may lower the attacker's SPEED.", {"chance": 0.3, "stat": "speed", "stages": -1}],
	"dread": ["stat_on_enter_ability.gd", "DREAD", "Lowers the foe's ATTACK on entering battle.", {"stat": "attack", "stages": -1}],
	"gale_force": ["stat_on_enter_ability.gd", "GALE FORCE", "Buffets the foe on entering battle, lowering its SPEED.", {"stat": "speed", "stages": -1}],
}

## id: [name, element, ability, [hp, attack, defense, special, speed], catch rate, exp yield, learnset, dex entry]
## In MONDEX order: each evolution right after its pre-evolution.
const SPECIES := {
	"flamlet": ["FLAMLET", "fire", "kindle", [39, 52, 43, 55, 65], 45, 62,
		[[1, "scratch"], [1, "growl"], [7, "ember"], [13, "leer"], [19, "flame_dash"]],
		"Its tail-flame flickers brighter whenever it is excited."],
	"blazard": ["BLAZARD", "fire", "kindle", [58, 72, 58, 75, 80], 45, 142,
		[[1, "scratch"], [1, "growl"], [7, "ember"], [13, "leer"], [19, "flame_dash"], [28, "heat_wave"]],
		"Its horns glow white-hot when it battles a worthy foe."],
	"aquapup": ["AQUAPUP", "water", "soak_up", [44, 48, 65, 50, 43], 45, 63,
		[[1, "tackle"], [1, "growl"], [7, "water_gun"], [13, "harden"], [19, "bubblebeam"]],
		"Splashes through puddles for hours and never seems to get cold."],
	"tidehound": ["TIDEHOUND", "water", "soak_up", [62, 66, 82, 68, 60], 45, 143,
		[[1, "tackle"], [1, "growl"], [7, "water_gun"], [13, "harden"], [19, "bubblebeam"], [28, "aqua_blast"]],
		"Rides the waves along the coast, its fin crest cutting the spray."],
	"sproutle": ["SPROUTLE", "grass", "sunsoak", [45, 49, 49, 65, 45], 190, 50,
		[[1, "tackle"], [3, "growl"], [7, "vine_whip"], [10, "poison_dust"], [15, "razor_leaf"], [20, "sleep_dust"]],
		"Naps in sunny patches of tall grass, soaking up light through its leaves."],
	"grovetle": ["GROVETLE", "grass", "sunsoak", [62, 64, 72, 82, 55], 45, 141,
		[[1, "tackle"], [3, "growl"], [7, "vine_whip"], [10, "poison_dust"], [15, "razor_leaf"], [20, "sleep_dust"], [30, "leaf_storm"]],
		"A small tree takes root on its back. Birds nest in its branches."],
	"pebblet": ["PEBBLET", "rock", "sturdy_shell", [40, 80, 100, 30, 20], 190, 60,
		[[1, "tackle"], [1, "harden"], [8, "rock_throw"], [16, "scary_face"]],
		"Often mistaken for an ordinary rock, until it rolls away."],
	"bouldron": ["BOULDRON", "rock", "sturdy_shell", [60, 100, 125, 45, 35], 45, 137,
		[[1, "tackle"], [1, "harden"], [8, "rock_throw"], [16, "scary_face"], [24, "rock_slide"]],
		"Crystals grow from its shoulders. It can sleep standing up for years."],
	"zapkit": ["ZAPKIT", "electric", "jolt", [35, 55, 30, 50, 90], 190, 56,
		[[1, "quick_hit"], [1, "growl"], [6, "spark"], [10, "volt_wave"], [14, "volt_dash"]],
		"Its ears crackle with static. Touching them makes your hair stand up."],
	"voltvix": ["VOLTVIX", "electric", "jolt", [60, 85, 55, 85, 115], 45, 160,
		[[1, "quick_hit"], [1, "growl"], [6, "spark"], [10, "volt_wave"], [14, "volt_dash"], [26, "thunder"]],
		"Its mane crackles with lightning. It can outrun a thunderclap."],
	"shadeling": ["SHADELING", "ghost", "dread", [30, 35, 30, 100, 80], 120, 62,
		[[1, "lick"], [1, "scary_face"], [8, "shade_orb"], [12, "hypnosis"], [18, "wisp_fire"]],
		"Lurks in the shadows of old houses and giggles at night."],
	"duskwraith": ["DUSKWRAITH", "ghost", "dread", [55, 60, 50, 125, 105], 45, 160,
		[[1, "lick"], [1, "scary_face"], [8, "shade_orb"], [12, "hypnosis"], [18, "wisp_fire"], [24, "phantasm"]],
		"Drifts through town at dusk, grinning at anyone still outside."],
	"pipwing": ["PIPWING", "normal", "gale_force", [40, 45, 40, 35, 56], 255, 50,
		[[1, "tackle"], [1, "growl"], [5, "quick_hit"], [9, "gust"], [13, "leer"], [17, "wing_slash"]],
		"Flocks of PIPWING chase the sea breeze, chirping loudly at dawn."],
	"galehawk": ["GALEHAWK", "normal", "gale_force", [63, 72, 60, 52, 91], 45, 145,
		[[1, "tackle"], [1, "growl"], [5, "quick_hit"], [9, "gust"], [13, "leer"], [17, "wing_slash"], [28, "aerial_dive"]],
		"It rides storm winds above the clouds, then dives faster than the eye can follow."],
}

const BY_LEVEL := Evolution.Method.LEVEL
const BY_ITEM := Evolution.Method.ITEM
## Pre-evolution id: [evolved id, BY_LEVEL or BY_ITEM, level or item id].
const EVOLUTIONS := {
	"flamlet": ["blazard", BY_LEVEL, 12],
	"aquapup": ["tidehound", BY_LEVEL, 12],
	"sproutle": ["grovetle", BY_LEVEL, 12],
	"pebblet": ["bouldron", BY_LEVEL, 14],
	"zapkit": ["voltvix", BY_ITEM, "bolt_stone"],
	"shadeling": ["duskwraith", BY_ITEM, "dusk_stone"],
	"pipwing": ["galehawk", BY_LEVEL, 18],
}

const BALL := ItemData.Kind.BALL
const HEAL := ItemData.Kind.HEAL
const EVOLUTION := ItemData.Kind.EVOLUTION
const CURE := ItemData.Kind.CURE

## id: [name, kind, catch multiplier or heal amount, price (0 = not sold),
##      description, optional extra properties]
## The orbs follow Gen 3's balls: MON/SUPER/HYPER/MASTER are Poke/Great/Ultra/
## Master, then Net, Dive, Nest, Repeat and Timer, and GALA is the Premier
## Ball (a free bonus for buying 10 MON ORBs at once).
const ITEMS := {
	"mon_orb": ["MON ORB", BALL, 1.0, 200, "A device for catching\nwild MONSTERS."],
	"super_orb": ["SUPER ORB", BALL, 1.5, 600, "A good orb with a\nhigher catch rate\nthan a MON ORB."],
	"hyper_orb": ["HYPER ORB", BALL, 2.0, 1200, "A high-performance\norb. Better than a\nSUPER ORB."],
	"master_orb": ["MASTER ORB", BALL, 255.0, 0, "Catches any wild\nMONSTER without fail."],
	"net_orb": ["NET ORB", BALL, 1.0, 1000, "Works especially well\non WATER MONSTERS.",
		{"bonus": ItemData.Bonus.ELEMENT, "bonus_multiplier": 3.0, "bonus_elements": [&"water"]}],
	"dive_orb": ["DIVE ORB", BALL, 1.0, 1000, "Works especially well\non MONSTERS met in\nthe water.",
		{"bonus": ItemData.Bonus.IN_WATER, "bonus_multiplier": 3.5}],
	"nest_orb": ["NEST ORB", BALL, 1.0, 1000, "Works better the\nlower the wild\nMONSTER's level.",
		{"bonus": ItemData.Bonus.LOW_LEVEL}],
	"repeat_orb": ["REPEAT ORB", BALL, 1.0, 1000, "Works especially well\non kinds of MONSTER\nyou've caught before.",
		{"bonus": ItemData.Bonus.REPEAT, "bonus_multiplier": 3.0}],
	"timer_orb": ["TIMER ORB", BALL, 1.0, 1000, "Works better the\nlonger the battle\ngoes on.",
		{"bonus": ItemData.Bonus.TIMER}],
	"gala_orb": ["GALA ORB", BALL, 1.0, 200, "A rare orb made to\ncelebrate a MART\nopening."],
	"potion": ["POTION", HEAL, 20, 300, "Restores 20 HP to\none MONSTER."],
	"big_potion": ["BIG POTION", HEAL, 50, 700, "Restores 50 HP to\none MONSTER."],
	"antidote": ["ANTIDOTE", CURE, 0, 100, "Cures a poisoned\nMONSTER.", {"cures": [&"poison"]}],
	"burn_heal": ["BURN HEAL", CURE, 0, 250, "Heals a MONSTER's\nburn.", {"cures": [&"burn"]}],
	"para_heal": ["PARA HEAL", CURE, 0, 200, "Cures a paralyzed\nMONSTER.", {"cures": [&"paralysis"]}],
	"awakening": ["AWAKENING", CURE, 0, 250, "Wakes up a sleeping\nMONSTER.", {"cures": [&"sleep"]}],
	"full_heal": ["FULL HEAL", CURE, 0, 600, "Cures any status\ncondition.", {"cures": []}],
	"bolt_stone": ["BOLT STONE", EVOLUTION, 0, 2100, "Makes certain MONSTERS\nevolve. It crackles\nwith static."],
	"dusk_stone": ["DUSK STONE", EVOLUTION, 0, 2100, "Makes certain MONSTERS\nevolve. It's cold to\nthe touch."],
}

## id: [class, name, battle sprite, payout, team as [species, level]...,
##      intro (on the map), defeat (in battle), after (on the map once beaten),
##      optional extra properties]
## Prize money is payout x the last monster's level. "{PLAYER}" in a line
## becomes the player's name.
const TRAINERS := {
	"lass_mia": ["LASS", "MIA", "lass", 16, [["sproutle", 4], ["zapkit", 5]],
		["Oh! Did you just get\nyour first MONSTER?", "Mine are super cute.\nLet's battle!"],
		["Aww... You won fair\nand square."],
		["GRASS types like my\nSPROUTLE soak up the\nsun on this route."]],
	"youngster_tim": ["YOUNGSTER", "TIM", "youngster", 16, [["zapkit", 4], ["pebblet", 6]],
		["Hey! Our eyes met!\nThat means we have to\nbattle!"],
		["What?! My PEBBLET is\nsupposed to be tough!"],
		["I'll train in the tall\ngrass until my team\ngets stronger!"]],
	"rival_ren": ["RIVAL", "REN", "rival", 60, [["flamlet", 5]],
		["REN: Hey, {PLAYER}! You got\na MONSTER from PROF.\nASTER too?", "I picked mine to beat\nyours. Let's battle!"],
		["Whoa... You're really\ngood!"],
		["REN: I'm off to\nTIDEWATER to catch more\nMONSTERS.", "Next time, I'll win!"],
		{"counters_starter": true}],
	"swimmer_luca": ["SWIMMER", "LUCA", "swimmer", 16, [["aquapup", 9], ["zapkit", 9]],
		["Splash! You want to\nsee our LEADER? Get\npast me first!"],
		["I got swept away..."],
		["MARINA can read the\ntides like a book."]],
	"swimmer_nia": ["SWIMMER", "NIA", "swimmer", 16, [["shadeling", 10], ["aquapup", 11]],
		["The pool's deeper than\nit looks. So am I!"],
		["Glub... I sank."],
		["GRASS and ELECTRIC moves\ncut right through WATER\nMONSTERS."]],
	"leader_marina": ["LEADER", "MARINA", "leader", 100, [["aquapup", 11], ["pebblet", 12], ["tidehound", 14]],
		["MARINA: Welcome to the\nTIDEWATER GYM!", "The sea is calm one\nmoment and wild the\nnext. So am I.", "Show me your strength!"],
		["The tide has turned...\nYou win!"],
		["MARINA: SURF across the\nriver on ROUTE 2 to\nreach COPPERDALE TOWN.", "Its GYM LEADER, CORA,\nis simply electrifying!"],
		{"music": &"gym_battle", "badge": &"tide_badge", "badge_lines": [
			"MARINA: You've earned\nthe TIDE BADGE!",
			"With it, your MONSTERS\ncan SURF across water\noutside of battle.",
		]}],
	"hiker_dale": ["HIKER", "DALE", "hiker", 36, [["pebblet", 12], ["bouldron", 15]],
		["Hah! I've climbed every\nhill around here!", "Let's see if you're as\ntough as a mountain!"],
		["Whoa! You rocked me!"],
		["ROCK types laugh off\nELECTRIC moves. Good to\nknow for COPPERDALE!"]],
	"youngster_joey": ["YOUNGSTER", "JOEY", "youngster", 16, [["pipwing", 12], ["zapkit", 13]],
		["My PIPWING is in the\ntop percentage of\nPIPWING!"],
		["Aww, no way!"],
		["PIPWING evolves at\nlevel 18. It gets SO\ncool!"]],
	"swimmer_rio": ["SWIMMER", "RIO", "swimmer", 16, [["aquapup", 13], ["shadeling", 14]],
		["Surfing the river? This\nis my lane! Battle!"],
		["I got caught in the\ncurrent..."],
		["The river's calm today.\nPerfect for a swim."]],
	"rival_ren_2": ["RIVAL", "REN", "rival", 60, [["flamlet", 18], ["pipwing", 15], ["zapkit", 16]],
		["REN: {PLAYER}! I heard you\nbeat MARINA!", "I've been training too.\nLet's see who's better\nnow!"],
		["Ugh... Again?!"],
		["REN: CORA's GYM is just\nahead. Her ELECTRIC\nMONSTERS hit hard.", "Next time, I'm winning\nfor sure!"],
		{"counters_starter": true}],
	"engineer_roy": ["ENGINEER", "ROY", "engineer", 48, [["zapkit", 16], ["pebblet", 16]],
		["Zzzt! The power's on!\nAre you charged up?"],
		["Short circuit..."],
		["CORA built half the\nmachines in this town."]],
	"engineer_ida": ["ENGINEER", "IDA", "engineer", 48, [["pipwing", 16], ["zapkit", 17]],
		["Watch your step! These\ncables carry a real\njolt!"],
		["Blown fuse!"],
		["GRASS types shrug off\nELECTRIC moves. CORA\nhates that!"]],
	"leader_cora": ["LEADER", "CORA", "cora", 100, [["zapkit", 18], ["bouldron", 19], ["voltvix", 21]],
		["CORA: Welcome to the\nCOPPERDALE GYM!", "My MONSTERS crackle\nwith a million volts.", "Ready to get zapped?"],
		["Wow! You really\nsparked something!"],
		["CORA: With FLY, you can\nhop back to any town\nyou've been to.", "Keep exploring! There's\nso much more out\nthere!"],
		{"music": &"gym_battle", "badge": &"spark_badge", "badge_lines": [
			"CORA: That's the SPARK\nBADGE! You earned it!",
			"With it, your MONSTERS\ncan FLY between towns\noutside of battle.",
		]}],
}

var _force := false


func _initialize() -> void:
	_force = "--force" in OS.get_cmdline_user_args()
	var moves := {}
	for id: String in MOVES:
		moves[id] = _save_or_keep(MOVE_DIR + id + ".tres", _build_move.bind(id, MOVES[id]))
	var abilities := {}
	for id: String in ABILITIES:
		abilities[id] = _save_or_keep(ABILITY_DIR + id + ".tres", _build_ability.bind(ABILITIES[id]))
	var species := {}
	var rebuilt: Array[String] = []
	for id: String in SPECIES:
		var path := SPECIES_DIR + id + ".tres"
		if _force or not FileAccess.file_exists(path):
			rebuilt.append(id)
		species[id] = _save_or_keep(path, _build_species.bind(id, SPECIES[id], moves, abilities))
	# Evolutions point at other species, so they're added once all exist.
	for id: String in EVOLUTIONS:
		if id in rebuilt:
			_add_evolution(species[id], species[EVOLUTIONS[id][0]], EVOLUTIONS[id])
	for id: String in ITEMS:
		_save_or_keep(ITEM_DIR + id + ".tres", _build_item.bind(id, ITEMS[id]))
	for id: String in TRAINERS:
		_save_or_keep(TRAINER_DIR + id + ".tres", _build_trainer.bind(TRAINERS[id], species))
	quit()


func _build_move(id: String, row: Array) -> MoveData:
	var move := MoveData.new()
	move.display_name = row[0]
	move.element = row[1]
	move.category = row[2]
	move.power = row[3]
	move.accuracy = row[4]
	move.max_pp = row[5]
	move.priority = row[6]
	var changes: Dictionary[StringName, int] = {}
	changes.assign(row[7])
	move.stat_changes = changes
	move.stat_target = row[8]
	move.effect_chance = row[9] if not changes.is_empty() else 100
	move.description = row[10]
	if row.size() > 11:
		move.status_effect = StringName(row[11][0])
		move.status_chance = row[11][1]
	move.animation = StringName(id) # MoveAnimator has a recipe for every built-in move.
	return move


func _build_ability(row: Array) -> Ability:
	var ability: Ability = load(ABILITY_SCRIPT_DIR + row[0]).new()
	ability.display_name = row[1]
	ability.description = row[2]
	for property: String in row[3]:
		ability.set(property, row[3][property])
	return ability


const FAST := MonsterSpecies.Growth.FAST
const MEDIUM_FAST := MonsterSpecies.Growth.MEDIUM_FAST
const MEDIUM_SLOW := MonsterSpecies.Growth.MEDIUM_SLOW
const SLOW := MonsterSpecies.Growth.SLOW

## id: [category, height in m, weight in kg, growth rate]. MONDEX numbers
## follow SPECIES order.
const DEX := {
	"flamlet": ["EMBER LIZARD", 0.6, 8.5, MEDIUM_SLOW],
	"blazard": ["BLAZE DRAKE", 1.1, 19.0, MEDIUM_SLOW],
	"aquapup": ["PUDDLE PUP", 0.5, 9.0, MEDIUM_SLOW],
	"tidehound": ["SURF HOUND", 1.2, 35.0, MEDIUM_SLOW],
	"sproutle": ["SPROUT TURTLE", 0.4, 7.2, MEDIUM_SLOW],
	"grovetle": ["GROVE TURTLE", 0.9, 48.0, MEDIUM_SLOW],
	"pebblet": ["PEBBLE", 0.3, 22.0, MEDIUM_SLOW],
	"bouldron": ["BOULDER", 1.4, 210.0, MEDIUM_SLOW],
	"zapkit": ["SPARK FOX", 0.4, 4.8, MEDIUM_FAST],
	"voltvix": ["STORM FOX", 0.9, 21.0, MEDIUM_FAST],
	"shadeling": ["WISP", 0.7, 0.1, MEDIUM_SLOW],
	"duskwraith": ["SHADE", 1.5, 0.3, MEDIUM_SLOW],
	"pipwing": ["TINY BIRD", 0.3, 1.8, MEDIUM_SLOW],
	"galehawk": ["STORM HAWK", 1.2, 24.5, MEDIUM_SLOW],
}


func _build_species(id: String, row: Array, moves: Dictionary, abilities: Dictionary) -> MonsterSpecies:
	var species := MonsterSpecies.new()
	species.display_name = row[0]
	species.element = row[1]
	species.ability = abilities[row[2]]
	species.front_texture = load(SPRITE_DIR + id + ".png")
	species.back_texture = load(SPRITE_DIR + id + "_back.png")
	var stats: Array = row[3]
	species.base_hp = stats[0]
	species.base_attack = stats[1]
	species.base_defense = stats[2]
	species.base_special = stats[3]
	species.base_speed = stats[4]
	species.catch_rate = row[4]
	species.exp_yield = row[5]
	for entry: Array in row[6]:
		var level_move := LevelMove.new()
		level_move.level = entry[0]
		level_move.move = moves[entry[1]]
		species.learnset.append(level_move)
	species.dex_entry = row[7]
	species.dex_number = SPECIES.keys().find(id) + 1
	species.category = DEX[id][0]
	species.height = DEX[id][1]
	species.weight = DEX[id][2]
	species.growth = DEX[id][3]
	return species


func _add_evolution(from: MonsterSpecies, into: MonsterSpecies, row: Array) -> void:
	assert(from.growth == into.growth, "%s must share %s's growth rate" % [into.display_name, from.display_name])
	var evolution := Evolution.new()
	evolution.into = into
	evolution.method = row[1]
	if evolution.method == BY_LEVEL:
		evolution.level = row[2]
	else:
		evolution.item = StringName(row[2])
	from.evolutions.append(evolution)
	var error := ResourceSaver.save(from, from.resource_path)
	print("%s %s (evolves into %s)" % ["wrote" if error == OK else "FAILED (%s)" % error_string(error), from.resource_path, into.display_name])


func _build_item(id: String, row: Array) -> ItemData:
	var item := ItemData.new()
	item.display_name = row[0]
	item.kind = row[1]
	item.icon = load(ITEM_SPRITE_DIR + id + ".png")
	if item.kind == BALL:
		item.catch_multiplier = row[2]
		item.open_icon = load(ITEM_SPRITE_DIR + id + "_open.png")
	elif item.kind == HEAL:
		item.heal_amount = row[2]
	item.price = row[3]
	item.description = row[4]
	var extras: Dictionary = row[5] if row.size() > 5 else {}
	for property: String in extras:
		if property == "bonus_elements":
			item.bonus_elements.assign(extras[property])
		elif property == "cures":
			item.cures.assign(extras[property])
		else:
			item.set(property, extras[property])
	return item


func _build_trainer(row: Array, species: Dictionary) -> TrainerData:
	var trainer := TrainerData.new()
	trainer.trainer_class = row[0]
	trainer.trainer_name = row[1]
	trainer.battle_sprite = load(TRAINER_SPRITE_DIR + row[2] + ".png")
	trainer.payout = row[3]
	for entry: Array in row[4]:
		var member := TrainerMonster.new()
		member.species = species[entry[0]]
		member.level = entry[1]
		trainer.party.append(member)
	trainer.intro = PackedStringArray(row[5])
	trainer.defeat = PackedStringArray(row[6])
	trainer.after = PackedStringArray(row[7])
	var extras: Dictionary = row[8] if row.size() > 8 else {}
	for property: String in extras:
		var value: Variant = extras[property]
		trainer.set(property, PackedStringArray(value) if value is Array else value)
	return trainer


## Saves a freshly built resource, or loads the existing file unless --force.
func _save_or_keep(path: String, build: Callable) -> Resource:
	if FileAccess.file_exists(path) and not _force:
		print("kept  %s (pass -- --force to rebuild)" % path)
		return load(path)
	var resource: Resource = build.call()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var error := ResourceSaver.save(resource, path)
	print("%s %s" % ["wrote" if error == OK else "FAILED (%s)" % error_string(error), path])
	resource.take_over_path(path)
	return resource
