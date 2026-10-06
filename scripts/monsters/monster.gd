class_name Monster
extends Resource
## One individual monster: a species plus its own level, stats, moves and HP.
## A Resource so the party can be saved later with ResourceSaver.
##
## Stats use the Generation 3 formula without EVs:
##   HP    = (2 * base + iv) * level / 100 + level + 10
##   other = ((2 * base + iv) * level / 100 + 5) * nature (x1.1, x0.9 or x1)
## IVs are 0-31. The EXP needed per level depends on the species' growth rate
## (MonsterSpecies.exp_for_level).

const MAX_LEVEL := 100
const MAX_NICKNAME_LENGTH := 10
const MAX_MOVES := 4
const MAX_IV := 31
const STATS: Array[StringName] = [&"hp", &"attack", &"defense", &"special", &"speed"]
## Gen 3's major status conditions; a monster has at most one. They last
## outside battle too, until cured or healed.
const STATUSES: Array[StringName] = [&"poison", &"burn", &"paralysis", &"sleep", &"freeze"]
## How menus and HP boxes show them.
const STATUS_TAGS := {&"poison": "PSN", &"burn": "BRN", &"paralysis": "PAR", &"sleep": "SLP", &"freeze": "FRZ"}
## Nature -> [stat raised 10%, stat lowered 10%]; the same stat twice means
## neutral. Like Generation 3's 25, over our four non-HP stats.
const NATURES := {
	&"HARDY": [&"attack", &"attack"], &"LONELY": [&"attack", &"defense"],
	&"BRAVE": [&"attack", &"speed"], &"ADAMANT": [&"attack", &"special"],
	&"BOLD": [&"defense", &"attack"], &"DOCILE": [&"defense", &"defense"],
	&"RELAXED": [&"defense", &"speed"], &"IMPISH": [&"defense", &"special"],
	&"TIMID": [&"speed", &"attack"], &"HASTY": [&"speed", &"defense"],
	&"SERIOUS": [&"speed", &"speed"], &"JOLLY": [&"speed", &"special"],
	&"MODEST": [&"special", &"attack"], &"MILD": [&"special", &"defense"],
	&"QUIET": [&"special", &"speed"], &"BASHFUL": [&"special", &"special"],
}

@export var species: MonsterSpecies
## Leave empty to use the species name.
@export var nickname := ""
@export_range(1, 100) var level := 1
@export var experience := 0
@export var hp := 1
## Individual values 0-31 per stat: why two monsters of one species differ.
@export var ivs: Dictionary[StringName, int] = {}
## A key of NATURES.
@export var nature: StringName = &"HARDY"
## Id of the orb it was caught in (starters come in a MON ORB). It's sent
## out of this orb, and the summary shows it.
@export var orb: StringName = &"mon_orb"
## One of STATUSES, or empty when healthy.
@export var status: StringName = &""
## Turns left asleep (Gen 3: 2-5, counted down each time it tries to move).
@export var sleep_turns := 0
@export var moves: Array[MoveData] = []
## Remaining PP, one entry per move.
@export var pp: PackedInt32Array = []


## A fresh monster at full HP knowing the last four moves of its learnset.
static func create(p_species: MonsterSpecies, p_level: int, rng: RandomNumberGenerator = null) -> Monster:
	var monster := Monster.new()
	monster.species = p_species
	monster.level = clampi(p_level, 1, MAX_LEVEL)
	monster.experience = monster.exp_for_level(monster.level)
	for stat in STATS:
		monster.ivs[stat] = rng.randi_range(0, MAX_IV) if rng else randi_range(0, MAX_IV)
	var natures := NATURES.keys()
	monster.nature = natures[rng.randi_range(0, natures.size() - 1) if rng else randi_range(0, natures.size() - 1)]
	for move in p_species.moves_known_at(monster.level):
		monster.learn(move)
	monster.hp = monster.max_hp()
	return monster


## Total EXP needed to reach `p_level`, by the species' growth rate.
func exp_for_level(p_level: int) -> int:
	return species.exp_for_level(p_level)


func get_display_name() -> String:
	return nickname if not nickname.is_empty() else species.display_name


