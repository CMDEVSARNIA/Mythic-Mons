class_name ChipSynth
extends RefCounted
## Tiny NES / Game Boy style synthesizer.
##
## Renders sound effects (and, through Chiptune, music) to AudioStreamWAV at
## runtime, so the prototype has audio without a single asset file. Voices are
## the classic 8-bit set: three pulse duty cycles, a 4-bit stepped triangle and
## a 15-bit LFSR noise channel.

const MIX_RATE := 22050

enum Wave { PULSE_12, PULSE_25, PULSE_50, TRIANGLE, NOISE }


## Stateful oscillator for one voice. For NOISE, `hz` is the LFSR clock rate:
## low values rumble, high values hiss.
class Oscillator:
	var wave: Wave
	var phase := 0.0
	var _lfsr := 1
	var _noise := 1.0

	func _init(p_wave: Wave) -> void:
		wave = p_wave

	func next(hz: float) -> float:
		phase += hz / MIX_RATE
		if wave == Wave.NOISE:
			while phase >= 1.0:
				phase -= 1.0
				var bit := (_lfsr ^ (_lfsr >> 1)) & 1
				_lfsr = (_lfsr >> 1) | (bit << 14)
				_noise = 1.0 if _lfsr & 1 else -1.0
			return _noise
		phase -= floorf(phase)
		match wave:
			Wave.TRIANGLE:
				return roundf((1.0 - 4.0 * absf(phase - 0.5)) * 7.5) / 7.5
			Wave.PULSE_12:
				return 1.0 if phase < 0.125 else -1.0
			Wave.PULSE_25:
				return 1.0 if phase < 0.25 else -1.0
			_:
				return 1.0 if phase < 0.5 else -1.0


## One voice segment: pitch slides linearly from `from_hz` to `to_hz` while the
## volume fades linearly from `volume` to `end_volume`.
static func tone(wave: Wave, from_hz: float, to_hz: float, seconds: float, volume := 0.35, end_volume := 0.0) -> PackedFloat32Array:
	var n := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var osc := Oscillator.new(wave)
	var attack := 0.004 * MIX_RATE
	for i in n:
		var t := float(i) / n
		out[i] = osc.next(lerpf(from_hz, to_hz, t)) * lerpf(volume, end_volume, t) * minf(1.0, i / attack)
	return out


static func silence(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * MIX_RATE))
	return out


## Plays segments one after another.
static func sequence(parts: Array[PackedFloat32Array]) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for part in parts:
		out.append_array(part)
	return out


## Plays segments at the same time.
static func layer(parts: Array[PackedFloat32Array]) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for part in parts:
		if part.size() > out.size():
			out.resize(part.size())
		for i in part.size():
			out[i] += part[i]
	return out


## Converts float samples (-1..1) to 16-bit little-endian PCM.
static func pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	return data


static func make_stream(pcm: PackedByteArray, loop := false) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = pcm
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = pcm.size() >> 1  # 2 bytes per sample
	return stream


