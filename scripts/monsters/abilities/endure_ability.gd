class_name EndureAbility
extends Ability
## Survives any hit taken at full HP with 1 HP left (e.g. STURDY SHELL).


func modify_damage_taken(battle: Battle, holder: Battler, _attacker: Battler, _move: MoveData, damage: int) -> int:
	var hp := holder.monster.hp
	if hp > 1 and hp == holder.monster.max_hp() and damage >= hp:
		battle.message_after_hit("%s endured the hit\nwith %s!" % [holder.name, display_name])
		return hp - 1
	return damage
