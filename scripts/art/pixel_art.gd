class_name PixelArt
extends RefCounted
## Procedural 8-bit placeholder art.
##
## Every function returns an Image. tools/generate_placeholder_art.gd saves them
## as PNGs under res://assets/placeholder/, and the TileSet and scenes use those
## files. Replace a PNG with real art of the same size and layout and nothing
## else has to change.
##
## Colors come from one small palette (mostly "Sweetie 16" by GrafxKid) so
## everything reads as a single cohesive retro style.

const TILE := 16

# --- Palette ----------------------------------------------------------------
const INK := Color("1a1c2c")
const PLUM := Color("5d275d")
const RED := Color("b13e53")
const ORANGE := Color("ef7d57")
const SAND := Color("ffcd75")
const LIME := Color("a7f070")
const GREEN := Color("38b764")
const TEAL := Color("257179")
const NAVY := Color("29366f")
const BLUE := Color("3b5dc9")
const SKY := Color("41a6f6")
const CYAN := Color("73eff7")
const WHITE := Color("f4f4f4")
const FOG := Color("94b0c2")
const SLATE := Color("566c86")
const NIGHT := Color("333c57")
# A few extras for ground, wood and skin.
const DEEP := Color("1f6b4a")
const DIRT := Color("e3b26f")
const DIRT_DARK := Color("b8803f")
const WOOD := Color("b86f50")
const WOOD_DARK := Color("743f39")
const SKIN := Color("f5c9a0")
const HAIR := Color("4a2c2a")
const CLEAR := Color(0, 0, 0, 0)

## Where each tile lives in overworld_tiles.png (8 columns x 4 rows of 16x16).
## tools/build_world.gd reads this to build the TileSet, so keep them in sync.
const TILES := {
	&"grass": Vector2i(0, 0),
	&"tall_grass": Vector2i(1, 0),
	&"path": Vector2i(2, 0),
	&"flowers": Vector2i(3, 0),
	&"sand": Vector2i(4, 0),
	&"ledge_down": Vector2i(5, 0),
	&"tree": Vector2i(6, 0),
	&"cliff": Vector2i(7, 0),
	&"water": Vector2i(0, 1), # 2-frame animation: frames at (0,1) and (1,1)
	&"roof_red_l": Vector2i(2, 1),
	&"roof_red_m": Vector2i(3, 1),
	&"roof_red_r": Vector2i(4, 1),
	&"wall": Vector2i(5, 1),
	&"window": Vector2i(6, 1),
	&"door": Vector2i(7, 1),
	&"fence": Vector2i(0, 2),
	&"floor": Vector2i(1, 2),
	&"indoor_wall": Vector2i(2, 2),
	&"mat": Vector2i(3, 2),
	&"table": Vector2i(4, 2),
	&"bed": Vector2i(5, 2),
	&"shelf": Vector2i(6, 2),
	&"void": Vector2i(7, 2),
	&"roof_blue_l": Vector2i(0, 3),
	&"roof_blue_m": Vector2i(1, 3),
	&"roof_blue_r": Vector2i(2, 3),
}
const ATLAS_SIZE := Vector2i(8, 4)

## Color sets for character_sheet(). Keys match the letters in the sprite patterns.
const PLAYER_COLORS := {"H": RED, "h": PLUM, "A": HAIR, "B": BLUE, "b": NAVY, "P": NIGHT}
const NPC_COLORS := {
	&"lass": {"H": GREEN, "h": TEAL, "A": ORANGE, "B": ORANGE, "b": RED, "P": NAVY},
	&"elder": {"H": FOG, "h": SLATE, "A": WHITE, "B": PLUM, "b": NAVY, "P": SLATE},
	&"hiker": {"H": WOOD, "h": WOOD_DARK, "A": HAIR, "B": GREEN, "b": TEAL, "P": WOOD_DARK},
	&"mom": {"H": ORANGE, "h": RED, "A": ORANGE, "B": SKY, "b": BLUE, "P": NAVY},
	&"swimmer": {"H": SKY, "h": BLUE, "A": SAND, "B": CYAN, "b": SKY, "P": BLUE},
	&"professor": {"H": HAIR, "h": INK, "A": HAIR, "B": WHITE, "b": FOG, "P": SLATE},
}

