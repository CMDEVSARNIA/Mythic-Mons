class_name MoveAnimator
extends Node2D
## Battle effects: one animation recipe per move, plus the light bursts, stars,
## stat arrows and sparkles BattleScene uses for orbs, stat changes and
## healing. Effect sprites (EffectDesigns) are spawned as children, above the
## monsters and below the HP panels, and drawn at 2x like the monsters.
##
##     await move_animator.play_move(move, user_sprite, target_sprite)
##
## A move picks its recipe with MoveData.animation. Moves without one fall
## back to a recipe for their category and element (see recipe_for()).

const EFFECT_DIR := "res://assets/placeholder/effects/"
const EFFECTS: Array[StringName] = [&"flame", &"drop", &"bubble", &"leaf", &"rock", &"spark",
	&"shadow", &"glint", &"arrow_up", &"arrow_down", &"impact", &"slash"]
const SIZE := 2.0
const CLEAR := Color(0, 0, 0, 0)

## MoveData.animation -> the method that plays it.
const RECIPES := {
	&"tackle": &"_tackle", &"struggle": &"_tackle", &"quick_hit": &"_quick_hit",
	&"scratch": &"_scratch", &"lick": &"_lick", &"flame_dash": &"_flame_dash",
	&"volt_dash": &"_volt_dash", &"ember": &"_ember", &"heat_wave": &"_heat_wave",
	&"water_gun": &"_water_gun", &"bubblebeam": &"_bubblebeam", &"aqua_blast": &"_aqua_blast",
	&"vine_whip": &"_vine_whip", &"razor_leaf": &"_razor_leaf", &"leaf_storm": &"_leaf_storm",
	&"rock_throw": &"_rock_throw", &"rock_slide": &"_rock_slide", &"spark": &"_spark",
	&"thunder": &"_thunder", &"shade_orb": &"_shade_orb", &"phantasm": &"_phantasm",
	&"growl": &"_growl", &"leer": &"_leer", &"scary_face": &"_scary_face", &"harden": &"_harden",
}
## Recipes for moves without their own, by element.
const PHYSICAL_FALLBACK := {&"fire": &"flame_dash", &"water": &"water_gun", &"grass": &"vine_whip",
	&"rock": &"rock_throw", &"electric": &"volt_dash", &"ghost": &"lick"}
const SPECIAL_FALLBACK := {&"fire": &"ember", &"water": &"water_gun", &"grass": &"razor_leaf",
	&"rock": &"rock_throw", &"electric": &"spark", &"ghost": &"shade_orb"}


## A sound-wave arc for GROWL.
class SoundArc extends Node2D:
	var facing := 0.0
	var radius := 4.0:
		set(value):
			radius = value
			queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, facing - 0.9, facing + 0.9, 10, PixelArt.INK, 4.0)
		draw_arc(Vector2.ZERO, radius, facing - 0.9, facing + 0.9, 10, PixelArt.WHITE, 2.0)


## Tints the battle backdrop behind the monsters (HEAT WAVE, PHANTASM...).
@export var backdrop_tint: ColorRect
## Flashes the whole field (THUNDER, orbs popping open).
@export var flash: ColorRect

var _textures := {}
var _user: Sprite2D
var _target: Sprite2D


func _ready() -> void:
	for id in EFFECTS:
		_textures[id] = load(EFFECT_DIR + id + ".png")


## The recipe `move` plays: its own, or one for its category and element.
static func recipe_for(move: MoveData) -> StringName:
	if RECIPES.has(move.animation):
		return move.animation
	match move.category:
		MoveData.Category.STATUS:
			return &"harden" if move.stat_target == MoveData.Target.SELF else &"leer"
		MoveData.Category.SPECIAL:
			return SPECIAL_FALLBACK.get(StringName(move.element), &"tackle")
	return PHYSICAL_FALLBACK.get(StringName(move.element), &"tackle")


