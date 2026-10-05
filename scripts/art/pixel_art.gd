class_name PixelArt
extends RefCounted
## Procedural 8-bit art: characters, monsters, items, battle effects, the
## player's battle back sprite, the surf mount and the hop shadow. (Map tiles, signs and the battle backdrop come from
## ArMM1998's sheet instead; see WorldTiles and tools/import_world_art.gd.)
##
## Every function returns an Image. tools/generate_placeholder_art.gd saves them
## as PNGs under res://assets/placeholder/, and scenes use those files. Replace
## a PNG with real art of the same size and layout and nothing else has to
## change.
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
const SKIN_SHADE := Color("d9a07c")
const HAIR := Color("4a2c2a")
const PINK := Color("f29ab4")
const PINK_DARK := Color("c45a7c")
const MAUVE := Color("9a5aa0")
const CLEAR := Color(0, 0, 0, 0)

## The cast: id -> [head, body, colors]. Parts are drawn in CharacterDesigns;
## the color letters are explained there. tools/generate_placeholder_art.gd
## saves "player" as characters/player.png and the rest as npc_<id>.png.
const CHARACTERS := {
	&"player": [&"cap", &"pack", {"H": RED, "h": PLUM, "A": WHITE, "R": HAIR, "r": INK, "B": BLUE, "b": NAVY, "X": SAND, "x": WOOD, "P": NIGHT, "F": RED}],
	&"professor": [&"prof", &"coat", {"H": FOG, "h": SLATE, "G": INK, "L": CYAN, "C": WHITE, "c": FOG, "B": TEAL, "P": SLATE, "F": WOOD_DARK}],
	&"mom": [&"long", &"apron", {"H": ORANGE, "h": RED, "B": SKY, "b": BLUE, "C": WHITE, "c": FOG, "P": SKY, "F": NIGHT}],
	&"lass": [&"pigtails", &"dress", {"H": SAND, "h": ORANGE, "A": RED, "B": PINK, "b": PINK_DARK, "P": RED, "F": NIGHT}],
	&"elder": [&"elder", &"robe", {"H": WHITE, "h": FOG, "B": PLUM, "b": NAVY, "F": WOOD_DARK}],
	&"hiker": [&"bandana", &"pack", {"A": ORANGE, "a": RED, "H": HAIR, "h": INK, "B": GREEN, "b": TEAL, "X": WOOD, "x": WOOD_DARK, "P": WOOD_DARK, "F": INK}],
	&"swimmer": [&"swimcap", &"swim", {"H": SKY, "h": BLUE, "G": INK, "L": WHITE, "B": ORANGE, "b": RED}],
	&"rival": [&"spiky", &"jacket", {"H": WOOD, "h": WOOD_DARK, "B": PLUM, "b": NAVY, "C": WHITE, "P": NIGHT, "F": SLATE}],
	&"nurse": [&"nurse", &"apron", {"H": PINK, "h": PINK_DARK, "A": RED, "B": PINK, "b": PINK_DARK, "C": WHITE, "c": FOG, "P": PINK, "F": WHITE}],
	&"clerk": [&"cap", &"apron", {"H": GREEN, "h": DEEP, "A": WHITE, "R": HAIR, "r": INK, "B": GREEN, "b": DEEP, "C": WHITE, "c": FOG, "P": NIGHT, "F": INK}],
}