## Catching orbs: id -> [top color, accent color].
const ORBS := {
	&"mon_orb": [RED, ORANGE],
	&"super_orb": [BLUE, RED],
	&"master_orb": [PLUM, SAND],
}

## Base / shade / highlight colors per monster element.
const ELEMENT_COLORS := {
	&"fire": [ORANGE, RED, SAND],
	&"water": [SKY, BLUE, CYAN],
	&"grass": [GREEN, DEEP, LIME],
	&"rock": [FOG, SLATE, WHITE],
	&"electric": [SAND, ORANGE, WHITE],
	&"ghost": [PLUM, NAVY, Color("9a5aa0")],
}

## Placeholder species: id -> [generator seed, element].
const MONSTERS := {
	&"flamlet": [11, &"fire"],
	&"aquapup": [24, &"water"],
	&"sproutle": [36, &"grass"],
	&"pebblet": [43, &"rock"],
	&"zapkit": [54, &"electric"],
	&"shadeling": [69, &"ghost"],
}

# --- Character sprite patterns (16x16, facing down / up / left) ---------------
# K outline, H hat, h hat shade, A hair, S skin, E eye, W shine, B shirt,
# b shirt shade, P pants. "." is transparent. Right-facing frames are mirrored.
const _FRONT := [
	"................",
	".....KKKKKK.....",
	"....KHHHHHHK....",
	"...KHHHWWHHHK...",
	"...KHHHHHHHHK...",
	"..KhhhhhhhhhhK..",
	"...KSSSSSSSSK...",
	"...KSESSSSESK...",
	"...KSSSSSSSSK...",
	"....KKSSSSKK....",
	"...KBBBBBBBBK...",
	"..KSKBBBBBBKSK..",
	"..KKKbBBBBbKKK..",
	"....KPPPPPPK....",
	"....KPPKKPPK....",
	"....KKK..KKK....",
]
const _BACK := [
	"................",
	".....KKKKKK.....",
	"....KHHHHHHK....",
	"...KHHHHHHHHK...",
	"...KHHHHHHHHK...",
	"..KhhhhhhhhhhK..",
	"...KAAAAAAAAK...",
	"...KAAAAAAAAK...",
	"...KSAAAAAASK...",
	"....KKSSSSKK....",
	"...KBBBBBBBBK...",
	"..KSKBBBBBBKSK..",
	"..KKKbBBBBbKKK..",
	"....KPPPPPPK....",
	"....KPPKKPPK....",
	"....KKK..KKK....",
]
const _SIDE := [
	"................",
	"......KKKKK.....",
	".....KHHHHHK....",
	"....KHHWHHHHK...",
	"....KHHHHHHHK...",
	"..KKhhhhhhhhK...",
	"....KSSSSAAAK...",
	"....KESSSAAAK...",
	"....KSSSSSAK....",
	".....KKSSKK.....",
	"....KBBBBBBK....",
	"....KBBSBBBK....",
	"....KbBSBBbK....",
	".....KPPPPK.....",
	".....KPPPPK.....",
	".....KKKKKK.....",
]
# Leg poses for walking frames (the body above is raised 1px to bob).
const _LEGS_FRONT_A := ["....KPPPPPPK....", "....KPPKKPPK....", "....KPPK.KKK....", "....KKK........."]
const _LEGS_FRONT_B := ["....KPPPPPPK....", "....KPPKKPPK....", "....KKK.KPPK....", ".........KKK...."]
const _LEGS_SIDE_A := [".....KPPPPK.....", "....KPPKKPPK....", "...KPPK..KPPK...", "...KKK....KKK..."]
const _LEGS_SIDE_B := [".....KPPPPK.....", ".....KPPPPK.....", "......KPPK......", "......KKKK......"]

# 8x8 clump repeated four times to make the tall grass tile.
const _TALL_GRASS := [
	".D....D.",
	"DLD..DLD",
	"DLLDDLLD",
	"DGLLLLGD",
	".DGGGGD.",
	"..DDDD..",
	"........",
	"........",
]


# =============================================================================
# Tiles
# =============================================================================