func play_move(move: MoveData, user: Sprite2D, target: Sprite2D) -> void:
	_user = user
	_target = target
	await call(RECIPES[recipe_for(move)])


# --- Effects BattleScene uses directly -----------------------------------------

## The flash and sparkles of an orb popping open at `at`.
func orb_light(at: Vector2) -> void:
	_flash(Color(1, 1, 1, 0.25), 1, 0.04)
	_pop(&"glint", at, 0.3, 1.0, 3.0)
	_burst(&"glint", at, 8, 22.0, 0.35, 1.0)


## Three stars that hop out of an orb as a catch clicks shut.
func catch_stars(at: Vector2) -> void:
	for i in 3:
		var star := _spawn(&"glint", at, 1.0)
		var to := at + Vector2(-18.0 + 18.0 * i, -18.0 + absf(i - 1) * 8.0)
		_fly(star, to, 0.45, 8.0)
		var fade := create_tween()
		fade.tween_interval(0.25)
		fade.tween_property(star, "modulate:a", 0.0, 0.2)


## Arrows rising over a monster whose stat went up, or falling when it fell.
func stat_arrows(sprite: Sprite2D, rise: bool) -> void:
	var effect := &"arrow_up" if rise else &"arrow_down"
	var step := -48.0 if rise else 48.0
	for i in 6:
		var column := -18.0 + 18.0 * (i % 3)
		var arrow := _spawn(effect, sprite.position + Vector2(column, -step / 2.0), 1.5)
		arrow.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(0.08 * i)
		tween.tween_property(arrow, "modulate:a", 0.9, 0.08)
		tween.parallel().tween_property(arrow, "position:y", arrow.position.y + step, 0.45)
		tween.tween_property(arrow, "modulate:a", 0.0, 0.1)
		tween.tween_callback(arrow.queue_free)


## Green sparkles rising around a monster being healed.
func heal_sparkles(sprite: Sprite2D) -> void:
	for i in 5:
		var sparkle := _spawn(&"glint", sprite.position + Vector2(-20.0 + 10.0 * i, 16.0 - 8.0 * (i % 2)), 1.5)
		sparkle.modulate = Color(0.6, 1.6, 0.8, 0.0)
		var tween := create_tween()
		tween.tween_interval(0.07 * i)
		tween.tween_property(sparkle, "modulate:a", 1.0, 0.1)
		tween.parallel().tween_property(sparkle, "position:y", sparkle.position.y - 28.0, 0.5)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.1)
		tween.tween_callback(sparkle.queue_free)


# --- Contact moves -------------------------------------------------------------

func _tackle() -> void:
	await _lunge(16.0, _impact)
	await _wait(0.1)


func _quick_hit() -> void:
	Audio.play_sfx(&"swish")
	_user.modulate.a = 0.5
	await _lunge(26.0, _impact, 0.05)
	_user.modulate.a = 1.0
	await _wait(0.1)


func _scratch() -> void:
	Audio.play_sfx(&"slash")
	var slash := _spawn(&"slash", _target.position + Vector2(8, -8))
	var tween := create_tween()
	tween.tween_property(slash, "position", _target.position + Vector2(-4, 4), 0.12)
	tween.tween_property(slash, "modulate:a", 0.0, 0.18)
	tween.tween_callback(slash.queue_free)
	await tween.finished


func _lick() -> void:
	Audio.play_sfx(&"ghost")
	for i in 3:
		_pop(&"shadow", _target.position + Vector2(-8.0 + 8.0 * i, -8.0 + 6.0 * i), 0.3, 1.0, 2.2)
		await _wait(0.1)
	await _shake(_target)


func _flame_dash() -> void:
	Audio.play_sfx(&"burn")
	var hit := func() -> void:
		_impact()
		_burst(&"flame", _target.position, 6, 24.0, 0.4)
	await _lunge(16.0, hit)
	await _wait(0.3)


