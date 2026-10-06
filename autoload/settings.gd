extends Node
## The player's options (autoload "Settings"), like Emerald's OPTION screen,
## saved to their own file so they apply to every save and the title screen.
##
##   text_speed     SLOW / MID / FAST typewriter (and battle text pacing)
##   battle_scene   ON plays move animations; OFF skips them
##   shift_style    SHIFT offers a switch when a trainer sends out its next
##                  monster; SET doesn't
##   music_volume, sound_volume   0-10, applied to the Music and SFX buses

const PATH := "user://settings.cfg"
const TEXT_SPEEDS: Array[String] = ["SLOW", "MID", "FAST"]
const CHARS_PER_SECOND: Array[float] = [25.0, 50.0, 140.0]
## How long auto-advancing battle text stays up, per text speed.
const MESSAGE_SECONDS: Array[float] = [1.4, 1.0, 0.6]
const MAX_VOLUME := 10

var text_speed := 1
var battle_scene := true
var shift_style := true
var music_volume := 8
var sound_volume := 8
var save_path := PATH


func _ready() -> void:
	load_settings()


func chars_per_second() -> float:
	return CHARS_PER_SECOND[text_speed]


func message_seconds() -> float:
	return MESSAGE_SECONDS[text_speed]


## Puts every option back to its default (tests call this so a player's
## saved options can't change their timing).
func reset() -> void:
	text_speed = 1
	battle_scene = true
	shift_style = true
	music_volume = 8
	sound_volume = 8
	apply()


## Sets the bus volumes. Call after changing a volume.
func apply() -> void:
	_set_bus_volume(&"Music", music_volume)
	_set_bus_volume(&"SFX", sound_volume)


func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("options", "text_speed", text_speed)
	config.set_value("options", "battle_scene", battle_scene)
	config.set_value("options", "shift_style", shift_style)
	config.set_value("options", "music_volume", music_volume)
	config.set_value("options", "sound_volume", sound_volume)
	return config.save(save_path)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) == OK:
		text_speed = clampi(int(config.get_value("options", "text_speed", text_speed)), 0, TEXT_SPEEDS.size() - 1)
		battle_scene = bool(config.get_value("options", "battle_scene", battle_scene))
		shift_style = bool(config.get_value("options", "shift_style", shift_style))
		music_volume = clampi(int(config.get_value("options", "music_volume", music_volume)), 0, MAX_VOLUME)
		sound_volume = clampi(int(config.get_value("options", "sound_volume", sound_volume)), 0, MAX_VOLUME)
	apply()


func _set_bus_volume(bus_name: StringName, volume: int) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_mute(index, volume == 0)
	AudioServer.set_bus_volume_db(index, linear_to_db(volume / float(MAX_VOLUME)))
