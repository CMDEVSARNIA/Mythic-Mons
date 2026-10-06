class_name Battler
extends RefCounted
## A monster while it is on the field: its Monster plus battle-only state.
## Stat stages reset whenever it leaves, because a new Battler is created.

const STAGE_STATS: Array[StringName] = [&"attack", &"defense", &"special", &"speed"]
const MIN_STAGE := -6
const MAX_STAGE := 6

var monster: Monster
var side: StringName
var is_wild: bool
var stages: Dictionary[StringName, int] = {}
## Volatile conditions, gone once it leaves the field: how many more of its
## turns confusion lasts, and whether it flinched this turn.
var confused_turns := 0
var flinched := false

## Name used in battle text: "Wild SPROUTLE" for wild monsters, "Foe
## SPROUTLE" for a trainer's.
var name: String:
	get:
		var prefix := ""
		if side == Battle.ENEMY:
			prefix = "Wild " if is_wild else "Foe "
		return prefix + monster.get_display_name()

var element: String:
	get:
		return monster.species.element

var ability: Ability:
	get:
		return monster.species.ability


func _init(p_monster: Monster, p_side: StringName, p_is_wild := false) -> void:
	monster = p_monster
	side = p_side
	is_wild = p_is_wild
	for stat_name in STAGE_STATS:
		stages[stat_name] = 0


func is_fainted() -> bool:
	return monster.is_fainted()


## The stat including its current stage. Paralysis quarters SPEED (Gen 3).
func stat(stat_name: StringName) -> int:
	var value := stat_at_stage(stat_name, stages.get(stat_name, 0))
	if stat_name == &"speed" and monster.status == &"paralysis":
		value = maxi(1, floori(value / 4.0))
	return value


func stat_at_stage(stat_name: StringName, stage: int) -> int:
	return maxi(1, floori(monster.stat(stat_name) * stage_multiplier(stage)))


## Stage -6..+6 maps to 2/8 .. 8/2, as in the handheld games.
static func stage_multiplier(stage: int) -> float:
	return maxf(2.0, 2.0 + stage) / maxf(2.0, 2.0 - stage)
