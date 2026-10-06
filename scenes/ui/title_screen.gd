class_name TitleScreen
extends Control
## The title screen: a dawn sky with twinkling stars, drifting clouds and the
## sun coming up behind the hills, the MYTHIC MONS logo, the three starters on
## a hill and a GALEHAWK gliding past. PRESS START, then a menu.
##
##     await title_screen.open()            # logo drops in; waits for START or A
##     var pick: int = await title_screen.choose(["NEW GAME", "OPTION"])
##     title_screen.show_backdrop()         # just the scenery (the new-game intro)
##
## The scenery is drawn in _draw(), so it scales with the 240 x 160 screen.

signal _started

const HORIZON := 96
## Sky bands, top to bottom: [color, height].
const SKY := [
	[PixelArt.NIGHT, 18], [PixelArt.NAVY, 16], [PixelArt.PLUM, 16], [PixelArt.MAUVE, 14],
	[PixelArt.RED, 12], [PixelArt.ORANGE, 10], [PixelArt.SAND, 10],
]
const STARTERS: Array[StringName] = [&"flamlet", &"aquapup", &"sproutle"]
const BIRD_SECONDS := 7.0
const BIRD_PAUSE := 5.0
const SILHOUETTE := Color(0.22, 0.17, 0.36)
## Low in the sky to the right of the starters, half behind the far hills.
const SUN := Vector2(214, 80)

var _time := 0.0
var _waiting := false
var _stars: Array[Vector3] = [] # x, y, twinkle phase
var _clouds: Array[Vector3] = [] # x, y, speed
var _starters: Array[Sprite2D] = []

@onready var _logo: Control = $Logo
@onready var _press_start: Label = $PressStart
@onready var _version: Label = $Version
@onready var _menu: ChoiceBox = $MenuArea/Menu
@onready var _bird: Sprite2D = $Bird


func _ready() -> void:
	hide()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 18:
		_stars.append(Vector3(rng.randi_range(4, 236), rng.randi_range(2, 40), rng.randf() * TAU))
	for i in 3:
		_clouds.append(Vector3(rng.randi_range(0, 240), 30 + 14 * i, 4.0 + 3.0 * i))
	for i in STARTERS.size():
		var sprite := Sprite2D.new()
		sprite.texture = GameData.species(STARTERS[i]).front_texture
		sprite.position = Vector2(64 + 56 * i, _hill_y(64 + 56 * i) - 14)
		add_child(sprite)
		move_child(sprite, _bird.get_index())
		_starters.append(sprite)
	_bird.texture = GameData.species(&"galehawk").front_texture
	_bird.modulate = SILHOUETTE
	_version.text = "VER %s" % ProjectSettings.get_setting("application/config/version", "0.1")
	_logo.add_child(_logo_label("MYTHIC", 16, 0))
	_logo.add_child(_logo_label("MONS", 32, 18))