## The full overworld/interior tile atlas (128x64).
static func overworld_tiles() -> Image:
	var img := _new_image(ATLAS_SIZE.x * TILE, ATLAS_SIZE.y * TILE)
	_grass(img, _origin(&"grass"))
	_tall_grass(img, _origin(&"tall_grass"))
	_path(img, _origin(&"path"))
	_flowers(img, _origin(&"flowers"))
	_sand(img, _origin(&"sand"))
	_ledge(img, _origin(&"ledge_down"))
	_tree(img, _origin(&"tree"))
	_cliff(img, _origin(&"cliff"))
	_water(img, _origin(&"water"), 0)
	_water(img, _origin(&"water") + Vector2i(TILE, 0), 1)
	for side: String in ["l", "m", "r"]:
		_roof(img, _origin(StringName("roof_red_" + side)), side, RED, PLUM, ORANGE)
		_roof(img, _origin(StringName("roof_blue_" + side)), side, BLUE, NAVY, SKY)
	_wall(img, _origin(&"wall"))
	_window(img, _origin(&"window"))
	_door(img, _origin(&"door"))
	_fence(img, _origin(&"fence"))
	_floor(img, _origin(&"floor"))
	_indoor_wall(img, _origin(&"indoor_wall"))
	_mat(img, _origin(&"mat"))
	_table(img, _origin(&"table"))
	_bed(img, _origin(&"bed"))
	_shelf(img, _origin(&"shelf"))
	_rect(img, _origin(&"void"), 0, 0, TILE, TILE, INK)
	return img


static func _origin(tile: StringName) -> Vector2i:
	return TILES[tile] * TILE


static func _grass(img: Image, o: Vector2i) -> void:
	_rect(img, o, 0, 0, TILE, TILE, GREEN)
	# Little "v" tufts on a fixed, even scatter so tiles repeat cleanly.
	for p: Vector2i in [Vector2i(2, 3), Vector2i(10, 2), Vector2i(6, 8), Vector2i(12, 10), Vector2i(1, 12), Vector2i(8, 14)]:
		_px(img, o + p, DEEP)
		_px(img, o + p + Vector2i(2, 0), DEEP)
		_px(img, o + p + Vector2i(1, 1), DEEP)
	for p: Vector2i in [Vector2i(5, 4), Vector2i(13, 6), Vector2i(3, 9), Vector2i(11, 13)]:
		_px(img, o + p, LIME)


static func _tall_grass(img: Image, o: Vector2i) -> void:
	_rect(img, o, 0, 0, TILE, TILE, GREEN)
	var colors := {"D": DEEP, "L": LIME, "G": GREEN}
	for q: Vector2i in [Vector2i(0, 1), Vector2i(8, 1), Vector2i(0, 9), Vector2i(8, 9)]:
		_pattern(img, o + q, _TALL_GRASS, colors)


static func _path(img: Image, o: Vector2i) -> void:
	_rect(img, o, 0, 0, TILE, TILE, DIRT)
	for p: Vector2i in [Vector2i(3, 2), Vector2i(11, 5), Vector2i(6, 10), Vector2i(13, 13), Vector2i(1, 14)]:
		_px(img, o + p, DIRT_DARK)
		_px(img, o + p + Vector2i(1, 0), DIRT_DARK)
	for p: Vector2i in [Vector2i(8, 3), Vector2i(2, 7), Vector2i(10, 12)]:
		_px(img, o + p, SAND)


static func _flowers(img: Image, o: Vector2i) -> void:
	_grass(img, o)
	for f in [[Vector2i(4, 4), RED], [Vector2i(11, 11), WHITE], [Vector2i(12, 3), SAND]]:
		var c: Vector2i = o + f[0]
		for d in Grid.DIRECTIONS:
			_px(img, c + d, f[1])
		_px(img, c, SAND if f[1] != SAND else ORANGE)
		_px(img, c + Vector2i(1, 2), DEEP)


static func _sand(img: Image, o: Vector2i) -> void:
	_rect(img, o, 0, 0, TILE, TILE, SAND)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(9, 4), Vector2i(5, 9), Vector2i(13, 11), Vector2i(1, 13), Vector2i(10, 14)]:
		_px(img, o + p, WHITE)
	for p: Vector2i in [Vector2i(12, 7), Vector2i(4, 14)]:
		_px(img, o + p, DIRT)


