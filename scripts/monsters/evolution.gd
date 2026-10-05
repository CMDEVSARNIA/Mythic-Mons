class_name Evolution
extends Resource
## One way a species evolves, kept in MonsterSpecies.evolutions.
## The evolved species must share the pre-evolution's growth rate.

enum Method {
	LEVEL, ## After a battle in which the monster reaches `level`.
	ITEM, ## When the BAG item `item` is used on it.
}

## The species it turns into.
@export var into: MonsterSpecies
@export var method := Method.LEVEL
@export_range(1, 100) var level := 16
## An item id (a file in res://data/items/), e.g. &"bolt_stone".
@export var item: StringName = &""
