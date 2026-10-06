class_name MoveData
extends Resource
## One move a monster can know. Saved as .tres files in res://data/moves/.

enum Category { PHYSICAL, SPECIAL, STATUS }
enum Target { FOE, SELF }

## Shown in menus; keep it to 10 characters so the move list fits the screen.
@export var display_name := ""
@export_enum("normal", "fire", "water", "grass", "rock", "electric", "ghost") var element := "normal"
## PHYSICAL uses ATTACK vs DEFENSE, SPECIAL uses SPECIAL vs SPECIAL.
@export var category := Category.PHYSICAL
@export_range(0, 250) var power := 40
@export_range(1, 100) var accuracy := 100
@export_range(1, 64) var max_pp := 35
## Higher priority moves go first regardless of speed.
@export_range(-3, 3) var priority := 0

@export_group("Stat Effect")
## Stat stage changes, e.g. {&"attack": -1}. Applied on hit for damaging moves.
@export var stat_changes: Dictionary[StringName, int] = {}
@export var stat_target := Target.FOE
## Chance (percent) that the stat effect happens. Status moves use 100.
@export_range(0, 100) var effect_chance := 100

@export_group("Status Effect")
## A status condition (one of Monster.STATUSES) the move inflicts on the foe:
## always for a STATUS move that hits, otherwise with status_chance.
@export var status_effect: StringName
@export_range(0, 100) var status_chance := 100

@export_group("Extra Effects")
## Percent of the damage dealt that the user regains (ABSORB, GIGA DRAIN).
@export_range(0, 100) var drain := 0
## Percent of the damage dealt that the user takes back (TAKE DOWN).
@export_range(0, 100) var recoil := 0
## Percent of its max HP a STATUS move restores to the user (SYNTHESIS).
## Give such moves stat_target SELF so they never miss.
@export_range(0, 100) var heal := 0
## Chance (percent) the target flinches and loses its move, if it hasn't
## moved yet this turn (HEADBUTT, ROCK SLIDE).
@export_range(0, 100) var flinch_chance := 0
## Chance (percent) the target becomes confused (DIZZY RAY, SUPERSONIC).
@export_range(0, 100) var confuse_chance := 0

@export_multiline var description := ""
## Which MoveAnimator recipe plays when the move is used (see
## MoveAnimator.RECIPES). Leave empty to pick one from the element and
## category.
@export var animation: StringName


func is_damaging() -> bool:
	return category != Category.STATUS
