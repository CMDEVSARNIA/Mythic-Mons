class_name Monster
extends Resource
## One individual monster: a species plus its own level, stats, moves and HP.
## A Resource so the party can be saved later with ResourceSaver.
##
## Stats use a simplified Generation 3 formula without EVs:
##   HP    = (2 * base + iv) * level / 100 + level + 10
##   other = (2 * base + iv) * level / 100 + 5
## EXP follows the "medium fast" curve: reaching level n takes n^3 EXP.

const MAX_LEVEL := 100
const MAX_MOVES := 4
const MAX_IV := 15
const STATS: Array[StringName] = [&"hp", &"attack", &"defense", &"special", &"speed"]

@export var species: MonsterSpecies
## Leave empty to use the species name.
@export var nickname := ""
@export_range(1, 100) var level := 1
@export var experience := 0
@export var hp := 1
## Individual values 0-15 per stat: why two monsters of one species differ.
@export var ivs: Dictionary[StringName, int] = {}
@export var moves: Array[MoveData] = []
## Remaining PP, one entry per move.
@export var pp: PackedInt32Array = []


## A fresh monster at full HP knowing the last four moves of its learnset.
static func create(p_species: MonsterSpecies, p_level: int, rng: RandomNumberGenerator = null) -> Monster:
	var monster := Monster.new()
	monster.species = p_species
	monster.level = clampi(p_level, 1, MAX_LEVEL)
	monster.experience = exp_for_level(monster.level)
	for stat in STATS:
		monster.ivs[stat] = rng.randi_range(0, MAX_IV) if rng else randi_range(0, MAX_IV)
	for move in p_species.moves_known_at(monster.level):
		monster.learn(move)
	monster.hp = monster.max_hp()
	return monster


static func exp_for_level(p_level: int) -> int:
	return p_level * p_level * p_level


func get_display_name() -> String:
	return nickname if not nickname.is_empty() else species.display_name


func max_hp() -> int:
	return stat(&"hp")


@warning_ignore("integer_division")
func stat(stat_name: StringName) -> int:
	var raw: int = (2 * species.base_stat(stat_name) + ivs.get(stat_name, 0)) * level / 100
	return raw + level + 10 if stat_name == &"hp" else raw + 5


func is_fainted() -> bool:
	return hp <= 0


func heal_full() -> void:
	hp = max_hp()
	for i in moves.size():
		pp[i] = moves[i].max_pp


func has_usable_move() -> bool:
	for value in pp:
		if value > 0:
			return true
	return false


## Adds a move if there's a free slot. Returns false when it already knows four.
func learn(move: MoveData) -> bool:
	if moves.size() >= MAX_MOVES or move in moves:
		return false
	moves.append(move)
	pp.append(move.max_pp)
	return true


func replace_move(index: int, move: MoveData) -> void:
	moves[index] = move
	pp[index] = move.max_pp


## Plain data for save files. Species and moves are stored by id.
func to_dict() -> Dictionary:
	var move_ids: Array[String] = []
	for move in moves:
		move_ids.append(String(GameData.id_of(move)))
	return {
		"species": String(GameData.id_of(species)),
		"nickname": nickname,
		"level": level,
		"experience": experience,
		"hp": hp,
		"ivs": ivs,
		"moves": move_ids,
		"pp": Array(pp),
	}


## Rebuilds a monster saved with to_dict(). Returns null if its species no
## longer exists; unknown moves are dropped.
static func from_dict(data: Dictionary) -> Monster:
	var saved_species := GameData.species(StringName(data.get("species", "")))
	if saved_species == null:
		return null
	var monster := Monster.new()
	monster.species = saved_species
	monster.nickname = data.get("nickname", "")
	monster.level = clampi(int(data.get("level", 1)), 1, MAX_LEVEL)
	monster.experience = int(data.get("experience", exp_for_level(monster.level)))
	var saved_ivs: Dictionary = data.get("ivs", {})
	for stat in STATS:
		monster.ivs[stat] = clampi(int(saved_ivs.get(stat, 0)), 0, MAX_IV)
	var saved_pp: Array = data.get("pp", [])
	var saved_moves: Array = data.get("moves", [])
	for i in saved_moves.size():
		var move := GameData.move(StringName(saved_moves[i]))
		if move and monster.learn(move):
			monster.pp[-1] = clampi(int(saved_pp[i]) if i < saved_pp.size() else move.max_pp, 0, move.max_pp)
	monster.hp = clampi(int(data.get("hp", monster.max_hp())), 0, monster.max_hp())
	return monster


## Progress through the current level, 0..1 (for the EXP bar).
func exp_progress() -> float:
	if level >= MAX_LEVEL:
		return 1.0
	var floor_exp := exp_for_level(level)
	return float(experience - floor_exp) / (exp_for_level(level + 1) - floor_exp)


func exp_to_next_level() -> int:
	return 0 if level >= MAX_LEVEL else exp_for_level(level + 1) - experience


## Raises the level by one, keeping damage taken, and returns the moves the
## species learns at the new level (the caller decides how to teach them).
func level_up() -> Array[MoveData]:
	var old_max := max_hp()
	level += 1
	hp += max_hp() - old_max
	return species.moves_learned_at(level)


## Adds EXP without any UI: levels up as needed and auto-learns moves while
## there is room. Returns how many levels were gained.
func gain_exp(amount: int) -> int:
	var gained := 0
	experience += amount
	while level < MAX_LEVEL and experience >= exp_for_level(level + 1):
		for move in level_up():
			learn(move)
		gained += 1
	return gained
