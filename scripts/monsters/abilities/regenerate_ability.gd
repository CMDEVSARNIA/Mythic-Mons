class_name RegenerateAbility
extends Ability
## Restores a slice of HP at the end of every turn (e.g. SUNSOAK).

@export_range(0.0, 1.0, 0.01) var heal_fraction := 0.0625


func on_turn_end(battle: Battle, holder: Battler) -> void:
	if holder.monster.hp >= holder.monster.max_hp():
		return
	battle.message("%s's %s\nrestored a little HP!" % [holder.name, display_name])
	battle.heal(holder, maxi(1, floori(holder.monster.max_hp() * heal_fraction)))