static func _ledge(img: Image, o: Vector2i) -> void:
	_grass(img, o)
	_rect(img, o, 0, 9, TILE, 1, LIME)       # lip highlight
	_rect(img, o, 0, 10, TILE, 3, TEAL)      # drop face
	_rect(img, o, 0, 13, TILE, 1, DEEP)
	_rect(img, o, 0, 14, TILE, 2, GREEN)     # ground below
	for x in range(1, TILE, 4):
		_px(img, o + Vector2i(x, 11), DEEP)


static func _tree(img: Image, o: Vector2i) -> void:
	_rect(img, o, 0, 0, TILE, TILE, GREEN)
	_rect(img, o, 6, 12, 4, 4, WOOD_DARK)
	_rect(img, o, 7, 12, 1, 4, WOOD)
	_shaded_ellipse(img, o, Vector2(8, 6.5), Vector2(7.5, 6.5), GREEN, DEEP, LIME)


static func _cliff(img: Image, o: Vector2i) -> void:
	_rect(img, o, 0, 0, TILE, TILE, SLATE)
	for row in 3:
		var y := row * 5 + 1
		_rect(img, o, 0, y, TILE, 1, FOG)              # top edge of each stone row
		_rect(img, o, 0, y + 4, TILE, 1, NIGHT)        # mortar line
		var joint := 4 if row % 2 == 0 else 10
		_rect(img, o, joint, y, 1, 4, NIGHT)
	_rect(img, o, 0, 0, TILE, 1, NIGHT)


static func _water(img: Image, o: Vector2i, frame: int) -> void:
	_rect(img, o, 0, 0, TILE, TILE, BLUE)
	var shift := frame * 2
	for p: Vector2i in [Vector2i(1, 3), Vector2i(9, 6), Vector2i(3, 11), Vector2i(11, 13)]:
		var x := (p.x + shift) % TILE
		for step: Vector2i in [Vector2i(0, 0), Vector2i(1, -1), Vector2i(2, -1), Vector2i(3, 0)]:
			_px(img, o + Vector2i((x + step.x) % TILE, p.y + step.y), SKY)
	_px(img, o + Vector2i((6 + shift * 2) % TILE, 1), CYAN)
	_px(img, o + Vector2i((13 + shift * 2) % TILE, 9), CYAN)


static func _roof(img: Image, o: Vector2i, side: String, base: Color, shade: Color, light: Color) -> void:
	_rect(img, o, 0, 0, TILE, TILE, base)
	for y in TILE:
		var band := floori(y / 4.0)
		if y % 4 == 3:
			_rect(img, o, 0, y, TILE, 1, shade)
		elif y % 4 == 0:
			_rect(img, o, 0, y, TILE, 1, light)
		else:
			for x in TILE:
				if (x + band * 4) % 8 == 0:
					_px(img, o + Vector2i(x, y), shade)
	_rect(img, o, 0, 15, TILE, 1, INK)  # eave
	if side == "l":
		_rect(img, o, 0, 0, 1, TILE, INK)
	elif side == "r":
		_rect(img, o, 15, 0, 1, TILE, INK)


static func _wall(img: Image, o: Vector2i) -> void:
	_rect(img, o, 0, 0, TILE, TILE, WHITE)
	for y in range(3, 13, 4):
		_rect(img, o, 0, y, TILE, 1, FOG)
	_rect(img, o, 0, 13, TILE, 2, FOG)
	_rect(img, o, 0, 15, TILE, 1, SLATE)


static func _window(img: Image, o: Vector2i) -> void:
	_wall(img, o)
	_rect(img, o, 3, 2, 10, 10, INK)
	_rect(img, o, 4, 3, 8, 8, SKY)
	_rect(img, o, 4, 6, 8, 1, WOOD_DARK)
	_rect(img, o, 7, 3, 1, 8, WOOD_DARK)
	_px(img, o + Vector2i(5, 4), CYAN)
	_px(img, o + Vector2i(9, 8), CYAN)


static func _door(img: Image, o: Vector2i) -> void:
	_wall(img, o)
	_rect(img, o, 3, 1, 10, 15, INK)
	_rect(img, o, 4, 2, 8, 14, WOOD)
	_rect(img, o, 7, 2, 1, 14, WOOD_DARK)
	_rect(img, o, 4, 8, 8, 1, WOOD_DARK)
	_px(img, o + Vector2i(10, 9), SAND)
	_px(img, o + Vector2i(5, 9), SAND)


