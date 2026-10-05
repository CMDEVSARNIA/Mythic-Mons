class_name AbsorbElementAbility
extends Ability
## Moves of one element heal the holder instead of hurting it (e.g. SOAK UP).

@export_enum("normal", "fire", "water", "grass", "rock", "electric", "ghost") var element := "water"
@export_range(0.0, 1.0, 0.05) var heal_fraction := 0.25


func modify_damage_taken(battle: Battle, holder: Battler, _attacker: Battler, move: MoveData, damage: int) -> int:
	if move.element != element:
		return damage
	var amount := maxi(1, roundi(holder.monster.max_hp() * heal_fraction))
	if battle.heal(holder, amount) > 0:
		battle.message("%s's %s\nrestored its HP!" % [holder.name, display_name])
	else:
		battle.message("%s's %s\nmade %s useless!" % [holder.name, display_name, move.display_name])
	return 0
