class_name ElementBoostAbility
extends Ability
## Powers up one element's moves while the holder's HP is low (e.g. KINDLE).

@export_enum("normal", "fire", "water", "grass", "rock", "electric", "ghost") var element := "fire"
## Active at or below this fraction of max HP.
@export_range(0.0, 1.0, 0.01) var hp_threshold := 0.34
@export var multiplier := 1.5


func damage_multiplier(_battle: Battle, holder: Battler, _target: Battler, move: MoveData) -> float:
	var low_hp := holder.monster.hp <= holder.monster.max_hp() * hp_threshold
	return multiplier if low_hp and move.element == element else 1.0