static func _fence(img: Image, o: Vector2i) -> void:
	_grass(img, o)
	for y: int in [5, 10]:
		_rect(img, o, 0, y, TILE, 2, WHITE)
		_rect(img, o, 0, y + 2, TILE, 1, FOG)
	for x: int in [2, 12]:
		_rect(img, o, x - 1, 2, 4, 13, INK)
		_rect(img, o, x, 3, 2, 11, WHITE)
		_rect(img, o, x + 1, 4, 1, 10, FOG)


static func _floor(img: Image, o: Vector2i) -> void:
	_rect(img, o, 0, 0, TILE, TILE, WOOD)
	for y in range(3, TILE, 4):
		_rect(img, o, 0, y, TILE, 1, WOOD_DARK)
	for row in 4:
		var x := 5 if row % 2 == 0 else 12
		_rect(img, o, x, row * 4, 1, 3, WOOD_DARK)


static func _indoor_wall(img: Image, o: Vector2i) -> void:
	_rect(img, o, 0, 0, TILE, 11, WHITE)
	for x in range(1, TILE, 4):
		_rect(img, o, x, 0, 1, 11, FOG)
	_rect(img, o, 0, 11, TILE, 4, WOOD)
	_rect(img, o, 0, 11, TILE, 1, WOOD_DARK)
	_rect(img, o, 0, 15, TILE, 1, WOOD_DARK)


static func _mat(img: Image, o: Vector2i) -> void:
	_floor(img, o)
	_rect(img, o, 1, 3, 14, 10, ORANGE)
	_rect(img, o, 2, 4, 12, 8, RED)
	for x in range(3, 13, 2):
		_px(img, o + Vector2i(x, 7), SAND)
		_px(img, o + Vector2i(x + 1, 8), SAND)


static func _table(img: Image, o: Vector2i) -> void:
	_floor(img, o)
	_rect(img, o, 1, 2, 14, 12, INK)
	_rect(img, o, 2, 3, 12, 9, WOOD)
	_rect(img, o, 2, 3, 12, 1, SAND)
	_rect(img, o, 2, 12, 12, 1, WOOD_DARK)
	_rect(img, o, 6, 6, 4, 3, WHITE)  # a plate


static func _bed(img: Image, o: Vector2i) -> void:
	_floor(img, o)
	_rect(img, o, 2, 0, 12, 16, INK)
	_rect(img, o, 3, 1, 10, 4, WHITE)
	_rect(img, o, 3, 5, 10, 10, BLUE)
	_rect(img, o, 3, 5, 10, 1, SKY)
	for y in range(8, 15, 3):
		_rect(img, o, 4, y, 8, 1, SKY)


static func _shelf(img: Image, o: Vector2i) -> void:
	_rect(img, o, 0, 0, TILE, TILE, WOOD_DARK)
	_rect(img, o, 1, 1, 14, 14, HAIR)
	var books := [RED, BLUE, SAND, GREEN, PLUM, SKY, ORANGE]
	for shelf in 2:
		var y := 2 + shelf * 7
		for i in 6:
			var h := 5 - (i * 3 + shelf) % 2
			_rect(img, o, 2 + i * 2, y + (5 - h), 2, h, books[(i + shelf * 3) % books.size()])
		_rect(img, o, 1, y + 5, 14, 1, WOOD)


# =============================================================================
# Characters & objects
# =============================================================================

## A 48x64 walking sprite sheet: columns = stand, step A, step B;
## rows = facing down, up, left, right.
static func character_sheet(colors: Dictionary) -> Image:
	var palette := {"K": INK, "S": SKIN, "E": INK, "W": WHITE}
	palette.merge(colors, true)
	var img := _new_image(TILE * 3, TILE * 4)
	var poses := [
		[_FRONT, _LEGS_FRONT_A, _LEGS_FRONT_B, false],
		[_BACK, _LEGS_FRONT_A, _LEGS_FRONT_B, false],
		[_SIDE, _LEGS_SIDE_A, _LEGS_SIDE_B, false],
		[_SIDE, _LEGS_SIDE_A, _LEGS_SIDE_B, true],
	]
	for row in poses.size():
		var pose: Array = poses[row]
		var frames := [pose[0], _walk_frame(pose[0], pose[1]), _walk_frame(pose[0], pose[2])]
		for col in frames.size():
			_pattern(img, Vector2i(col * TILE, row * TILE), frames[col], palette, pose[3])
	return img