func _volt_dash() -> void:
	Audio.play_sfx(&"zap")
	var hit := func() -> void:
		_impact()
		_flash(Color(1, 1, 1, 0.5), 1, 0.04)
		_burst(&"spark", _target.position, 5, 22.0, 0.35, 1.5)
	await _lunge(18.0, hit)
	await _wait(0.3)


# --- Fire ----------------------------------------------------------------------

func _ember() -> void:
	Audio.play_sfx(&"burn")
	var aims: Array[Vector2] = [Vector2(-6, -4), Vector2(6, 2), Vector2(0, -10)]
	for aim in aims:
		_fly(_spawn(&"flame", _user.position), _target.position + aim, 0.3, 14.0)
		await _wait(0.12)
	await _wait(0.2)
	await _burst(&"flame", _target.position, 4, 14.0, 0.3).finished


func _heat_wave() -> void:
	Audio.play_sfx(&"burn")
	await _tint(Color(PixelArt.ORANGE, 0.45))
	# A wall of flame rolls across to the target.
	for i in 5:
		for row in 3:
			var lane := Vector2(0.0, -18.0 + 18.0 * row)
			_fly(_spawn(&"flame", _user.position + lane), _target.position + lane, 0.45)
		await _wait(0.08)
	await _wait(0.4)
	Audio.play_sfx(&"burn")
	await _burst(&"flame", _target.position, 8, 26.0, 0.4).finished
	await _tint(CLEAR)


# --- Water ---------------------------------------------------------------------

func _water_gun() -> void:
	Audio.play_sfx(&"splash")
	await _stream(8, 0.05)
	await _burst(&"drop", _target.position, 5, 18.0, 0.3).finished


func _bubblebeam() -> void:
	Audio.play_sfx(&"bubble")
	for i in 6:
		var bubble := _spawn(&"bubble", _user.position, 1.5 + 0.5 * (i % 2))
		_fly(bubble, _target.position + Vector2(-8.0 + 4.0 * i, -10.0 + 5.0 * (i % 3)), 0.5, 10.0 if i % 2 == 0 else -10.0)
		await _wait(0.08)
	await _wait(0.4)
	Audio.play_sfx(&"bubble")
	for i in 3:
		_pop(&"bubble", _target.position + Vector2(-10.0 + 10.0 * i, -6.0 + 6.0 * (i % 2)), 0.25, 2.0, 3.5)
	await _wait(0.25)


func _aqua_blast() -> void:
	Audio.play_sfx(&"splash")
	await _tint(Color(PixelArt.BLUE, 0.4))
	await _stream(14, 0.03)
	Audio.play_sfx(&"splash")
	_burst(&"bubble", _target.position, 6, 28.0, 0.4, 1.5)
	await _burst(&"drop", _target.position, 8, 26.0, 0.4).finished
	await _tint(CLEAR)


# --- Grass ---------------------------------------------------------------------

func _vine_whip() -> void:
	Audio.play_sfx(&"slash")
	for i in 2:
		await _vine(1.0 if i == 0 else -1.0)
		_impact(_target.position + Vector2(-6.0 + 12.0 * i, -6.0))
		await _wait(0.1)
	await _wait(0.1)


func _razor_leaf() -> void:
	Audio.play_sfx(&"leaf")
	for i in 6:
		var aim := Vector2(0.0, -8.0 + 8.0 * (i % 3))
		_fly(_spawn(&"leaf", _user.position), _target.position + aim, 0.45, 18.0 if i % 2 == 0 else -14.0, TAU * 2.0)
		await _wait(0.07)
	await _wait(0.4)
	_impact()
	await _wait(0.2)


func _leaf_storm() -> void:
	Audio.play_sfx(&"leaf")
	await _tint(Color(PixelArt.GREEN, 0.4))
	# Leaves whirl in from all around and close on the target.
	for i in 14:
		var from := _target.position + Vector2.from_angle(TAU * i / 14.0) * 90.0
		_fly(_spawn(&"leaf", from), _target.position, 0.55, 20.0, TAU * 3.0)
		if i % 4 == 0:
			Audio.play_sfx(&"leaf")
		await _wait(0.04)
	await _wait(0.5)
	_impact()
	await _burst(&"leaf", _target.position, 8, 28.0, 0.4).finished
	await _tint(CLEAR)