## Shows the whole title, drops the logo in and waits for START or A.
func open() -> void:
	_show_title(true)
	show()
	_menu.hide()
	_press_start.hide()
	_logo.position.y = -64
	var drop := create_tween()
	drop.tween_property(_logo, "position:y", 6.0, 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_waiting = true
	await _started
	drop.kill()
	_logo.position.y = 6
	_press_start.hide()


## The menu under the logo. Returns the picked index, or -1 for B.
func choose(options: PackedStringArray) -> int:
	var picked: int = await _menu.choose(options)
	return picked


## Only the sky and hills, as a backdrop for the new-game intro.
func show_backdrop() -> void:
	_show_title(false)
	_menu.hide()
	_press_start.hide()
	show()


func _show_title(on: bool) -> void:
	_logo.visible = on
	_version.visible = on
	for sprite in _starters:
		sprite.visible = on


func _input(event: InputEvent) -> void:
	if not visible or not _waiting:
		return
	if event.is_action_pressed(&"confirm") or event.is_action_pressed(&"menu"):
		get_viewport().set_input_as_handled()
		_waiting = false
		Audio.play_sfx(&"select")
		_started.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	if _waiting and _press_start.visible != (fmod(_time, 1.0) < 0.6) and _logo.position.y >= 6.0:
		_press_start.visible = fmod(_time, 1.0) < 0.6
	for i in _starters.size(): # A little idle bounce, one after another.
		var x := _starters[i].position.x
		_starters[i].position.y = _hill_y(x) - 14 - (1 if fmod(_time * 2.0 + i * 0.66, 2.0) < 1.0 else 0)
	var t := fmod(_time, BIRD_SECONDS + BIRD_PAUSE)
	_bird.visible = t < BIRD_SECONDS and _logo.visible
	_bird.position = Vector2(round(lerpf(256.0, -16.0, t / BIRD_SECONDS)), 66.0 + round(2.0 * sin(t * 2.5)))
	queue_redraw()


func _draw() -> void:
	var y := 0
	for band: Array in SKY:
		draw_rect(Rect2(0, y, 240, band[1]), band[0])
		y += band[1]
	for star in _stars:
		var shine := 0.35 + 0.65 * absf(sin(_time * 1.7 + star.z))
		draw_rect(Rect2(star.x, star.y, 1, 1), Color(PixelArt.WHITE, shine))
	draw_circle(SUN, 13.0, PixelArt.WHITE)
	draw_circle(SUN, 10.0, Color("fff3d6"))
	for cloud in _clouds:
		var x := fposmod(cloud.x - _time * cloud.z, 300.0) - 30.0
		_draw_cloud(Vector2(x, cloud.y))
	_draw_hills(HORIZON - 8, 5.0, 0.06, PixelArt.TEAL, PixelArt.DEEP)
	# The near hill the starters stand on, and the meadow below.
	var hill := PackedVector2Array()
	for x in range(0, 244, 4):
		hill.append(Vector2(x, _hill_y(x)))
	var top := hill.duplicate()
	hill.append_array([Vector2(240, 160), Vector2(0, 160)])
	draw_colored_polygon(hill, PixelArt.GREEN)
	draw_polyline(top, PixelArt.LIME, 1.0)
	for i in 26: # Grass tufts.
		var at := Vector2((i * 37) % 236 + 2, 120 + (i * 13) % 36)
		draw_rect(Rect2(at, Vector2(1, 2)), PixelArt.DEEP)
		draw_rect(Rect2(at + Vector2(2, 0), Vector2(1, 2)), PixelArt.DEEP)


## The top of the near hill at `x`: a gentle crest in the middle.
static func _hill_y(x: float) -> float:
	return 102.0 + round(14.0 * pow((x - 120.0) / 120.0, 2))


func _draw_cloud(at: Vector2) -> void:
	for part: Vector3 in [Vector3(0, 2, 5), Vector3(8, -1, 7), Vector3(17, 2, 6), Vector3(9, 4, 6)]:
		draw_circle(at + Vector2(part.x, part.y + 2), part.z, PixelArt.PINK_DARK)
	for part: Vector3 in [Vector3(0, 2, 5), Vector3(8, -1, 7), Vector3(17, 2, 6)]:
		draw_circle(at + Vector2(part.x, part.y), part.z, PixelArt.PINK)


## A row of rolling hills along `base`, with a lighter rim.
func _draw_hills(base: int, height: float, frequency: float, color: Color, shade: Color) -> void:
	var points := PackedVector2Array()
	for x in range(0, 244, 4):
		points.append(Vector2(x, base - round(height * (1.0 + sin(x * frequency) + 0.5 * sin(x * frequency * 2.7)))))
	points.append_array([Vector2(240, 160), Vector2(0, 160)])
	draw_colored_polygon(points, shade)
	var rim := PackedVector2Array()
	for point in points.slice(0, points.size() - 2):
		rim.append(point + Vector2(0, 1))
	draw_polyline(rim, color, 2.0)


func _logo_label(text: String, size: int, top: float) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, top)
	label.size = Vector2(240, size + 8)
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = PixelArt.SAND
	settings.outline_size = 6 if size > 16 else 4
	settings.outline_color = PixelArt.INK
	settings.shadow_color = PixelArt.RED
	settings.shadow_size = settings.outline_size
	settings.shadow_offset = Vector2(0, 3 if size > 16 else 2)
	label.label_settings = settings
	return label
