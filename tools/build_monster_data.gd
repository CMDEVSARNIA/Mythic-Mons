extends SceneTree
## Writes the starter monster data (moves, abilities, species) to res://data/
## as .tres files you can then tweak in the inspector.
##
## Usually run through tools/rebuild_placeholders.sh (it needs the monster PNGs
## to be imported first). To run it alone:
##   godot --headless --path . --script res://tools/build_monster_data.gd
##
## Existing files are kept so inspector edits are safe. Pass `-- --force` to
## rewrite them all from the tables below.

const MOVE_DIR := "res://data/moves/"
const ABILITY_DIR := "res://data/abilities/"
const SPECIES_DIR := "res://data/species/"
const SPRITE_DIR := "res://assets/placeholder/monsters/"
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
	"ember": ["EMBER", "fire", SPECIAL, 40, 100, 25, 0, {}, FOE, 0, "A small burst of flame."],
	"flame_dash": ["FLAME DASH", "fire", PHYSICAL, 60, 95, 20, 0, {}, FOE, 0, "A charge wreathed in fire."],
	"water_gun": ["WATER GUN", "water", SPECIAL, 40, 100, 25, 0, {}, FOE, 0, "Squirts water at the foe."],
	"bubblebeam": ["BUBBLEBEAM", "water", SPECIAL, 65, 100, 20, 0, {&"speed": -1}, FOE, 10, "May lower the foe's SPEED."],
	"vine_whip": ["VINE WHIP", "grass", PHYSICAL, 45, 100, 25, 0, {}, FOE, 0, "Strikes with slender vines."],
	"razor_leaf": ["RAZOR LEAF", "grass", SPECIAL, 55, 95, 25, 0, {}, FOE, 0, "Launches sharp-edged leaves."],
	"rock_throw": ["ROCK THROW", "rock", PHYSICAL, 50, 90, 15, 0, {}, FOE, 0, "Hurls a small rock."],
	"spark": ["SPARK", "electric", SPECIAL, 40, 100, 30, 0, {}, FOE, 0, "A jolt of electricity."],
	"volt_dash": ["VOLT DASH", "electric", PHYSICAL, 65, 95, 15, 0, {}, FOE, 0, "A crackling tackle."],
	"lick": ["LICK", "ghost", PHYSICAL, 30, 100, 30, 0, {}, FOE, 0, "An eerie, chilling lick."],
	"shade_orb": ["SHADE ORB", "ghost", SPECIAL, 60, 100, 15, 0, {&"special": -1}, FOE, 20, "May lower the foe's SPECIAL."],
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
}

## id: [name, element, ability, [hp, attack, defense, special, speed], catch rate, exp yield, learnset, dex entry]
const SPECIES := {
	"flamlet": ["FLAMLET", "fire", "kindle", [39, 52, 43, 55, 65], 45, 62,
		[[1, "scratch"], [1, "growl"], [7, "ember"], [13, "leer"], [19, "flame_dash"]],
		"Its tail-flame flickers brighter whenever it is excited."],
	"aquapup": ["AQUAPUP", "water", "soak_up", [44, 48, 65, 50, 43], 45, 63,
		[[1, "tackle"], [1, "growl"], [7, "water_gun"], [13, "harden"], [19, "bubblebeam"]],
		"Splashes through puddles for hours and never seems to get cold."],
	"sproutle": ["SPROUTLE", "grass", "sunsoak", [45, 49, 49, 65, 45], 190, 50,
		[[1, "tackle"], [3, "growl"], [7, "vine_whip"], [15, "razor_leaf"]],
		"Naps in sunny patches of tall grass, soaking up light through its leaves."],
	"pebblet": ["PEBBLET", "rock", "sturdy_shell", [40, 80, 100, 30, 20], 190, 60,
		[[1, "tackle"], [1, "harden"], [8, "rock_throw"], [16, "scary_face"]],
		"Often mistaken for an ordinary rock, until it rolls away."],
	"zapkit": ["ZAPKIT", "electric", "jolt", [35, 55, 30, 50, 90], 190, 56,
		[[1, "quick_hit"], [1, "growl"], [6, "spark"], [14, "volt_dash"]],
		"Its ears crackle with static. Touching them makes your hair stand up."],
	"shadeling": ["SHADELING", "ghost", "dread", [30, 35, 30, 100, 80], 120, 62,
		[[1, "lick"], [1, "scary_face"], [8, "shade_orb"]],
		"Lurks in the shadows of old houses and giggles at night."],
}

var _force := false


func _initialize() -> void:
	_force = "--force" in OS.get_cmdline_user_args()
	var moves := {}
	for id: String in MOVES:
		moves[id] = _save_or_keep(MOVE_DIR + id + ".tres", _build_move.bind(MOVES[id]))
	var abilities := {}
	for id: String in ABILITIES:
		abilities[id] = _save_or_keep(ABILITY_DIR + id + ".tres", _build_ability.bind(ABILITIES[id]))
	for id: String in SPECIES:
		_save_or_keep(SPECIES_DIR + id + ".tres", _build_species.bind(id, SPECIES[id], moves, abilities))
	quit()


func _build_move(row: Array) -> MoveData:
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
	return move


func _build_ability(row: Array) -> Ability:
	var ability: Ability = load(ABILITY_SCRIPT_DIR + row[0]).new()
	ability.display_name = row[1]
	ability.description = row[2]
	for property: String in row[3]:
		ability.set(property, row[3][property])
	return ability


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
	return species


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