# --- Rock ----------------------------------------------------------------------

func _rock_throw() -> void:
	for i in 2:
		_drop_rock(_target.position + Vector2(-10.0 + 20.0 * i, 0.0))
		await _wait(0.15)
	await _wait(0.45)


func _rock_slide() -> void:
	for i in 6:
		_drop_rock(_target.position + Vector2(-24.0 + 10.0 * i, -4.0 + 4.0 * (i % 2)))
		await _wait(0.08)
	await _shake(_target, 3.0, 8, 0.05)
	await _wait(0.1)


# --- Electric ------------------------------------------------------------------

func _spark() -> void:
	Audio.play_sfx(&"zap")
	for i in 3:
		_pop(&"spark", _user.position + Vector2(-14.0 + 14.0 * i, -12.0 + 6.0 * (i % 2)), 0.2, 1.0, 2.0)
		await _wait(0.06)
	for i in 4:
		_fly(_spawn(&"spark", _user.position, 1.5), _target.position + Vector2(-8.0 + 5.0 * i, -6.0 + 4.0 * (i % 2)), 0.25, 8.0 if i % 2 else -8.0)
		await _wait(0.05)
	await _wait(0.25)
	Audio.play_sfx(&"zap")
	_flash(Color(1, 1, 1, 0.5), 1, 0.05)
	await _burst(&"spark", _target.position, 5, 20.0, 0.3).finished


func _thunder() -> void:
	Audio.play_sfx(&"thunder")
	await _flash(Color(1, 1, 1, 0.8), 1, 0.05)
	var bolt := _bolt(_target.position)
	for i in 4:
		bolt.visible = i % 2 == 0
		await _wait(0.07)
	bolt.show()
	await _flash(Color(PixelArt.SAND, 0.6), 1, 0.06)
	_burst(&"spark", _target.position, 6, 24.0, 0.35)
	await _wait(0.2)
	bolt.queue_free()
	await _wait(0.15)


# --- Ghost ---------------------------------------------------------------------

func _shade_orb() -> void:
	Audio.play_sfx(&"ghost")
	var orb := _spawn(&"shadow", _user.position, 0.5)
	var grow := create_tween()
	grow.tween_property(orb, "scale", Vector2.ONE * 2.5, 0.25)
	await grow.finished
	await _fly(orb, _target.position, 0.3).finished
	await _burst(&"shadow", _target.position, 6, 22.0, 0.35, 1.5).finished


func _phantasm() -> void:
	Audio.play_sfx(&"ghost")
	await _tint(Color(0.12, 0.02, 0.18, 0.7), 0.25)
	# Six shades circle the target, closing in.
	var shades: Array[Sprite2D] = []
	for i in 6:
		shades.append(_spawn(&"shadow", _target.position, 1.5))
	var center := _target.position
	var orbit := func(t: float) -> void:
		for i in shades.size():
			var angle := TAU * i / shades.size() + t * TAU * 1.5
			shades[i].position = center + Vector2.from_angle(angle) * lerpf(44.0, 4.0, t)
	var tween := create_tween()
	tween.tween_method(orbit, 0.0, 1.0, 0.8)
	await tween.finished
	for shade in shades:
		shade.queue_free()
	Audio.play_sfx(&"ghost")
	_flash(Color(PixelArt.MAUVE, 0.6), 1, 0.06)
	await _burst(&"shadow", _target.position, 8, 28.0, 0.35, 1.5).finished
	await _tint(CLEAR, 0.25)


# --- Status --------------------------------------------------------------------