static func _walk_frame(stand: Array, legs: Array) -> Array:
	return stand.slice(1, 13) + legs


## Two 16x16 frames of a sea monster the player rides while surfing.
static func surf_mount() -> Image:
	var img := _new_image(TILE * 2, TILE)
	for frame in 2:
		var o := Vector2i(frame * TILE, 0)
		_shaded_ellipse(img, o, Vector2(8, 11), Vector2(7.5, 4.5), SKY, BLUE, CYAN)
		_shaded_ellipse(img, o, Vector2(8, 6), Vector2(3.5, 3), SKY, BLUE, CYAN)
		_px(img, o + Vector2i(6, 5), INK)
		_px(img, o + Vector2i(9, 5), INK)
		var foam := 0 if frame == 0 else 1
		for x: int in [0, 15]:
			_px(img, o + Vector2i(x, 11 + foam), WHITE)
			_px(img, o + Vector2i(x, 13 - foam), WHITE)
	return img


## Soft drop shadow shown under the player while hopping.
static func shadow() -> Image:
	var img := _new_image(TILE, TILE)
	var c := Color(INK, 0.35)
	for y in TILE:
		for x in TILE:
			var d := Vector2((x + 0.5 - 8.0) / 5.0, (y + 0.5 - 13.0) / 2.0)
			if d.length_squared() <= 1.0:
				img.set_pixel(x, y, c)
	return img


## Small tree that CUT removes.
static func cut_tree() -> Image:
	var img := _new_image(TILE, TILE)
	_rect(img, Vector2i.ZERO, 7, 11, 2, 4, WOOD_DARK)
	_rect(img, Vector2i.ZERO, 5, 15, 6, 1, DEEP)
	_shaded_ellipse(img, Vector2i.ZERO, Vector2(8, 7), Vector2(6, 5.5), LIME, GREEN, WHITE)
	for p: Vector2i in [Vector2i(6, 6), Vector2i(9, 8), Vector2i(8, 4)]:
		_px(img, p, GREEN)
	return img


## Cracked boulder that ROCK SMASH breaks.
static func smash_rock() -> Image:
	var img := _new_image(TILE, TILE)
	_shaded_ellipse(img, Vector2i.ZERO, Vector2(8, 9), Vector2(7, 6), FOG, SLATE, WHITE)
	for p: Vector2i in [Vector2i(8, 4), Vector2i(7, 5), Vector2i(7, 6), Vector2i(8, 7), Vector2i(9, 8), Vector2i(8, 9), Vector2i(10, 8), Vector2i(11, 9)]:
		_px(img, p, NIGHT)
	return img


static func signpost() -> Image:
	var img := _new_image(TILE, TILE)
	_rect(img, Vector2i.ZERO, 7, 10, 2, 6, WOOD_DARK)
	_rect(img, Vector2i.ZERO, 1, 2, 14, 9, INK)
	_rect(img, Vector2i.ZERO, 2, 3, 12, 7, WOOD)
	_rect(img, Vector2i.ZERO, 2, 3, 12, 1, SAND)
	_rect(img, Vector2i.ZERO, 4, 5, 8, 1, WOOD_DARK)
	_rect(img, Vector2i.ZERO, 4, 7, 6, 1, WOOD_DARK)
	return img


## 240x160 grassy battle backdrop with two platforms: the wild monster's at
## the top right, the player's at the bottom left (see BattleScene).
static func battle_background() -> Image:
	var img := _new_image(240, 160)
	# Sky fades from white to cyan through ordered dithering.
	for y in 52:
		for x in 240:
			var t := y / 52.0
			var threshold := (((x % 2) * 2 + (y % 2)) + 0.5) / 4.0
			img.set_pixel(x, y, CYAN if t > threshold else WHITE)
	# A band of distant trees on the horizon.
	for x in 240:
		var top := 44 + roundi(3.0 * sin(x * 0.35) + 2.0 * sin(x * 0.9))
		for y in range(top, 54):
			img.set_pixel(x, y, DEEP if y > top else INK)
	# The field, with light stripes for depth.
	_rect(img, Vector2i.ZERO, 0, 54, 240, 106, LIME)
	for y in range(54, 160):
		if (y - 54) % 6 < 2:
			for x in range(y % 4, 240, 4):
				img.set_pixel(x, y, GREEN)
	_platform(img, Vector2(176, 68), Vector2(46, 10))
	_platform(img, Vector2(64, 114), Vector2(56, 12))
	return img


