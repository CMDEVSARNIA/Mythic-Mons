class_name MonsterSpecies
extends Resource
## Static data shared by every monster of a kind. Saved in res://data/species/,
## one file per species, named after its id (e.g. sproutle.tres).

@export var display_name := ""
@export_enum("normal", "fire", "water", "grass", "rock", "electric", "ghost") var element := "normal"
@export var ability: Ability
@export var front_texture: Texture2D
@export var back_texture: Texture2D

@export_group("Base Stats")
@export_range(1, 255) var base_hp := 45
@export_range(1, 255) var base_attack := 45
@export_range(1, 255) var base_defense := 45
## Used for both dealing and resisting SPECIAL moves (like the 8-bit games).
@export_range(1, 255) var base_special := 45
@export_range(1, 255) var base_speed := 45

@export_group("Growth")
## 3 (very hard) to 255 (very easy). Used by the catching formula.
@export_range(1, 255) var catch_rate := 45
## EXP awarded for defeating it is exp_yield * its level / 7.
@export_range(1, 400) var exp_yield := 60
@export var learnset: Array[LevelMove] = []

@export_group("MONDEX")
## Position in the MONDEX list (No. 001 and up).
@export_range(1, 999) var dex_number := 1
## Shown as "<category> MONSTER", e.g. "EMBER LIZARD".
@export var category := ""
@export_range(0.1, 99.9, 0.1, "suffix:m") var height := 0.5
@export_range(0.1, 999.9, 0.1, "suffix:kg") var weight := 5.0
@export_multiline var dex_entry := ""


func base_stat(stat: StringName) -> int:
	match stat:
		&"hp":
			return base_hp
		&"attack":
			return base_attack
		&"defense":
			return base_defense
		&"special":
			return base_special
		_:
			return base_speed


## Moves learned exactly at `level`, in learnset order.
func moves_learned_at(level: int) -> Array[MoveData]:
	var moves: Array[MoveData] = []
	for entry in learnset:
		if entry.level == level and entry.move:
			moves.append(entry.move)
	return moves


## The last four moves learned by `level`: what a wild monster knows.
func moves_known_at(level: int) -> Array[MoveData]:
	var moves: Array[MoveData] = []
	for entry in learnset:
		if entry.level <= level and entry.move and entry.move not in moves:
			moves.append(entry.move)
	return moves.slice(maxi(moves.size() - Monster.MAX_MOVES, 0))
