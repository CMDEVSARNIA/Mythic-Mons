class_name ItemData
extends Resource
## An item that can be carried in the BAG. Saved as .tres files in
## res://data/items/, named by id; GameState.bag counts them by that id.

enum Kind { BALL, HEAL, EVOLUTION, CURE, REVIVE, PP, REPEL }
## Special orbs, after Gen 3's: when the condition holds, `bonus_multiplier`
## replaces `catch_multiplier`. LOW_LEVEL (NEST ORB) and TIMER (TIMER ORB)
## work out their own multiplier; see Battle.ball_multiplier().
enum Bonus { NONE, ELEMENT, IN_WATER, LOW_LEVEL, REPEAT, TIMER }

## Shown in menus; keep it to 10 characters.
@export var display_name := ""
@export_multiline var description := ""
@export var kind := Kind.BALL
## 16x16 picture for the BAG and MART; balls are also thrown with it.
@export var icon: Texture2D
## Cost in a MART, which buys items back for half. 0 = can't be bought or sold.
@export_range(0, 99999) var price := 0

@export_group("Ball")
## Multiplies the catch chance. 255 or more always catches.
@export var catch_multiplier := 1.0
@export var bonus := Bonus.NONE
@export var bonus_multiplier := 1.0
## ELEMENT orbs: the wild monster's element must be one of these.
@export var bonus_elements: Array[StringName] = []
## The orb popping open, for catches and send-outs.
@export var open_icon: Texture2D

@export_group("Heal")
@export_range(1, 999) var heal_amount := 20

@export_group("Cure")
## Status conditions it cures; empty cures them all (FULL HEAL).
@export var cures: Array[StringName] = []

@export_group("Revive")
## Share of max HP a fainted monster comes back with (REVIVE 0.5, MAX REVIVE 1).
@export_range(0.0, 1.0) var revive_fraction := 0.5

@export_group("PP")
## PP restored to one move (ETHER).
@export_range(1, 99) var pp_amount := 10

@export_group("Repel")
## Steps during which wild monsters weaker than the lead stay away.
@export_range(1, 999) var repel_steps := 100


## True if this item (a CURE) would fix `status`.
func cures_status(status: StringName) -> bool:
	return kind == Kind.CURE and not status.is_empty() and (cures.is_empty() or status in cures)


## True for items used on one party member: HEAL, CURE, REVIVE and PP.
func targets_monster() -> bool:
	return kind in [Kind.HEAL, Kind.CURE, Kind.REVIVE, Kind.PP]


## Whether using this on `monster` would do anything. PP items need the
## move (`move_index`); with -1 any move short of PP counts.
func can_use_on(monster: Monster, move_index := -1) -> bool:
	match kind:
		Kind.HEAL:
			return not monster.is_fainted() and monster.hp < monster.max_hp()
		Kind.CURE:
			return not monster.is_fainted() and cures_status(monster.status)
		Kind.REVIVE:
			return monster.is_fainted()
		Kind.PP:
			if move_index >= 0:
				return monster.pp[move_index] < monster.moves[move_index].max_pp
			for i in monster.moves.size():
				if monster.pp[i] < monster.moves[i].max_pp:
					return true
	return false


## Uses the item on `monster` (check can_use_on() first) and returns what to
## say about it.
func use_on(monster: Monster, move_index := -1) -> String:
	var monster_name := monster.get_display_name()
	match kind:
		Kind.HEAL:
			var healed := mini(heal_amount, monster.max_hp() - monster.hp)
			monster.hp += healed
			return "%s's HP was\nrestored by %d point%s." % [monster_name, healed, "" if healed == 1 else "s"]
		Kind.CURE:
			var was := monster.status
			monster.cure()
			return Battle.CURED_TEXT[was] % monster_name
		Kind.REVIVE:
			monster.hp = maxi(1, floori(monster.max_hp() * revive_fraction))
			return "%s's HP was\nrestored. It's back on\nits feet!" % monster_name
		Kind.PP:
			var move := monster.moves[move_index]
			monster.pp[move_index] = mini(monster.pp[move_index] + pp_amount, move.max_pp)
			return "%s's PP\nwas restored." % move.display_name
	return ""


## What a MART pays for one.
func sell_price() -> int:
	return floori(price / 2.0)