## Item icons: id -> colors for the letters in ItemDesigns.
## tools/generate_placeholder_art.gd saves items/<id>.png, plus
## items/<id>_open.png for orbs.
const ITEMS := {
	&"mon_orb": {"A": RED, "a": PLUM, "H": PINK},
	&"super_orb": {"A": BLUE, "a": NAVY, "H": SKY, "X": RED, "x": PLUM},
	&"hyper_orb": {"A": NIGHT, "a": INK, "H": SLATE, "X": SAND, "x": ORANGE},
	&"master_orb": {"A": PLUM, "a": NAVY, "H": MAUVE, "X": PINK, "Y": SAND},
	&"net_orb": {"A": TEAL, "a": NAVY, "H": CYAN, "X": CYAN},
	&"dive_orb": {"A": BLUE, "a": NAVY, "H": SKY, "X": CYAN},
	&"nest_orb": {"A": LIME, "a": GREEN, "H": WHITE, "X": GREEN, "x": DEEP},
	&"repeat_orb": {"A": ORANGE, "a": RED, "H": WHITE, "X": SAND},
	&"timer_orb": {"A": WHITE, "a": FOG, "X": RED},
	&"gala_orb": {"A": WHITE, "a": FOG, "X": RED},
	&"potion": {"A": MAUVE, "a": PLUM, "H": PINK, "X": RED},
	&"big_potion": {"A": ORANGE, "a": RED, "H": SAND, "X": BLUE},
	&"bolt_stone": {"A": GREEN, "a": DEEP, "H": LIME, "X": SAND},
	&"dusk_stone": {"A": NIGHT, "a": NAVY, "H": SLATE, "X": PLUM, "Y": CYAN},
}

## Battle effects: id -> colors for the letters in EffectDesigns.
## tools/generate_placeholder_art.gd saves effects/<id>.png.
const EFFECTS := {
	&"flame": {"R": RED, "O": ORANGE, "Y": SAND, "W": WHITE},
	&"drop": {"L": CYAN, "B": SKY, "b": BLUE, "W": WHITE},
	&"bubble": {"B": SKY, "b": BLUE, "W": WHITE},
	&"leaf": {"G": GREEN, "L": LIME, "g": DEEP},
	&"rock": {"R": FOG, "r": SLATE, "L": WHITE},
	&"spark": {"W": WHITE, "Y": SAND},
	&"shadow": {"P": PLUM, "M": MAUVE, "n": NAVY},
	&"glint": {"W": WHITE, "Y": SAND},
	&"arrow_up": {"A": SAND, "a": ORANGE},
	&"arrow_down": {"A": SKY, "a": BLUE},
	&"impact": {"W": WHITE, "Y": SAND},
	&"slash": {"W": WHITE},
	&"exclaim": {"K": INK, "W": WHITE, "R": RED},
	&"party_ok": {"K": INK, "W": WHITE, "w": FOG, "R": RED, "L": PINK},
	&"party_fainted": {"K": INK, "w": FOG, "s": SLATE},
	&"party_empty": {"K": INK},
}

## Trainers you battle: class -> colors for the letters in
## TrainerDesigns.FRONTS. tools/generate_placeholder_art.gd saves
## trainers/<class>.png.
const TRAINERS := {
	&"youngster": {"H": ORANGE, "h": RED, "B": RED, "b": PLUM, "C": WHITE, "Y": SAND, "P": NIGHT, "F": WOOD_DARK},
	&"lass": {"H": SAND, "h": ORANGE, "A": RED, "B": PINK, "b": PINK_DARK, "C": WHITE, "F": RED},
	&"rival": {"H": WOOD, "h": WOOD_DARK, "B": PLUM, "b": NAVY, "C": WHITE, "P": NAVY, "F": SLATE},
}

## Colors for the letters in TrainerDesigns.PLAYER_BACK: the player's cap,
## hair, skin, shirt, backpack, and the orb in hand.
const TRAINER_BACK := {
	"L": PINK, "R": RED, "r": PLUM, "P": PLUM, "H": HAIR, "h": INK, "S": SKIN, "s": SKIN_SHADE,
	"B": BLUE, "b": NAVY, "X": SAND, "x": WOOD, "y": WOOD_DARK, "F": FOG,
	"K": INK, "W": WHITE, "w": FOG, "O": RED, "o": PLUM,
}

## Base / shade / highlight colors per monster element.
const ELEMENT_COLORS := {
	&"fire": [ORANGE, RED, SAND],
	&"water": [SKY, BLUE, CYAN],
	&"grass": [GREEN, DEEP, LIME],
	&"rock": [FOG, SLATE, WHITE],
	&"electric": [SAND, ORANGE, WHITE],
	&"ghost": [PLUM, NAVY, MAUVE],
}

