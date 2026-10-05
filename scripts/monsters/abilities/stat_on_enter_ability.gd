class_name StatOnEnterAbility
extends Ability
## Changes a stat when the holder enters battle (e.g. DREAD lowers the foe's ATTACK).

@export_enum("attack", "defense", "special", "speed") var stat := "attack"
@export_range(-6, 6) var stages := -1
@export var target := MoveData.Target.FOE


func on_enter(battle: Battle, holder: Battler) -> void:
	battle.message("%s's %s!" % [holder.name, display_name])
	var affected := battle.foe_of(holder) if target == MoveData.Target.FOE else holder
	battle.change_stat(affected, StringName(stat), stages)