static func _platform(img: Image, center: Vector2, radius: Vector2) -> void:
	for y in range(floori(center.y - radius.y), ceili(center.y + radius.y) + 1):
		for x in range(floori(center.x - radius.x), ceili(center.x + radius.x) + 1):
			var n := (Vector2(x, y) + Vector2(0.5, 0.5) - center) / radius
			var d := n.length_squared()
			if d > 1.0 or x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var c := GREEN
			if d > 0.8:
				c = DEEP
			elif n.y < -0.3 and d < 0.5:
				c = LIME
			img.set_pixel(x, y, c)


## A 16x16 catching orb: colored top, white bottom, dark band and a button.
static func orb(top: Color, accent: Color) -> Image:
	var img := _new_image(TILE, TILE)
	var center := Vector2(8.0, 8.0)
	for y in TILE:
		for x in TILE:
			var d := (Vector2(x, y) + Vector2(0.5, 0.5)).distance_to(center)
			if d > 6.5:
				continue
			var c := top if y < 7 else WHITE
			if d > 5.6 or y == 7 or y == 8:
				c = INK
			if d <= 2.2:
				c = INK if d > 1.3 else WHITE
			img.set_pixel(x, y, c)
	_px(img, Vector2i(4, 4), WHITE)
	_px(img, Vector2i(5, 3), WHITE)
	# Accent marks on the top half tell the orbs apart.
	for x: int in [6, 9]:
		_px(img, Vector2i(x, 3), accent)
		_px(img, Vector2i(x, 4), accent)
	return img


# =============================================================================
# Monsters
# =============================================================================

## A symmetric 32x32 creature built from a seed: a body, an optional head,
## then random ears or horns, legs, arms and a belly patch. Parts are drawn on
## a 16x16 grid, mirrored, shaded, upscaled 2x and outlined. `back` draws the
## same silhouette seen from behind (no face or belly) for the player's side
## of a battle.
static func monster(seed_value: int, element: StringName, back := false) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var colors: Array = ELEMENT_COLORS.get(element, ELEMENT_COLORS[&"rock"])
	var cells := PackedByteArray()
	cells.resize(256)

	var body_r := Vector2(rng.randf_range(3.5, 6.0), rng.randf_range(3.0, 4.5))
	var body_y := rng.randf_range(8.5, 10.0)
	_ellipse_cells(cells, Vector2(8.0, body_y), body_r)
	var head_r := body_r
	var head_y := body_y
	if rng.randf() < 0.7:
		head_r = Vector2(rng.randf_range(2.5, 4.5), rng.randf_range(2.2, 3.2))
		head_y = body_y - body_r.y - head_r.y * 0.4
		_ellipse_cells(cells, Vector2(8.0, head_y), head_r)
	var head_top := floori(head_y - head_r.y)

	match rng.randi_range(0, 3):
		0: # Pointy ears.
			var x := floori(8.0 - head_r.x * 0.6)
			for i in rng.randi_range(2, 3):
				_mirror_set(cells, x - i, head_top - i)
				_mirror_set(cells, x - i + 1, head_top - i)
		1: # Horns.
			var x := floori(8.0 - head_r.x * 0.4)
			for i in rng.randi_range(2, 3):
				_mirror_set(cells, x, head_top - i)
		2: # Antennae with tips.
			var x := floori(8.0 - head_r.x * 0.3)
			_mirror_set(cells, x, head_top - 1)
			_mirror_set(cells, x - 1, head_top - 2)
			_mirror_set(cells, x - 2, head_top - 2)
			_mirror_set(cells, x - 1, head_top - 3)
	if rng.randf() < 0.85: # Legs.
		var x := floori(8.0 - body_r.x * rng.randf_range(0.35, 0.65))
		var width := rng.randi_range(1, 2)
		for y in range(floori(body_y), 15):
			for w in width:
				_mirror_set(cells, x - w, y)
		_mirror_set(cells, x - width, 14) # Foot.
	if rng.randf() < 0.6: # Arms.
		var y := floori(body_y - rng.randf_range(0.0, body_r.y * 0.5))
		var x := floori(8.0 - body_r.x)
		for i in rng.randi_range(1, 2):
			_mirror_set(cells, x - i, y + i - 1)

	# Shade: highlight on top edges, shadow on side/bottom edges, light belly.
	var small := _new_image(16, 16)
	for y in 16:
		for x in 16:
			if not _cell(cells, x, y):
				continue
			var c: Color = colors[0]
			var belly := Vector2((x + 0.5 - 8.0) / (body_r.x * 0.55), (y + 0.5 - body_y - 1.0) / (body_r.y * 0.6))
			if not _cell(cells, x, y - 1):
				c = colors[2]
			elif not _cell(cells, x, y + 1) or not _cell(cells, x - 1, y) or not _cell(cells, x + 1, y):
				c = colors[1]
			elif belly.length_squared() <= 1.0 and not back:
				c = colors[2]
			small.set_pixel(x, y, c)
	var img := small.duplicate() as Image
	img.resize(32, 32, Image.INTERPOLATE_NEAREST)

	if not back:
		# Dark eyes with a white glint read on every body color.
		var eye_x := floori(8.0 - head_r.x * 0.45)
		var eye_y := floori(head_y - head_r.y * 0.15)
		for ex: int in [eye_x, 15 - eye_x]:
			var p := Vector2i(ex * 2, eye_y * 2)
			img.fill_rect(Rect2i(p, Vector2i(2, 3)), INK)
			img.set_pixel(p.x + (1 if ex < 8 else 0), p.y, WHITE)
	_outline(img, INK)
	return img


