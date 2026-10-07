class_name FurniturePieces
extends RefCounted
## Furniture from Bitglow's interior pack, shrunk to half size to suit the
## 16x16 cast. The pack's license doesn't allow sharing its files, so the
## originals stay out of the repository (see assets/interiors/source/README.md)
## and tools/import_interiors.gd packs the pieces into ATLAS, in the order
## below. Furniture and Rug draw them; tools/build_world.gd places them.
##
## id: {
##   "kind": SOLID blocks its footprint and A reads its lines; WALL hangs on a
##           wall tile (A from below reads its lines); RUG lies flat and is
##           walked over.
##   "parts": [[sheet, Rect2i in the sheet, offset], ...] layered at full size
##            (a lamp set on a nightstand, say), then halved.
##   "footprint": the cells a SOLID piece covers. Its sprite is centered on
##                them and bottom-aligned, so tall pieces lean on the wall.
##   "nudge": a pixel shift for the sprite.
##   "lines": what A shows. A map can give a piece its own.
## }

enum Kind { SOLID, WALL, RUG }

const ATLAS := "res://assets/interiors/furniture.png"
## Width of ATLAS. Pieces fill rows left to right, 1px apart.
const ATLAS_WIDTH := 128
## The pack's sheets, as named in "parts": <sheet>_BR.png in this folder.
const SOURCE_DIR := "res://assets/interiors/source/"

const BED := ["A cozy bed. It looks\nfreshly made."]
const BIG_BED := ["A big, comfy bed with\nfluffy pillows."]
const WARDROBE := ["A tall wardrobe. It's\nfull of neatly folded\nclothes."]
const DRESSER := ["A chest of drawers.\nBetter not snoop!"]
const STAND := ["A little bedside table."]
const LAMP := ["A bedside lamp glows\nsoftly."]
const VANITY := ["A vanity with a round\nmirror. Looking good!"]
const MIRROR := ["A mirror on the wall.\nLooking sharp!"]

const SINGLE := Vector2i(1, 2)
const DOUBLE := Vector2i(2, 2)
const WIDE := Vector2i(2, 1)
const CELL := Vector2i(1, 1)
## Where a lamp sits on a nightstand, at full size.
const ON_STAND := Vector2i(2, 0)
const UNDER_LAMP := Vector2i(0, 16)

