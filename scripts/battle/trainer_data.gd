class_name TrainerData
extends Resource
## Someone who battles the player with a team of monsters. Saved as .tres
## files in res://data/trainers/, named by id. A Trainer NPC on a map points
## at one, and beating it sets defeat_flag() in GameState.

## Starters, and the one that beats each: water douses fire, grass drinks
## water, fire burns grass.
const STARTER_COUNTERS := {&"flamlet": &"aquapup", &"aquapup": &"sproutle", &"sproutle": &"flamlet"}

## Shown before the name, as in "LASS MIA".
@export var trainer_class := "YOUNGSTER"
@export var trainer_name := ""
## 32x32 front sprite, drawn at 2x in battle.
@export var battle_sprite: Texture2D
## The team, sent out first to last.
@export var party: Array[TrainerMonster] = []
## The rival's trick: the first monster becomes the starter that beats the
## player's.
@export var counters_starter := false
## Prize money is payout times the level of the last monster, as in Gen 3.
@export_range(0, 255) var payout := 16
## Battle music (a Songs id or a file in assets/audio/music/).
@export var music: StringName = &"trainer_battle"
## Gym leaders: the badge (a GameState.BADGES id) they hand over when beaten.
@export var badge: StringName

@export_group("Lines")
## Said on the map before the battle. "{PLAYER}" becomes the player's name.
@export var intro: PackedStringArray = []
## Said in battle after losing.
@export var defeat: PackedStringArray = []
## Said on the map once beaten.
@export var after: PackedStringArray = []
## Said on the map right after handing over the badge.
@export var badge_lines: PackedStringArray = []


## "LASS MIA", or just the class for a trainer without a name.
func title() -> String:
	return "%s %s" % [trainer_class, trainer_name] if not trainer_name.is_empty() else trainer_class


## Fresh monsters for a battle. `player_starter` is the species id of the
## player's starter, for counters_starter. A trainer always rolls the same
## IVs and natures, so a rematch after a loss is the same fight.
func build_party(player_starter := &"") -> Array[Monster]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(resource_path)
	var team: Array[Monster] = []
	for i in party.size():
		var species := party[i].species
		if i == 0 and counters_starter and STARTER_COUNTERS.has(player_starter):
			species = GameData.species(STARTER_COUNTERS[player_starter])
		team.append(Monster.create(species, party[i].level, rng))
	return team


## What the player earns for winning: payout x the last monster's level.
func prize_money() -> int:
	return payout * party.back().level if not party.is_empty() else 0


## The GameState flag set once this trainer is beaten.
func defeat_flag() -> StringName:
	return StringName("beat_" + resource_path.get_file().get_basename())