static func _ellipse_cells(cells: PackedByteArray, center: Vector2, radius: Vector2) -> void:
	for y in range(1, 15):
		for x in range(1, 15):
			if ((Vector2(x, y) + Vector2(0.5, 0.5) - center) / radius).length_squared() <= 1.0:
				cells[y * 16 + x] = 1


## Sets a cell and its mirror image across the vertical center line.
static func _mirror_set(cells: PackedByteArray, x: int, y: int) -> void:
	if x >= 1 and x <= 14 and y >= 1 and y <= 14:
		cells[y * 16 + x] = 1
		cells[y * 16 + 15 - x] = 1


static func _cell(cells: PackedByteArray, x: int, y: int) -> bool:
	return x >= 0 and x < 16 and y >= 0 and y < 16 and cells[y * 16 + x] == 1


# =============================================================================
# Helpers
# =============================================================================

static func _new_image(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	return img


static func _rect(img: Image, o: Vector2i, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(o.x + x, o.y + y, w, h), c)


static func _px(img: Image, p: Vector2i, c: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixelv(p, c)


## Paints an ASCII pattern; each character is looked up in `colors`, "." is skipped.
static func _pattern(img: Image, o: Vector2i, rows: Array, colors: Dictionary, flip := false) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var key := row[x]
			if key == ".":
				continue
			var px := row.length() - 1 - x if flip else x
			_px(img, o + Vector2i(px, y), colors[key])


## Filled ellipse lit from the top-left, with a 1px outline.
static func _shaded_ellipse(img: Image, o: Vector2i, center: Vector2, radius: Vector2, base: Color, shade: Color, light: Color) -> void:
	var inside := {}
	for y in TILE:
		for x in TILE:
			var n := (Vector2(x, y) + Vector2(0.5, 0.5) - center) / radius
			if n.length_squared() <= 1.0:
				inside[Vector2i(x, y)] = n
	for p: Vector2i in inside:
		var n: Vector2 = inside[p]
		var lit := n.x * 0.4 + n.y * 0.7
		var c := base
		if lit > 0.35:
			c = shade
		elif lit < -0.45:
			c = light
		var edge := false
		for d in Grid.DIRECTIONS:
			if not inside.has(p + d):
				edge = true
		_px(img, o + p, INK if edge else c)


## Adds a 1px outline around every opaque region.
static func _outline(img: Image, color: Color) -> void:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in Grid.DIRECTIONS:
				var p := Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and src.get_pixelv(p).a > 0.0:
					img.set_pixel(x, y, color)
					break
