class_name Chiptune
extends RefCounted
## Renders a looping song written in a compact text format (see Songs).
##
## A song is a Dictionary:
##   { "bpm": 104, "steps_per_beat": 2, "channels": [
##       { "wave": ChipSynth.Wave.PULSE_25, "volume": 0.12, "notes": "C5 - E5 . G5 ..." } ] }
##
## `notes` holds one whitespace-separated token per step:
##   C4  F#5  Bb3   start a note (octave 4 holds middle C)
##   -              hold the previous note for another step
##   .              silence
##   k  s  h        kick / snare / hi-hat (use on a NOISE channel)
##   |              ignored, handy for marking bars
## Channels shorter than the longest one are repeated to fill the song.
##
## Rendering is pure math on PackedFloat32Arrays, so it is safe to call from a
## WorkerThreadPool task (the Audio autoload does exactly that).

const _NOTE_OFFSETS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const _ATTACK := 0.003
const _RELEASE := 0.015


static func render_pcm(song: Dictionary) -> PackedByteArray:
	return ChipSynth.pcm16(render_samples(song))


static func render_samples(song: Dictionary) -> PackedFloat32Array:
	var step_len := int(round(60.0 / (song.bpm * song.steps_per_beat) * ChipSynth.MIX_RATE))
	var parsed: Array = []
	var total_steps := 0
	for channel: Dictionary in song.channels:
		var tokens := _tokens(channel.notes)
		parsed.append(tokens)
		total_steps = maxi(total_steps, tokens.size())
	var buffer := PackedFloat32Array()
	buffer.resize(total_steps * step_len)
	var drums := _drum_kit()
	for c in song.channels.size():
		var channel: Dictionary = song.channels[c]
		var tokens: PackedStringArray = parsed[c]
		if tokens.is_empty():
			continue
		var steps := tokens
		while steps.size() < total_steps:
			steps.append_array(tokens)
		for event in _events(steps.slice(0, total_steps)):
			var start: int = event[0] * step_len
			var length: int = event[1] * step_len
			if event[2] is String:
				_mix_in(buffer, start, drums[event[2]], channel.volume)
			else:
				_render_note(buffer, start, length, channel.wave, event[2], channel.volume)
	return buffer


static func _tokens(notes: String) -> PackedStringArray:
	var out := PackedStringArray()
	for token in notes.replace("\n", " ").replace("\t", " ").split(" ", false):
		if token != "|":
			out.append(token)
	return out


## Turns tokens into [start_step, length_steps, hz_or_drum] events.
static func _events(tokens: PackedStringArray) -> Array:
	var events: Array = []
	var current: Array = []
	for step in tokens.size():
		var token := tokens[step]
		if token == "-":
			if not current.is_empty() and current[2] is float:
				current[1] += 1
			continue
		if not current.is_empty():
			events.append(current)
			current = []
		if token == ".":
			continue
		if token in ["k", "s", "h"]:
			events.append([step, 1, token])
		else:
			current = [step, 1, note_to_hz(token)]
	if not current.is_empty():
		events.append(current)
	return events


## "A4" -> 440.0, "C#5" -> 554.37, "Bb3" -> 233.08
static func note_to_hz(note: String) -> float:
	var semitone: int = _NOTE_OFFSETS[note[0].to_upper()]
	var i := 1
	if note.length() > 2:
		semitone += 1 if note[1] == "#" else -1
		i = 2
	var midi := (int(note.substr(i)) + 1) * 12 + semitone
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## Writes one note into `buffer`, wrapping past the end so the loop is seamless.
static func _render_note(buffer: PackedFloat32Array, start: int, length: int, wave: ChipSynth.Wave, hz: float, volume: float) -> void:
	var size := buffer.size()
	var osc := ChipSynth.Oscillator.new(wave)
	var attack := _ATTACK * ChipSynth.MIX_RATE
	var release := _RELEASE * ChipSynth.MIX_RATE
	# Pulses decay slightly for a plucky NES feel; the triangle bass stays flat.
	var decay := 0.0 if wave == ChipSynth.Wave.TRIANGLE else 0.35
	for i in length:
		var env := volume * minf(1.0, i / attack) * minf(1.0, (length - i) / release)
		env *= 1.0 - decay * minf(1.0, float(i) / length)
		buffer[(start + i) % size] += osc.next(hz) * env


static func _drum_kit() -> Dictionary:
	return {
		"k": ChipSynth.layer([
			ChipSynth.tone(ChipSynth.Wave.TRIANGLE, 160.0, 40.0, 0.12, 1.0),
			ChipSynth.tone(ChipSynth.Wave.NOISE, 3000.0, 1000.0, 0.02, 0.4),
		]),
		"s": ChipSynth.tone(ChipSynth.Wave.NOISE, 9000.0, 6000.0, 0.13, 0.8),
		"h": ChipSynth.tone(ChipSynth.Wave.NOISE, 20000.0, 20000.0, 0.035, 0.4),
	}


static func _mix_in(buffer: PackedFloat32Array, start: int, samples: PackedFloat32Array, volume: float) -> void:
	var size := buffer.size()
	for i in samples.size():
		buffer[(start + i) % size] += samples[i] * volume
