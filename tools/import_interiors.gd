extends SceneTree
## Builds assets/interiors/furniture.png from Bitglow's interior pack: every
## piece in FurniturePieces, layered at full size, then halved so it suits the
## 16x16 cast.
##
## The pack's license doesn't allow sharing its files, so they aren't in the
## repository. To rebuild the atlas, put beds_BR.png, wardrobes_BR.png and
## decorations_BR.png in assets/interiors/source/ and run:
##
##   godot --headless --path . --script res://tools/import_interiors.gd
##   godot --headless --path . --import


func _initialize() -> void:
	var sheets := {}
	for piece: StringName in FurniturePieces.PIECES:
		for part: Array in FurniturePieces.PIECES[piece].parts:
			if not sheets.has(part[0]):
				var path := ProjectSettings.globalize_path(FurniturePieces.SOURCE_DIR + "%s_BR.png" % part[0])
				var sheet := Image.load_from_file(path)
				if sheet == null:
					push_error("Missing %s (see assets/interiors/source/README.md)." % path)
					quit(1)
					return
				sheet.convert(Image.FORMAT_RGBA8)
				sheets[part[0]] = sheet

	var size := FurniturePieces.atlas_size()
	var atlas := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	for piece: StringName in FurniturePieces.PIECES:
		var full_size := FurniturePieces.full_size(piece)
		var canvas := Image.create_empty(full_size.x, full_size.y, false, Image.FORMAT_RGBA8)
		for part: Array in FurniturePieces.PIECES[piece].parts:
			var offset: Vector2i = part[2] if part.size() > 2 else Vector2i.ZERO
			canvas.blend_rect(sheets[part[0]], part[1], offset)
		atlas.blit_rect(_halve(canvas), Rect2i(Vector2i.ZERO, full_size), FurniturePieces.region(piece).position)
	var out := ProjectSettings.globalize_path(FurniturePieces.ATLAS)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var error := atlas.save_png(out)
	print("%s %s" % ["wrote" if error == OK else "FAILED (%s)" % error_string(error), FurniturePieces.ATLAS])
	quit(0 if error == OK else 1)


## Halves pixel art: each 2x2 block becomes its most common visible color
## (ties go to the darker one, so outlines survive), and a block with fewer
## than two visible pixels turns clear.
func _halve(image: Image) -> Image:
	var out := Image.create_empty((image.get_width() + 1) / 2, (image.get_height() + 1) / 2, false, Image.FORMAT_RGBA8)
	for y in out.get_height():
		for x in out.get_width():
			var counts := {}
			var visible := 0
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				var cell := Vector2i(x, y) * 2 + corner
				if cell.x >= image.get_width() or cell.y >= image.get_height():
					continue
				var color := image.get_pixelv(cell)
				if color.a > 0.0:
					counts[color] = counts.get(color, 0) + 1
					visible += 1
			if visible < 2:
				continue
			var best := Color(0, 0, 0, 0)
			var best_count := 0
			for color: Color in counts:
				var count: int = counts[color]
				if count > best_count or (count == best_count and _brightness(color) < _brightness(best)):
					best = color
					best_count = count
			out.set_pixel(x, y, best)
	return out


func _brightness(color: Color) -> float:
	return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