## Monster battle sprites: id -> colors for the letters in MonsterDesigns.
## tools/generate_placeholder_art.gd saves monsters/<id>.png and <id>_back.png.
const MONSTERS := {
	&"flamlet": {"B": ORANGE, "b": RED, "L": SAND, "R": RED, "O": ORANGE, "Y": SAND},
	&"blazard": {"B": RED, "b": PLUM, "L": ORANGE, "C": SAND, "c": ORANGE, "H": SAND, "h": ORANGE, "O": ORANGE, "Y": SAND},
	&"aquapup": {"B": SKY, "b": BLUE, "L": CYAN, "A": CYAN, "a": BLUE, "m": FOG},
	&"tidehound": {"B": BLUE, "b": NAVY, "L": SKY, "A": CYAN, "a": SKY, "m": FOG},
	&"sproutle": {"B": GREEN, "b": DEEP, "L": LIME, "S": WOOD, "s": WOOD_DARK, "T": SAND, "t": DIRT_DARK, "G": GREEN, "g": DEEP},
	&"grovetle": {"B": GREEN, "b": DEEP, "L": LIME, "S": WOOD, "s": WOOD_DARK, "T": SAND, "t": DIRT_DARK, "G": LIME, "g": GREEN, "D": DEEP},
	&"pebblet": {"B": FOG, "b": SLATE, "L": WHITE, "N": NIGHT, "G": GREEN, "g": DEEP},
	&"bouldron": {"B": FOG, "b": SLATE, "L": WHITE, "N": NIGHT, "G": GREEN, "g": DEEP, "C": CYAN, "c": SKY},
	&"zapkit": {"B": SAND, "b": ORANGE, "L": WHITE, "A": NIGHT, "P": PINK, "Y": SAND, "y": ORANGE, "m": FOG},
	&"voltvix": {"B": SAND, "b": ORANGE, "L": WHITE, "A": NIGHT, "P": PINK, "C": CYAN, "Y": SAND, "y": ORANGE, "m": FOG},
	&"shadeling": {"B": PLUM, "b": NAVY, "L": MAUVE, "C": CYAN, "c": SKY},
	&"duskwraith": {"B": PLUM, "b": NAVY, "L": MAUVE, "C": CYAN, "c": SKY, "H": NIGHT, "h": NAVY},
}

## Quick stand-ins for species nobody has drawn yet: id -> [seed, element],
## e.g. `&"newmon": [7, &"fire"]`. Try seeds until one looks right.
const GENERATED_MONSTERS := {}

# =============================================================================
# Characters & objects
# =============================================================================

## A 48x64 walking sprite sheet for a CHARACTERS id: columns = stand, step A,
## step B; rows = facing down, up, left, right.
static func character_sheet(id: StringName) -> Image:
	var design: Array = CHARACTERS[id]
	var head: Dictionary = CharacterDesigns.HEADS[design[0]]
	var body: Dictionary = CharacterDesigns.BODIES[design[1]]
	var palette := {"K": INK, "S": SKIN, "s": SKIN_SHADE, "E": INK, "W": WHITE}
	palette.merge(design[2], true)
	var img := _new_image(TILE * 3, TILE * 4)
	var views := [ # [head view, body view, leg poses, mirrored]
		["front", "front", "walk_front", false],
		["back", "back", "walk_front", false],
		["side", "side", "walk_side", false],
		["side", "side", "walk_side", true],
	]
	for row in views.size():
		var view: Array = views[row]
		var stand := _compose(head[view[0]], body.get(view[1], body["front"]))
		var legs: Array = body[view[2]]
		var frames := [stand, stand.slice(1, 13) + legs[0], stand.slice(1, 13) + legs[1]]
		for col in frames.size():
			_pattern(img, Vector2i(col * TILE, row * TILE), frames[col], palette, view[3])
	return img


## Lays a head over a body: body rows fill 10-15, then head rows (from row 0)
## are drawn on top, so long hair and beards can overlap the shoulders.
static func _compose(head_rows: Array, body_rows: Array) -> Array:
	var grid: Array = []
	for y in TILE:
		grid.append(".".repeat(TILE))
	for layer: Array in [[body_rows, 10], [head_rows, 0]]:
		var rows: Array = layer[0]
		for i in rows.size():
			var line: String = grid[layer[1] + i]
			var part: String = rows[i]
			for x in TILE:
				if part[x] != ".":
					line[x] = part[x]
			grid[layer[1] + i] = line
	return grid


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


