extends Node
## Save-worthy data that outlives any single map (autoload "GameState").
##
## Saves are plain JSON in user:// (see save_game()). JSON is used instead of
## a .tres file because loading a .tres can run scripts embedded in it, and a
## save file is something players can edit or share.

## Field moves that change how the player can traverse the world.
const FIELD_MOVES: Array[StringName] = [&"cut", &"rock_smash", &"surf", &"fly"]
const MAX_PARTY := 6
## Most of one item the BAG holds.
const MAX_ITEM_COUNT := 99
const START_MONEY := 3000
const MAX_MONEY := 999999
const SAVE_VERSION := 1
const STARTER_FLAG := &"got_starter"
## Set once a new game's intro (PROF. ASTER asking your name) has played.
const INTRO_FLAG := &"intro_done"
const DEFAULT_NAME := "KAI"
## Where a new game respawns after whiting out, until a MONSTER CENTER heals you.
const HOME_MAP := "res://scenes/maps/house_emberfall.tscn"
const MAX_NAME_LENGTH := 7
## Gym badges, in the order they're won: id -> [name, field moves it lets
## monsters use outside battle]. A badge is kept as a flag with its id.
## Field moves no badge lists (CUT, ROCK SMASH) work from the start.
const BADGES := {
	&"tide_badge": ["TIDE BADGE", [&"surf"]],
	&"spark_badge": ["SPARK BADGE", [&"fly"]],
}

var player_name := DEFAULT_NAME
## Tests set this to start straight on the map, without the title screen.
var skip_title := false
## Seconds played, for the trainer card.
var play_seconds := 0.0
## Steps left on a REPEL: until 0, wild monsters weaker than the lead stay away.
var repel_steps := 0
## Fly destinations: town map scene path -> display name, in visit order.
var visited_towns: Dictionary[String, String] = {}
var current_map_path := ""
## Story/progress switches, e.g. flags[STARTER_FLAG] = true.
var flags: Dictionary[StringName, bool] = {}
## Up to six monsters; the first healthy one leads in battle.
var party: Array[Monster] = []
## The BOX: caught monsters that didn't fit in the party. The PC in a
## MONSTER CENTER moves them in and out (withdraw(), deposit(), release()).
var storage: Array[Monster] = []
## MONDEX: species ids met in battle, and species ids ever owned.
var seen: Dictionary[StringName, bool] = {}
var caught: Dictionary[StringName, bool] = {}
## Item id (a file in res://data/items/) -> how many the player carries.
var bag: Dictionary[StringName, int] = {&"potion": 2}
var money := START_MONEY
## Where the player wakes up after losing a battle (last place they healed).
var respawn_map := HOME_MAP
var respawn_spawn: StringName = &"entrance"
## Tests point this somewhere else so they never touch a real save.
var save_path := "user://save.json"


## True if the player has the badge that `move` needs (or it needs none).
func can_use_field_move(move: StringName) -> bool:
	var badge := badge_for(move)
	return badge.is_empty() or has_flag(badge)


## The badge `move` needs outside battle, or &"" if none.
func badge_for(move: StringName) -> StringName:
	for badge: StringName in BADGES:
		if move in BADGES[badge][1]:
			return badge
	return &""


func badge_count() -> int:
	return BADGES.keys().filter(func(badge: StringName) -> bool: return has_flag(badge)).size()


func has_flag(flag: StringName) -> bool:
	return flags.get(flag, false)


func set_flag(flag: StringName, value := true) -> void:
	flags[flag] = value


func mark_town_visited(map_path: String, display_name: String) -> void:
	visited_towns[map_path] = display_name


## The monster that battles first: the first one that hasn't fainted.
func lead_monster() -> Monster:
	for monster in party:
		if not monster.is_fainted():
			return monster
	return null


func has_healthy_monster() -> bool:
	for monster in party:
		if not monster.is_fainted():
			return true
	return false


func heal_party() -> void:
	for monster in party:
		monster.heal_full()


## Adds a new monster (a starter or a catch) and registers it in the MONDEX.
## Returns true if it joined the party, false if the party was full and it
## went to storage.
func add_monster(monster: Monster) -> bool:
	mark_caught(GameData.id_of(monster.species))
	if party.size() < MAX_PARTY:
		party.append(monster)
		return true
	storage.append(monster)
	return false


## Moves BOX monster `box_index` into the party. False if the party is full.
func withdraw(box_index: int) -> bool:
	if party.size() >= MAX_PARTY or box_index < 0 or box_index >= storage.size():
		return false
	party.append(storage.pop_at(box_index))
	return true


## True if party member `party_index` may go in the BOX: the party must keep
## another monster that can still battle.
func can_deposit(party_index: int) -> bool:
	if party_index < 0 or party_index >= party.size():
		return false
	for i in party.size():
		if i != party_index and not party[i].is_fainted():
			return true
	return false


