class_name StatBar
extends Control
## Pixel-art bar for HP and EXP, drawn directly so it stays crisp at any value.

## HP bars go green -> yellow -> red as they empty; otherwise `fill_color` is used.
@export var hp_colors := true
@export var fill_color := PixelArt.SKY

## Fill amount, 0..1. Tween it for smooth drains.
var ratio := 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var frame := Rect2(Vector2.ZERO, size)
	draw_rect(frame, PixelArt.NIGHT)
	var inner := frame.grow(-1.0)
	draw_rect(inner, PixelArt.FOG)
	var width := roundf(inner.size.x * ratio)
	if width > 0.0:
		draw_rect(Rect2(inner.position, Vector2(width, inner.size.y)), _fill())


func _fill() -> Color:
	if not hp_colors:
		return fill_color
	if ratio > 0.5:
		return PixelArt.GREEN
	return PixelArt.SAND if ratio > 0.2 else PixelArt.RED