## The 96x32 battle sheet of the player from behind: stand, wind up, throw.
static func trainer_back_sheet() -> Image:
	var sheet := _new_image(96, 32)
	for i in TrainerDesigns.PLAYER_BACK.size():
		var frame := _new_image(32, 32)
		_pattern(frame, Vector2i.ZERO, TrainerDesigns.PLAYER_BACK[i], TRAINER_BACK)
		_outline(frame, INK)
		sheet.blit_rect(frame, Rect2i(0, 0, 32, 32), Vector2i(i * 32, 0))
	return sheet


## A 32x32 battle sprite of a trainer you face, from TrainerDesigns.FRONTS.
static func trainer_front(trainer_class: StringName) -> Image:
	var palette := {"S": SKIN, "s": SKIN_SHADE, "E": INK, "K": INK, "W": WHITE, "M": PINK_DARK}
	palette.merge(TRAINERS[trainer_class], true)
	var img := _new_image(32, 32)
	_pattern(img, Vector2i.ZERO, TrainerDesigns.FRONTS[trainer_class], palette)
	_outline(img, INK)
	return img


# =============================================================================
# Items & effects
# =============================================================================

## A 16x16 item icon drawn in ItemDesigns.
static func item(id: StringName) -> Image:
	var palette := {"K": INK, "W": WHITE, "w": FOG, "s": SLATE}
	palette.merge(ITEMS[id], true)
	var img := _new_image(TILE, TILE)
	_pattern(img, Vector2i.ZERO, ItemDesigns.ITEMS[id], palette)
	return img


## The orb popped open: its lid (rows 2-7) lifts two pixels and light pours
## out where the band was. Every orb shares the silhouette this assumes.
static func orb_open(id: StringName) -> Image:
	var closed := item(id)
	var img := _new_image(TILE, TILE)
	img.blit_rect(closed, Rect2i(0, 2, TILE, 6), Vector2i(0, 0))
	img.blit_rect(closed, Rect2i(0, 9, TILE, 7), Vector2i(0, 9))
	for x in range(3, 14):
		img.set_pixel(x, 6, INK) # Underside of the lid.
		img.set_pixel(x, 9, INK) # Rim of the bottom half.
	for y in [7, 8]:
		for x in range(2, 15):
			var c := CYAN if x < 5 or x > 11 else WHITE
			img.set_pixel(x, y, INK if x == 2 or x == 14 else c)
	return img


## A battle effect drawn in EffectDesigns.
static func effect(id: StringName) -> Image:
	var rows: Array = EffectDesigns.EFFECTS[id]
	var img := _new_image(rows[0].length(), rows.size())
	_pattern(img, Vector2i.ZERO, rows, EFFECTS[id])
	if id in EffectDesigns.OUTLINED:
		_outline(img, INK)
	return img


# =============================================================================
# Monsters
# =============================================================================

## A 32x32 battle sprite drawn in MonsterDesigns, with an ink outline added
## around the silhouette. `back` is the view from behind, used for the
## player's side of a battle.
static func monster(id: StringName, back := false) -> Image:
	var rows: Array = MonsterDesigns.MONSTERS[id]["back" if back else "front"]
	var palette := {"K": INK, "E": INK, "W": WHITE}
	palette.merge(MONSTERS[id], true)
	var img := _new_image(rows[0].length(), rows.size())
	_pattern(img, Vector2i.ZERO, rows, palette)
	_outline(img, INK)
	return img


## A stand-in for GENERATED_MONSTERS: a symmetric 32x32 creature built from
## a seed. A body, an optional head, then random ears or horns, legs, arms and
## a belly patch, drawn on a 16x16 grid, mirrored, shaded, upscaled 2x and
## outlined. `back` draws the same silhouette without the face or belly.
static func generated_monster(seed_value: int, element: StringName, back := false) -> Image:
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
