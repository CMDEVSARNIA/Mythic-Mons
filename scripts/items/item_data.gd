class_name ItemData
extends Resource
## An item that can be carried in the BAG. Saved as .tres files in
## res://data/items/, named by id; GameState.bag counts them by that id.

enum Kind { BALL, HEAL, EVOLUTION }
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


## What a MART pays for one.
func sell_price() -> int:
	return floori(price / 2.0)
