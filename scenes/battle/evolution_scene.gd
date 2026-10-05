class_name EvolutionScene
extends Control
## The evolution screen. The monster flashes between white silhouettes of its
## old and new forms, faster and faster, then becomes the new one. Holding B
## stops a level-up evolution, as in Emerald; stone evolutions can't be
## stopped. Main adds this over everything and awaits run().
##
##     var evolved: bool = await evolution_scene.run(monster, into, can_cancel)

const FLASHES := 14

@onready var _art: TextureRect = $Art


func run(monster: Monster, into: MonsterSpecies, can_cancel := true) -> bool:
	var old_name := monster.get_display_name()
	var before := monster.species.front_texture
	_art.texture = before
	await Dialogue.say(["What? %s\nis evolving!" % old_name])
	var light_before := _silhouette(before)
	var light_after := _silhouette(into.front_texture)
	var cancelled := false
	for i in FLASHES:
		_art.texture = light_before if i % 2 == 0 else light_after
		Audio.play_sfx(&"select")
		var duration := lerpf(0.4, 0.08, float(i) / (FLASHES - 1))
		var elapsed := 0.0
		while elapsed < duration and not cancelled:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
			cancelled = can_cancel and Input.is_action_pressed(&"cancel")
		if cancelled:
			break
	if cancelled:
		_art.texture = before
		await Dialogue.say(["Huh? %s\nstopped evolving!" % old_name])
		return false
	_art.texture = into.front_texture
	Audio.play_sfx(&"evolve")
	var new_moves := monster.evolve(into)
	GameState.mark_caught(GameData.id_of(into))
	await Dialogue.say(["Congratulations! Your\n%s evolved into\n%s!" % [old_name, into.display_name]])
	for move in new_moves:
		await MoveTutor.teach(monster, move)
	return true


## The sprite as a flat white shape.
static func _silhouette(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)
