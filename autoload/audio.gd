extends Node
## Music and sound effects (autoload "Audio").
##
## Real files always win: drop `town.ogg` into res://assets/audio/music/ or
## `bump.wav` into res://assets/audio/sfx/ and it replaces the generated sound
## with the same id. Music files loop. Everything else falls back to ChipSynth
## / Chiptune, so the game is never silent while you are still collecting
## assets.

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const EXTENSIONS: Array[String] = ["ogg", "wav", "mp3"]
const SFX_VOICES := 6
const MUSIC_VOLUME_DB := -4.0
const FADE_SECONDS := 0.3
## A track with no file of its own uses another's, so one song can cover
## both: gym battles play the trainer battle file.
const MUSIC_FALLBACKS := {&"gym_battle": &"trainer_battle"}

var _music: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _sfx_cache: Dictionary[StringName, AudioStream] = {}
var _music_cache: Dictionary[StringName, AudioStream] = {}
var _wanted_track: StringName = &""
var _fade: Tween

# Generated tracks render on worker threads so loading a map never hitches.
var _render_tasks: Dictionary[StringName, int] = {}
var _rendered_pcm: Dictionary[StringName, PackedByteArray] = {}
var _mutex := Mutex.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)
	for i in SFX_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = &"SFX"
		add_child(voice)
		_voices.append(voice)
	for id: StringName in Songs.ALL:
		if _music_file(id) == null:
			_render_tasks[id] = WorkerThreadPool.add_task(_render_track.bind(id), false, "Render chiptune")


func play_sfx(id: StringName) -> void:
	if id.is_empty():
		return
	if not _sfx_cache.has(id):
		var stream := _load_file(SFX_DIR, id)
		_sfx_cache[id] = stream if stream else ChipSynth.sfx(id)
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = _sfx_cache[id]
	voice.play()


## Switches the background music. Playing the current track again does nothing,
## so walking between maps that share a theme doesn't restart it.
func play_music(id: StringName) -> void:
	if id == _wanted_track:
		return
	_wanted_track = id
	var stream := _get_track(id)
	if stream or id.is_empty():
		_crossfade_to(stream)
	# Otherwise the track is still rendering; _process starts it when ready.


func stop_music() -> void:
	play_music(&"")


func _process(_delta: float) -> void:
	for id: StringName in _render_tasks.keys():
		var task := _render_tasks[id]
		if not WorkerThreadPool.is_task_completed(task):
			continue
		WorkerThreadPool.wait_for_task_completion(task)
		_render_tasks.erase(id)
		_mutex.lock()
		var pcm: PackedByteArray = _rendered_pcm.get(id, PackedByteArray())
		_rendered_pcm.erase(id)
		_mutex.unlock()
		_music_cache[id] = ChipSynth.make_stream(pcm, true)
		if id == _wanted_track:
			_crossfade_to(_music_cache[id])


func _exit_tree() -> void:
	for task: int in _render_tasks.values():
		WorkerThreadPool.wait_for_task_completion(task)


func _get_track(id: StringName) -> AudioStream:
	if id.is_empty():
		return null
	if not _music_cache.has(id):
		var stream := _music_file(id)
		if stream == null:
			if not _render_tasks.has(id) and not Songs.get_song(id).is_empty():
				_render_tasks[id] = WorkerThreadPool.add_task(_render_track.bind(id))
			return null
		_music_cache[id] = stream
	return _music_cache[id]


## The music file for `id` (or its fallback's), set to loop; null if none.
func _music_file(id: StringName) -> AudioStream:
	var stream := _load_file(MUSIC_DIR, id)
	if stream == null and MUSIC_FALLBACKS.has(id):
		stream = _load_file(MUSIC_DIR, MUSIC_FALLBACKS[id])
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	elif stream and &"loop" in stream:
		stream.set(&"loop", true)
	return stream


func _render_track(id: StringName) -> void: # Runs on a worker thread.
	var pcm := Chiptune.render_pcm(Songs.get_song(id))
	_mutex.lock()
	_rendered_pcm[id] = pcm
	_mutex.unlock()


func _crossfade_to(stream: AudioStream) -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween()
	if _music.playing:
		_fade.tween_property(_music, "volume_db", -40.0, FADE_SECONDS)
	_fade.tween_callback(func() -> void:
		_music.stream = stream
		_music.volume_db = MUSIC_VOLUME_DB
		if stream:
			_music.play()
		else:
			_music.stop())


func _load_file(dir: String, id: StringName) -> AudioStream:
	for ext in EXTENSIONS:
		var path := "%s%s.%s" % [dir, id, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")
