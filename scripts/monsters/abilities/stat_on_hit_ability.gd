class_name StatOnHitAbility
extends Ability
## When the holder is hit, may change the attacker's stats (e.g. JOLT).

@export_range(0.0, 1.0, 0.05) var chance := 0.3
@export_enum("attack", "defense", "special", "speed") var stat := "speed"
@export_range(-6, 6) var stages := -1


func on_hit(battle: Battle, holder: Battler, attacker: Battler, _move: MoveData, _damage: int) -> void:
	if attacker.is_fainted() or battle.rng.randf() >= chance:
		return
	battle.message("%s's %s!" % [holder.name, display_name])
	battle.change_stat(attacker, StringName(stat), stages)