func _growl() -> void:
	Audio.play_sfx(&"growl")
	var dir := (_target.position - _user.position).normalized()
	for i in 3:
		var arc := SoundArc.new()
		arc.facing = dir.angle()
		arc.position = _user.position + dir * 14.0
		add_child(arc)
		var tween := create_tween().set_parallel()
		tween.tween_property(arc, "position", _user.position + dir * 64.0, 0.45)
		tween.tween_property(arc, "radius", 16.0, 0.45)
		tween.tween_property(arc, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(arc.queue_free)
		await _wait(0.12)
	await _wait(0.35)
	await _shake(_target, 2.0)


func _leer() -> void:
	Audio.play_sfx(&"glint")
	# The user's eyes glint.
	for x: float in [-7.0, 7.0]:
		_pop(&"glint", _user.position + Vector2(x, -10.0), 0.4, 0.5, 2.5)
	await _wait(0.4)
	await _shake(_target, 3.0, 6)


func _scary_face() -> void:
	Audio.play_sfx(&"growl")
	await _tint(Color(0, 0, 0, 0.55))
	var size := _user.scale
	var loom := create_tween()
	loom.tween_property(_user, "scale", size * 1.2, 0.15)
	loom.tween_interval(0.3)
	loom.tween_property(_user, "scale", size, 0.15)
	_shake(_target, 2.0, 10, 0.03)
	await loom.finished
	await _tint(CLEAR)


func _harden() -> void:
	Audio.play_sfx(&"glint")
	var shine := create_tween()
	for i in 2:
		shine.tween_property(_user, "modulate", Color(2.2, 2.2, 2.4), 0.1)
		shine.tween_property(_user, "modulate", Color.WHITE, 0.1)
	for i in 3:
		_pop(&"glint", _user.position + Vector2(-16.0 + 16.0 * i, -14.0 + 12.0 * (i % 2)), 0.3, 0.5, 2.0)
	await shine.finished
	await _wait(0.1)


# --- Building blocks -----------------------------------------------------------

func _spawn(effect: StringName, at: Vector2, size := SIZE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _textures[effect]
	sprite.position = at
	sprite.scale = Vector2.ONE * size
	add_child(sprite)
	return sprite


## Moves `sprite` to `to` along an arc `arc` pixels high, turning `spin`
## radians, then frees it.
func _fly(sprite: Sprite2D, to: Vector2, seconds: float, arc := 0.0, spin := 0.0) -> Tween:
	var from := sprite.position
	var start_angle := sprite.rotation
	var travel := func(t: float) -> void:
		sprite.position = from.lerp(to, t) + Vector2(0.0, -arc * sin(t * PI))
		sprite.rotation = start_angle + spin * t
	var tween := create_tween()
	tween.tween_method(travel, 0.0, 1.0, seconds)
	tween.tween_callback(sprite.queue_free)
	return tween


## Grows an effect at `at` while it fades: hit sparks, splashes, puffs.
func _pop(effect: StringName, at: Vector2, seconds := 0.25, from_size := 1.0, to_size := 2.5) -> Tween:
	var sprite := _spawn(effect, at, from_size)
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale", Vector2.ONE * to_size, seconds)
	tween.tween_property(sprite, "modulate:a", 0.0, seconds).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(sprite.queue_free)
	return tween


## Scatters `count` copies of an effect outward from `at`.
func _burst(effect: StringName, at: Vector2, count := 6, radius := 22.0, seconds := 0.35, size := SIZE) -> Tween:
	var last: Tween
	for i in count:
		var sprite := _spawn(effect, at, size)
		var tween := create_tween().set_parallel()
		tween.tween_property(sprite, "position", at + Vector2.from_angle(TAU * i / count - PI / 2.0) * radius, seconds).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "modulate:a", 0.0, seconds).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(sprite.queue_free)
		last = tween
	return last


func _impact(at := Vector2.INF) -> void:
	_pop(&"impact", _target.position if at == Vector2.INF else at, 0.25, 1.0, 2.5)


## The user rushes at the target; `on_contact` runs at the moment of impact.
func _lunge(reach: float, on_contact := Callable(), seconds := 0.1) -> void:
	var home := _user.position
	var tween := create_tween()
	tween.tween_property(_user, "position", home + (_target.position - home).normalized() * reach, seconds).set_ease(Tween.EASE_IN)
	await tween.finished
	if on_contact.is_valid():
		on_contact.call()
	tween = create_tween()
	tween.tween_property(_user, "position", home, 0.15).set_ease(Tween.EASE_OUT)
	await tween.finished


## Drops of water shot from the user to the target, one after another.
func _stream(count: int, gap: float) -> void:
	var dir := (_target.position - _user.position).normalized()
	for i in count:
		var drop := _spawn(&"drop", _user.position + dir * 10.0)
		drop.rotation = dir.angle() + PI / 2.0
		_fly(drop, _target.position + Vector2(0.0, -4.0 + 4.0 * (i % 3)), 0.25)
		await _wait(gap)
	await _wait(0.25)


## A vine lashes out from the user and snaps back. `bend` picks the side it
## curves to.
func _vine(bend: float) -> void:
	var outline := Line2D.new()
	outline.width = 6.0
	outline.default_color = PixelArt.INK
	var vine := Line2D.new()
	vine.width = 3.0
	vine.default_color = PixelArt.GREEN
	add_child(outline)
	add_child(vine)
	var from := _user.position
	var to := _target.position
	var bulge := (to - from).orthogonal().normalized() * 30.0 * bend
	var grow := func(t: float) -> void:
		var points := PackedVector2Array()
		for i in 13:
			var u := t * i / 12.0
			points.append(from.lerp(to, u) + bulge * sin(u * PI))
		outline.points = points
		vine.points = points
	var tween := create_tween()
	tween.tween_method(grow, 0.0, 1.0, 0.14)
	tween.tween_interval(0.06)
	tween.tween_method(grow, 1.0, 0.0, 0.12)
	await tween.finished
	outline.queue_free()
	vine.queue_free()


## A jagged lightning bolt from the top of the screen down to `to`.
func _bolt(to: Vector2) -> Line2D:
	var points := PackedVector2Array([Vector2(to.x, -8.0)])
	var y := -8.0
	while y < to.y:
		y = minf(y + 12.0, to.y)
		points.append(Vector2(to.x + (7.0 if points.size() % 2 else -7.0), y))
	points.append(to)
	var bolt := Line2D.new()
	bolt.width = 5.0
	bolt.default_color = PixelArt.SAND
	bolt.points = points
	var core := Line2D.new()
	core.width = 2.0
	core.default_color = PixelArt.WHITE
	core.points = points
	bolt.add_child(core)
	add_child(bolt)
	return bolt


func _drop_rock(at: Vector2) -> void:
	Audio.play_sfx(&"rock")
	var rock := _spawn(&"rock", at + Vector2(0.0, -80.0))
	var tween := create_tween()
	tween.tween_property(rock, "position:y", at.y, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_impact.bind(at))
	tween.tween_property(rock, "modulate:a", 0.0, 0.2)
	tween.tween_callback(rock.queue_free)


func _shake(sprite: Sprite2D, amount := 3.0, times := 4, step := 0.04) -> void:
	var home_x := sprite.position.x
	var tween := create_tween()
	for i in times:
		tween.tween_property(sprite, "position:x", home_x + (amount if i % 2 == 0 else -amount), step)
	tween.tween_property(sprite, "position:x", home_x, step)
	await tween.finished


func _tint(color: Color, seconds := 0.2) -> void:
	var tween := create_tween()
	tween.tween_property(backdrop_tint, "color", color, seconds)
	await tween.finished


func _flash(color: Color, times := 1, seconds := 0.06) -> void:
	for i in times:
		flash.color = color
		await _wait(seconds)
		flash.color = Color(color, 0.0)
		await _wait(seconds)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