func deposit(party_index: int) -> bool:
	if not can_deposit(party_index):
		return false
	storage.append(party.pop_at(party_index))
	return true


## Lets BOX monster `box_index` go for good, and returns it.
func release(box_index: int) -> Monster:
	if box_index < 0 or box_index >= storage.size():
		return null
	return storage.pop_at(box_index)


func item_count(id: StringName) -> int:
	return bag.get(id, 0)


## Adds items, up to MAX_ITEM_COUNT of each.
func mark_seen(species_id: StringName) -> void:
	seen[species_id] = true


## Caught monsters count as seen too.
func mark_caught(species_id: StringName) -> void:
	seen[species_id] = true
	caught[species_id] = true


func add_item(id: StringName, count := 1) -> void:
	bag[id] = mini(item_count(id) + count, MAX_ITEM_COUNT)


## Removes `count` of an item. Returns false, removing nothing, if the BAG
## holds fewer than that.
func remove_item(id: StringName, count := 1) -> bool:
	if count <= 0 or item_count(id) < count:
		return false
	bag[id] -= count
	if bag[id] == 0:
		bag.erase(id)
	return true


func add_money(amount: int) -> void:
	money = clampi(money + amount, 0, MAX_MONEY)


## Pays `amount` if the player can afford it. Returns false, paying nothing,
## if they can't.
func spend_money(amount: int) -> bool:
	if amount < 0 or amount > money:
		return false
	money -= amount
	return true


# --- Saving ------------------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Writes everything to save_path. `location` comes from Main:
## {"map": scene path, "cell": Vector2i, "facing": Vector2i, "surfing": bool}.
func save_game(location: Dictionary) -> Error:
	var cell: Vector2i = location.cell
	var data := {
		"version": SAVE_VERSION,
		"player_name": player_name,
		"map": location.map,
		"cell": [cell.x, cell.y],
		"facing": Grid.direction_index(location.facing),
		"surfing": location.get("surfing", false),
		"respawn_map": respawn_map,
		"respawn_spawn": String(respawn_spawn),
		"party": party.map(func(monster: Monster) -> Dictionary: return monster.to_dict()),
		"storage": storage.map(func(monster: Monster) -> Dictionary: return monster.to_dict()),
		"bag": bag,
		"money": money,
		"repel_steps": repel_steps,
		"play_seconds": play_seconds,
		"flags": flags,
		"visited_towns": visited_towns,
		"seen": seen.keys(),
		"caught": caught.keys(),
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	return OK


## Restores the state from save_path. Returns where the player was standing
## ({"map", "cell", "facing", "surfing"}), or {} if there is no usable save.
func load_game() -> Dictionary:
	if not has_save():
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary or int(data.get("version", 0)) != SAVE_VERSION:
		push_warning("Ignoring unreadable save file: %s" % save_path)
		return {}
	player_name = data.get("player_name", player_name)
	respawn_map = data.get("respawn_map", respawn_map)
	respawn_spawn = StringName(data.get("respawn_spawn", respawn_spawn))
	party = _monsters_from(data.get("party", []))
	storage = _monsters_from(data.get("storage", []))
	bag.clear()
	for id: String in data.get("bag", {}):
		bag[StringName(id)] = int(data.bag[id])
	money = clampi(int(data.get("money", START_MONEY)), 0, MAX_MONEY)
	repel_steps = maxi(int(data.get("repel_steps", 0)), 0)
	play_seconds = maxf(float(data.get("play_seconds", 0.0)), 0.0)
	flags.clear()
	for flag: String in data.get("flags", {}):
		flags[StringName(flag)] = bool(data.flags[flag])
	visited_towns.clear()
	for path: String in data.get("visited_towns", {}):
		visited_towns[path] = String(data.visited_towns[path])
	seen.clear()
	caught.clear()
	for id: Variant in data.get("seen", []):
		mark_seen(StringName(str(id)))
	for id: Variant in data.get("caught", []):
		mark_caught(StringName(str(id)))
	for monster in party + storage: # Saves from before the MONDEX existed.
		mark_caught(GameData.id_of(monster.species))
	var cell: Array = data.get("cell", [0, 0])
	return {
		"map": String(data.get("map", "")),
		"cell": Vector2i(int(cell[0]), int(cell[1])),
		"facing": Grid.DIRECTIONS[clampi(int(data.get("facing", 0)), 0, 3)],
		"surfing": bool(data.get("surfing", false)),
	}


func _monsters_from(list: Array) -> Array[Monster]:
	var monsters: Array[Monster] = []
	for entry: Variant in list:
		var monster := Monster.from_dict(entry) if entry is Dictionary else null
		if monster:
			monsters.append(monster)
	return monsters
