class_name Ability
extends Resource
## Base class for monster abilities. Subclasses override only the hooks they
## need, and the battle calls them at the right moment for both monsters.
## Abilities act through the battle's helpers (message, heal, change_stat), so
## everything they do shows up on screen like any other battle event.
##
## Abilities are data: each subclass exposes its numbers as exports, and
## res://data/abilities/*.tres holds configured instances that species use.

@export var display_name := ""
@export_multiline var description := ""


## The holder was just sent into battle.
func on_enter(_battle: Battle, _holder: Battler) -> void:
	pass


## Multiplier for damage the holder deals with `move`.
func damage_multiplier(_battle: Battle, _holder: Battler, _target: Battler, _move: MoveData) -> float:
	return 1.0


## Returns the damage the holder will actually take from `move`.
func modify_damage_taken(_battle: Battle, _holder: Battler, _attacker: Battler, _move: MoveData, damage: int) -> int:
	return damage


## The holder took damage from `move` and is still standing.
func on_hit(_battle: Battle, _holder: Battler, _attacker: Battler, _move: MoveData, _damage: int) -> void:
	pass


## End of every turn, while the holder is still in battle.
func on_turn_end(_battle: Battle, _holder: Battler) -> void:
	pass