## The game's sound effect catalog. Unknown ids fall back to a menu blip.
static func sfx(id: StringName) -> AudioStreamWAV:
	var samples: PackedFloat32Array
	match id:
		&"bump":
			samples = tone(Wave.PULSE_50, 95.0, 70.0, 0.09, 0.3)
		&"select":
			samples = tone(Wave.PULSE_25, 1760.0, 1760.0, 0.045, 0.2, 0.1)
		&"menu":
			samples = sequence([tone(Wave.PULSE_25, 880.0, 880.0, 0.04, 0.2, 0.18), tone(Wave.PULSE_25, 1320.0, 1320.0, 0.07, 0.2)])
		&"door":
			samples = layer([tone(Wave.NOISE, 4000.0, 900.0, 0.2, 0.25), tone(Wave.PULSE_50, 220.0, 110.0, 0.2, 0.2)])
		&"jump":
			samples = tone(Wave.PULSE_25, 330.0, 880.0, 0.12, 0.25)
		&"cut":
			samples = sequence([tone(Wave.NOISE, 20000.0, 7000.0, 0.1, 0.35), tone(Wave.NOISE, 9000.0, 3000.0, 0.14, 0.3)])
		&"smash":
			samples = layer([tone(Wave.NOISE, 1800.0, 300.0, 0.35, 0.45), tone(Wave.TRIANGLE, 120.0, 40.0, 0.3, 0.6)])
		&"surf":
			samples = layer([tone(Wave.NOISE, 2500.0, 7000.0, 0.45, 0.2), tone(Wave.TRIANGLE, 196.0, 392.0, 0.35, 0.45)])
		&"fly":
			var notes: Array[PackedFloat32Array] = []
			for hz: float in [523.25, 659.25, 783.99, 1046.5, 1318.5]:
				notes.append(tone(Wave.PULSE_12, hz, hz, 0.055, 0.22, 0.15))
			notes.append(tone(Wave.PULSE_12, 1568.0, 2093.0, 0.2, 0.22))
			samples = sequence(notes)
		&"hit":
			samples = layer([tone(Wave.NOISE, 7000.0, 1500.0, 0.14, 0.4), tone(Wave.PULSE_50, 180.0, 70.0, 0.12, 0.25)])
		&"hit_super":
			samples = layer([tone(Wave.NOISE, 9000.0, 800.0, 0.3, 0.5), tone(Wave.PULSE_50, 240.0, 50.0, 0.28, 0.3)])
		&"hit_weak":
			samples = tone(Wave.NOISE, 4000.0, 2000.0, 0.07, 0.3)
		&"faint":
			samples = layer([tone(Wave.PULSE_50, 700.0, 70.0, 0.55, 0.25), tone(Wave.NOISE, 1500.0, 300.0, 0.55, 0.12)])
		&"stat_up", &"stat_down", &"level_up":
			var notes: Array[PackedFloat32Array] = []
			var scale: Array[float] = [523.25, 659.25, 783.99, 1046.5]
			if id == &"stat_down":
				scale.reverse()
			for hz in scale:
				notes.append(tone(Wave.PULSE_12 if id != &"level_up" else Wave.PULSE_25, hz, hz, 0.06, 0.22, 0.16))
			if id == &"level_up":
				notes.append(tone(Wave.PULSE_25, 1046.5, 1046.5, 0.35, 0.22))
			samples = sequence(notes)
		&"flee":
			var steps: Array[PackedFloat32Array] = []
			for i in 3:
				steps.append(tone(Wave.NOISE, 6000.0, 3000.0, 0.05, 0.3))
				steps.append(silence(0.05))
			samples = sequence(steps)
		&"throw":
			samples = layer([tone(Wave.NOISE, 2000.0, 9000.0, 0.3, 0.12, 0.25), tone(Wave.PULSE_12, 300.0, 900.0, 0.3, 0.12)])
		&"ball_shake":
			samples = sequence([tone(Wave.PULSE_50, 160.0, 120.0, 0.05, 0.3), silence(0.06), tone(Wave.PULSE_50, 140.0, 100.0, 0.05, 0.25)])
		&"break_free":
			samples = layer([tone(Wave.NOISE, 3000.0, 12000.0, 0.18, 0.4), tone(Wave.PULSE_25, 400.0, 1200.0, 0.18, 0.25)])
		&"catch":
			var jingle: Array[PackedFloat32Array] = [tone(Wave.NOISE, 9000.0, 9000.0, 0.03, 0.4), silence(0.12)]
			for hz: float in [783.99, 987.77, 1174.66]:
				jingle.append(tone(Wave.PULSE_25, hz, hz, 0.09, 0.22, 0.18))
			jingle.append(tone(Wave.PULSE_25, 1567.98, 1567.98, 0.4, 0.22))
			samples = sequence(jingle)
		&"heal":
			var sparkle: Array[PackedFloat32Array] = []
			for hz: float in [1046.5, 1318.51, 1567.98, 2093.0, 1567.98, 2093.0]:
				sparkle.append(tone(Wave.PULSE_12, hz, hz, 0.05, 0.18, 0.12))
			samples = sequence(sparkle)
		&"evolve":
			var fanfare: Array[PackedFloat32Array] = []
			for hz: float in [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5]:
				fanfare.append(tone(Wave.PULSE_25, hz, hz, 0.09, 0.22, 0.18))
			fanfare.append(tone(Wave.PULSE_25, 1318.51, 1318.51, 0.5, 0.22))
			samples = sequence(fanfare)
		&"orb_open":
			samples = layer([tone(Wave.NOISE, 4000.0, 10000.0, 0.15, 0.3), tone(Wave.PULSE_25, 600.0, 1800.0, 0.15, 0.25)])
		&"orb_bounce":
			samples = tone(Wave.PULSE_50, 300.0, 180.0, 0.04, 0.3)
		&"recall":
			samples = tone(Wave.PULSE_25, 1600.0, 300.0, 0.3, 0.22)
		# Move sounds, by element; MoveAnimator plays them.
		&"swish":
			samples = tone(Wave.NOISE, 3000.0, 9000.0, 0.12, 0.25)
		&"slash":
			samples = sequence([tone(Wave.NOISE, 20000.0, 6000.0, 0.08, 0.35), tone(Wave.NOISE, 12000.0, 4000.0, 0.08, 0.3)])
		&"burn":
			samples = layer([tone(Wave.NOISE, 1200.0, 400.0, 0.4, 0.35), tone(Wave.NOISE, 4000.0, 1500.0, 0.3, 0.15)])
		&"splash":
			samples = layer([tone(Wave.NOISE, 8000.0, 2000.0, 0.3, 0.3), tone(Wave.TRIANGLE, 400.0, 150.0, 0.2, 0.3)])
		&"bubble":
			var pops: Array[PackedFloat32Array] = []
			for hz: float in [600.0, 900.0, 750.0, 1100.0]:
				pops.append(tone(Wave.PULSE_25, hz, hz * 1.6, 0.05, 0.2))
				pops.append(silence(0.03))
			samples = sequence(pops)
		&"leaf":
			samples = sequence([tone(Wave.NOISE, 6000.0, 12000.0, 0.08, 0.2), silence(0.04), tone(Wave.NOISE, 6000.0, 12000.0, 0.08, 0.2)])
		&"zap":
			var crackle: Array[PackedFloat32Array] = []
			for i in 3:
				crackle.append(layer([tone(Wave.PULSE_12, 1800.0, 600.0, 0.07, 0.25), tone(Wave.NOISE, 12000.0, 12000.0, 0.07, 0.2)]))
				crackle.append(silence(0.02))
			samples = sequence(crackle)
		&"thunder":
			samples = layer([tone(Wave.NOISE, 9000.0, 300.0, 0.7, 0.55), tone(Wave.TRIANGLE, 90.0, 40.0, 0.6, 0.6)])
		&"rock":
			samples = layer([tone(Wave.NOISE, 900.0, 200.0, 0.3, 0.45), tone(Wave.TRIANGLE, 110.0, 55.0, 0.25, 0.5)])
		&"ghost":
			var wail: Array[PackedFloat32Array] = []
			for i in 6:
				var hz := 330.0 - 20.0 * i + (30.0 if i % 2 == 0 else -30.0)
				wail.append(tone(Wave.TRIANGLE, hz, hz - 15.0, 0.07, 0.35, 0.3))
			samples = sequence(wail)
		&"growl":
			samples = layer([tone(Wave.PULSE_50, 110.0, 80.0, 0.35, 0.3), tone(Wave.NOISE, 600.0, 300.0, 0.35, 0.2)])
		&"glint":
			samples = sequence([tone(Wave.PULSE_12, 2093.0, 2093.0, 0.04, 0.2, 0.1), tone(Wave.PULSE_12, 3136.0, 3136.0, 0.08, 0.2)])
		&"purchase":
			samples = sequence([tone(Wave.PULSE_25, 1567.98, 1567.98, 0.06, 0.22, 0.15), tone(Wave.PULSE_25, 2093.0, 2093.0, 0.18, 0.22)])
		&"encounter":
			var beeps: Array[PackedFloat32Array] = []
			for i in 8:
				var hz := 987.77 if i % 2 == 0 else 739.99
				beeps.append(tone(Wave.PULSE_50, hz, hz, 0.06, 0.22, 0.18))
			samples = sequence(beeps)
		_:
			samples = tone(Wave.PULSE_25, 1320.0, 1320.0, 0.04, 0.2)
	return make_stream(pcm16(samples))
