class_name ItemData
extends Resource
## An item that can be carried in the BAG. Saved as .tres files in
## res://data/items/, named by id; GameState.bag counts them by that id.

enum Kind { BALL, HEAL }

## Shown in menus; keep it to 10 characters.
@export var display_name := ""
@export_multiline var description := ""
@export var kind := Kind.BALL
## Sprite thrown in battle (balls).
@export var icon: Texture2D
## Cost in a MART, which buys items back for half. 0 = can't be bought or sold.
@export_range(0, 99999) var price := 0

@export_group("Ball")
## Multiplies the catch chance. 255 or more always catches.
@export var catch_multiplier := 1.0

@export_group("Heal")
@export_range(1, 999) var heal_amount := 20


## What a MART pays for one.
func sell_price() -> int:
	return floori(price / 2.0)