func max_hp() -> int:
	return stat(&"hp")


@warning_ignore("integer_division")
func stat(stat_name: StringName) -> int:
	var raw: int = (2 * species.base_stat(stat_name) + ivs.get(stat_name, 0)) * level / 100
	if stat_name == &"hp":
		return raw + level + 10
	match nature_effect(stat_name):
		1:
			return (raw + 5) * 11 / 10
		-1:
			return (raw + 5) * 9 / 10
	return raw + 5


## +1 if the nature raises this stat, -1 if it lowers it, 0 otherwise.
func nature_effect(stat_name: StringName) -> int:
	var effect: Array = NATURES.get(nature, NATURES[&"HARDY"])
	if effect[0] == effect[1]:
		return 0
	return 1 if stat_name == effect[0] else (-1 if stat_name == effect[1] else 0)


func is_fainted() -> bool:
	return hp <= 0


func heal_full() -> void:
	hp = max_hp()
	cure()
	for i in moves.size():
		pp[i] = moves[i].max_pp


func cure() -> void:
	status = &""
	sleep_turns = 0


## "PSN", "SLP"... or "" when healthy.
func status_tag() -> String:
	return STATUS_TAGS.get(status, "")


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


## The species this monster evolves into now that it has reached its level,
## or null. Checked after battles in which it leveled up.
func evolution_by_level() -> MonsterSpecies:
	for evolution in species.evolutions:
		if evolution.method == Evolution.Method.LEVEL and level >= evolution.level:
			return evolution.into
	return null


## The species `item_id` (an evolution stone) turns this monster into, or null.
func evolution_by_item(item_id: StringName) -> MonsterSpecies:
	for evolution in species.evolutions:
		if evolution.method == Evolution.Method.ITEM and evolution.item == item_id:
			return evolution.into
	return null


## Becomes `into`, keeping level, EXP, IVs, nature, moves and nickname. Max HP
## changes and current HP moves with it. Returns the moves the new species
## learns at the current level (the caller decides how to teach them).
func evolve(into: MonsterSpecies) -> Array[MoveData]:
	var old_max := max_hp()
	species = into
	if not is_fainted():
		hp = clampi(hp + max_hp() - old_max, 1, max_hp())
	return species.moves_learned_at(level)


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
		"nature": String(nature),
		"orb": String(orb),
		"status": String(status),
		"sleep_turns": sleep_turns,
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
	# Kept inside the level's range, in case the growth rate changed.
	var top := monster.exp_for_level(monster.level + 1) - 1 if monster.level < MAX_LEVEL else monster.exp_for_level(MAX_LEVEL)
	monster.experience = clampi(int(data.get("experience", 0)), monster.exp_for_level(monster.level), top)
	var saved_ivs: Dictionary = data.get("ivs", {})
	for stat in STATS:
		monster.ivs[stat] = clampi(int(saved_ivs.get(stat, 0)), 0, MAX_IV)
	var saved_nature := StringName(str(data.get("nature", "HARDY"))) # Neutral for older saves.
	monster.nature = saved_nature if NATURES.has(saved_nature) else &"HARDY"
	var saved_orb := StringName(str(data.get("orb", "mon_orb")))
	monster.orb = saved_orb if ResourceLoader.exists("%s%s.tres" % [GameData.ITEMS_DIR, saved_orb]) else &"mon_orb"
	var saved_pp: Array = data.get("pp", [])
	var saved_moves: Array = data.get("moves", [])
	for i in saved_moves.size():
		var move := GameData.move(StringName(saved_moves[i]))
		if move and monster.learn(move):
			monster.pp[-1] = clampi(int(saved_pp[i]) if i < saved_pp.size() else move.max_pp, 0, move.max_pp)
	monster.hp = clampi(int(data.get("hp", monster.max_hp())), 0, monster.max_hp())
	var saved_status := StringName(str(data.get("status", "")))
	if saved_status in STATUSES and monster.hp > 0:
		monster.status = saved_status
		monster.sleep_turns = clampi(int(data.get("sleep_turns", 0)), 0, 5) if saved_status == &"sleep" else 0
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
