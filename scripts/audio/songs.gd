class_name Songs
extends RefCounted
## Placeholder chiptune soundtrack, rendered at runtime by Chiptune.
## Each step is an eighth note (steps_per_beat = 2); every song is 8 bars.
## Maps choose a track with WorldMap.music. A real file with the same name in
## res://assets/audio/music/ (e.g. town.ogg) automatically replaces these.

## Calm C-major town theme: | C | Am | F | G | C | Am | F G | C |
const TOWN := {
	"bpm": 100,
	"steps_per_beat": 2,
	"channels": [
		{ # Lead
			"wave": ChipSynth.Wave.PULSE_50,
			"volume": 0.11,
			"notes": """
				E5 G5 C6 - B5 G5 E5 -  | A5 - G5 E5 C5 - E5 -  | F5 A5 C6 - A5 F5 C5 -  | D5 - G5 - B5 - D6 -
				E6 - D6 C6 B5 - G5 -   | C6 - B5 A5 E5 - A5 -  | A5 G5 F5 A5 G5 - B5 D6 | C6 - - - G5 - E5 -
			""",
		},
		{ # Off-beat harmony
			"wave": ChipSynth.Wave.PULSE_12,
			"volume": 0.06,
			"notes": """
				. E4 . G4 . E4 . G4 | . C4 . E4 . C4 . E4 | . A4 . C5 . A4 . C5 | . B4 . D5 . B4 . D5
				. E4 . G4 . E4 . G4 | . C4 . E4 . C4 . E4 | . A4 . C5 . B4 . D5 | . E4 . G4 . E4 . G4
			""",
		},
		{ # Bass
			"wave": ChipSynth.Wave.TRIANGLE,
			"volume": 0.3,
			"notes": """
				C3 . C4 . G3 . C4 . | A2 . A3 . E3 . A3 . | F2 . F3 . C3 . F3 . | G2 . G3 . D3 . G3 .
				C3 . C4 . G3 . C4 . | A2 . A3 . E3 . A3 . | F2 . F3 . G2 . G3 . | C3 . G3 . C3 . C3 .
			""",
		},
		{ # Drums
			"wave": ChipSynth.Wave.NOISE,
			"volume": 0.12,
			"notes": "k . s . k . s h",
		},
	],
}

## Upbeat G-major route theme: | G | Em | C | D | G | Em | C D | G |
const ROUTE := {
	"bpm": 132,
	"steps_per_beat": 2,
	"channels": [
		{ # Lead
			"wave": ChipSynth.Wave.PULSE_25,
			"volume": 0.11,
			"notes": """
				G5 - D5 G5 B5 - A5 G5  | E5 - B4 E5 G5 - F#5 E5 | C5 - E5 G5 C6 - B5 A5 | D5 - F#5 A5 D6 - C6 A5
				B5 - - G5 D6 - B5 G5   | G5 - E5 - B5 - G5 E5   | E5 G5 C6 - D6 - F#5 A5 | G5 - - - . . D5 F#5
			""",
		},
		{ # Off-beat harmony
			"wave": ChipSynth.Wave.PULSE_12,
			"volume": 0.06,
			"notes": """
				. B4 . D5 . B4 . D5 | . G4 . B4 . G4 . B4 | . E4 . G4 . E4 . G4 | . F#4 . A4 . F#4 . A4
				. B4 . D5 . B4 . D5 | . G4 . B4 . G4 . B4 | . E4 . G4 . F#4 . A4 | . B4 . D5 . B4 . D5
			""",
		},
		{ # Bass
			"wave": ChipSynth.Wave.TRIANGLE,
			"volume": 0.3,
			"notes": """
				G2 G3 G2 G3 G2 G3 G2 G3 | E2 E3 E2 E3 E2 E3 E2 E3 | C3 C4 C3 C4 C3 C4 C3 C4 | D3 D4 D3 D4 D3 D4 D3 D4
				G2 G3 G2 G3 G2 G3 G2 G3 | E2 E3 E2 E3 E2 E3 E2 E3 | C3 C4 C3 C4 D3 D4 D3 D4 | G2 G3 G2 G3 G2 G3 G2 G3
			""",
		},
		{ # Drums
			"wave": ChipSynth.Wave.NOISE,
			"volume": 0.12,
			"notes": "k h s h k k s h",
		},
	],
}

const ALL := {&"town": TOWN, &"route": ROUTE}


static func get_song(id: StringName) -> Dictionary:
	return ALL.get(id, {})