const PIECES := {
	&"bed_red": {"kind": Kind.SOLID, "parts": [["beds", Rect2i(16, 24, 32, 56)]], "footprint": SINGLE, "nudge": Vector2i(0, -2), "lines": BED},
	&"bed_red_double": {"kind": Kind.SOLID, "parts": [["beds", Rect2i(64, 24, 48, 56)]], "footprint": DOUBLE, "nudge": Vector2i(0, -2), "lines": BIG_BED},
	&"bed_white": {"kind": Kind.SOLID, "parts": [["beds", Rect2i(128, 25, 32, 55)]], "footprint": SINGLE, "nudge": Vector2i(0, -2), "lines": BED},
	&"bed_white_double": {"kind": Kind.SOLID, "parts": [["beds", Rect2i(176, 25, 48, 55)]], "footprint": DOUBLE, "nudge": Vector2i(0, -2), "lines": BIG_BED},
	&"bed_olive": {"kind": Kind.SOLID, "parts": [["beds", Rect2i(16, 104, 32, 56)]], "footprint": SINGLE, "nudge": Vector2i(0, -2), "lines": BED},
	&"bed_olive_double": {"kind": Kind.SOLID, "parts": [["beds", Rect2i(64, 104, 48, 56)]], "footprint": DOUBLE, "nudge": Vector2i(0, -2), "lines": BIG_BED},
	&"bed_dark": {"kind": Kind.SOLID, "parts": [["beds", Rect2i(128, 105, 32, 55)]], "footprint": SINGLE, "nudge": Vector2i(0, -2), "lines": BED},
	&"bed_dark_double": {"kind": Kind.SOLID, "parts": [["beds", Rect2i(176, 105, 48, 55)]], "footprint": DOUBLE, "nudge": Vector2i(0, -2), "lines": BIG_BED},
	&"bed_blue": {"kind": Kind.SOLID, "parts": [["beds", Rect2i(16, 184, 32, 56)]], "footprint": SINGLE, "nudge": Vector2i(0, -2), "lines": BED},
	&"bed_blue_double": {"kind": Kind.SOLID, "parts": [["beds", Rect2i(64, 184, 48, 56)]], "footprint": DOUBLE, "nudge": Vector2i(0, -2), "lines": BIG_BED},
	&"wardrobe_dark": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(16, 32, 48, 64)]], "footprint": WIDE, "lines": WARDROBE},
	&"wardrobe_oak": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(16, 112, 48, 64)]], "footprint": WIDE, "lines": WARDROBE},
	&"wardrobe_white": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(16, 192, 48, 64)]], "footprint": WIDE, "lines": WARDROBE},
	&"wardrobe_open": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(80, 32, 64, 66)]], "footprint": WIDE, "lines": ["The wardrobe's door is\nhanging open..."]},
	&"dresser_dark": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(208, 24, 48, 40)]], "footprint": WIDE, "lines": DRESSER},
	&"dresser_oak": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(208, 120, 48, 40)]], "footprint": WIDE, "lines": DRESSER},
	&"dresser_white": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(208, 216, 48, 40)]], "footprint": WIDE, "lines": DRESSER},
	&"nightstand_dark": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(160, 20, 16, 20)]], "footprint": CELL, "nudge": Vector2i(0, -2), "lines": STAND},
	&"nightstand_white": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(160, 212, 16, 20)]], "footprint": CELL, "nudge": Vector2i(0, -2), "lines": STAND},
	&"nightstand_lamp": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(160, 20, 16, 20), UNDER_LAMP], ["decorations", Rect2i(114, 53, 12, 19), ON_STAND]],
		"footprint": CELL, "nudge": Vector2i(0, -2), "lines": LAMP},
	&"nightstand_white_lamp": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(160, 212, 16, 20), UNDER_LAMP], ["decorations", Rect2i(98, 53, 12, 19), ON_STAND]],
		"footprint": CELL, "nudge": Vector2i(0, -2), "lines": LAMP},
	&"vanity_dark": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(16, 304, 32, 44)]], "footprint": CELL, "lines": VANITY},
	&"vanity_oak": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(64, 304, 32, 44)]], "footprint": CELL, "lines": VANITY},
	&"vanity_white": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(112, 304, 32, 44)]], "footprint": CELL, "lines": VANITY},
	&"bench": {"kind": Kind.SOLID, "parts": [["wardrobes", Rect2i(24, 280, 32, 16)]], "footprint": CELL, "nudge": Vector2i(0, -3), "lines": ["A cushioned bench.\nHave a seat!"]},
	&"painting": {"kind": Kind.WALL, "parts": [["decorations", Rect2i(132, 19, 40, 26)]], "nudge": Vector2i(0, -3), "lines": ["A painting of the sun\nrising over the sea."]},
	&"clock": {"kind": Kind.WALL, "parts": [["decorations", Rect2i(99, 30, 10, 10)]], "nudge": Vector2i(0, -6), "lines": ["Tick, tock... The clock\nis right on time."]},
	&"mirror_gold": {"kind": Kind.WALL, "parts": [["decorations", Rect2i(144, 80, 16, 32)]], "lines": MIRROR},
	&"mirror_silver": {"kind": Kind.WALL, "parts": [["decorations", Rect2i(160, 80, 16, 32)]], "lines": MIRROR},
	&"string_lights": {"kind": Kind.WALL, "parts": [["decorations", Rect2i(96, 80, 48, 8)]], "nudge": Vector2i(0, -11), "lines": ["Little lights twinkle\nalong the wall."]},
	&"rug_round": {"kind": Kind.RUG, "parts": [["decorations", Rect2i(17, 128, 62, 48)]]},
	&"rug_navy": {"kind": Kind.RUG, "parts": [["decorations", Rect2i(94, 128, 68, 48)]]},
}

static var _regions := {}


static func kind_of(id: StringName) -> Kind:
	return PIECES[id].kind


static func footprint_of(id: StringName) -> Vector2i:
	return PIECES[id].get("footprint", CELL)


static func nudge_of(id: StringName) -> Vector2i:
	return PIECES[id].get("nudge", Vector2i.ZERO)


static func lines_of(id: StringName) -> PackedStringArray:
	return PackedStringArray(PIECES[id].get("lines", []))


## The piece's size before halving: its parts' bounding box.
static func full_size(id: StringName) -> Vector2i:
	var size := Vector2i.ZERO
	for part: Array in PIECES[id].parts:
		var offset: Vector2i = part[2] if part.size() > 2 else Vector2i.ZERO
		size = size.max(offset + (part[1] as Rect2i).size)
	return size


## Where the piece is in ATLAS.
static func region(id: StringName) -> Rect2i:
	if _regions.is_empty():
		var cursor := Vector2i.ZERO
		var row_height := 0
		for piece: StringName in PIECES:
			var size := (full_size(piece) + Vector2i.ONE) / 2
			if cursor.x + size.x > ATLAS_WIDTH:
				cursor = Vector2i(0, cursor.y + row_height + 1)
				row_height = 0
			_regions[piece] = Rect2i(cursor, size)
			cursor.x += size.x + 1
			row_height = maxi(row_height, size.y)
	return _regions[id]


static func atlas_size() -> Vector2i:
	var size := Vector2i(ATLAS_WIDTH, 0)
	for piece: StringName in PIECES:
		size.y = maxi(size.y, region(piece).end.y)
	return size
