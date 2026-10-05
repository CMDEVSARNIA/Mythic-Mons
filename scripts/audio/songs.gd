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

## Driving A-minor wild battle theme: | Am | Am | F | G | Am | Am | F | E |
const BATTLE := {
	"bpm": 152,
	"steps_per_beat": 2,
	"channels": [
		{ # Lead
			"wave": ChipSynth.Wave.PULSE_25,
			"volume": 0.1,
			"notes": """
				A4 C5 E5 A5 G5 E5 C5 E5 | A5 - G5 E5 D5 E5 C5 -  | F5 A5 C6 - A5 F5 C5 F5 | G5 - B5 - D6 - B5 G5
				A5 E5 A5 C6 B5 A5 G5 E5 | A5 - - E5 G5 - A5 -    | F5 - A5 - C6 - A5 F5   | E5 - G#5 - B5 - E6 -
			""",
		},
		{ # Off-beat harmony
			"wave": ChipSynth.Wave.PULSE_12,
			"volume": 0.06,
			"notes": """
				. E4 . A4 . E4 . A4 | . E4 . A4 . E4 . A4 | . F4 . A4 . F4 . A4 | . G4 . B4 . G4 . B4
				. E4 . A4 . E4 . A4 | . E4 . A4 . E4 . A4 | . F4 . A4 . F4 . A4 | . E4 . G#4 . E4 . G#4
			""",
		},
		{ # Bass
			"wave": ChipSynth.Wave.TRIANGLE,
			"volume": 0.3,
			"notes": """
				A2 A3 A2 A3 A2 A3 A2 A3 | A2 A3 A2 A3 A2 A3 A2 A3 | F2 F3 F2 F3 F2 F3 F2 F3 | G2 G3 G2 G3 G2 G3 G2 G3
				A2 A3 A2 A3 A2 A3 A2 A3 | A2 A3 A2 A3 A2 A3 A2 A3 | F2 F3 F2 F3 F2 F3 F2 F3 | E2 E3 E2 E3 E2 E3 E2 E3
			""",
		},
		{ # Drums
			"wave": ChipSynth.Wave.NOISE,
			"volume": 0.12,
			"notes": "k h s h k k s h",
		},
	],
}

## Bright C-major victory fanfare: | C | Am | F | G | C | F | G | C |
const VICTORY := {
	"bpm": 126,
	"steps_per_beat": 2,
	"channels": [
		{ # Lead
			"wave": ChipSynth.Wave.PULSE_50,
			"volume": 0.11,
			"notes": """
				C5 E5 G5 C6 - - G5 - | A5 - G5 - E5 - G5 - | F5 - A5 - C6 - A5 - | G5 - - - - - . .
				C6 - B5 A5 G5 - E5 - | F5 - E5 - D5 - C5 - | D5 - E5 F5 G5 - B5 - | C6 - - - - - . .
			""",
		},
		{ # Off-beat harmony
			"wave": ChipSynth.Wave.PULSE_12,
			"volume": 0.06,
			"notes": """
				. E4 . G4 . E4 . G4 | . C4 . E4 . C4 . E4 | . A4 . C5 . A4 . C5 | . B4 . D5 . B4 . D5
				. E4 . G4 . E4 . G4 | . A4 . C5 . A4 . C5 | . B4 . D5 . B4 . D5 | . E4 . G4 . E4 . G4
			""",
		},
		{ # Bass
			"wave": ChipSynth.Wave.TRIANGLE,
			"volume": 0.3,
			"notes": """
				C3 . G3 . C3 . G3 . | A2 . E3 . A2 . E3 . | F2 . C3 . F2 . C3 . | G2 . D3 . G2 . D3 .
				C3 . G3 . C3 . G3 . | F2 . C3 . F2 . C3 . | G2 . D3 . G2 . D3 . | C3 . G3 . C3 . . .
			""",
		},
		{ # Drums
			"wave": ChipSynth.Wave.NOISE,
			"volume": 0.1,
			"notes": "k . h . s . h .",
		},
	],
}

## Driving E-minor trainer battle theme: | Em | Em | C | D | Em | Em | C | B |
const TRAINER_BATTLE := {
	"bpm": 160,
	"steps_per_beat": 2,
	"channels": [
		{ # Lead
			"wave": ChipSynth.Wave.PULSE_25,
			"volume": 0.1,
			"notes": """
				E5 G5 B5 E6 D6 B5 G5 B5 | E6 - D6 B5 A5 B5 G5 -   | C6 E6 G6 - E6 C6 G5 C6 | D6 - F#6 - A6 - F#6 D6
				E6 B5 E6 G6 F#6 E6 D6 B5 | E6 - - B5 D6 - E6 -   | C6 - E6 - G6 - E6 C6   | B5 - D#6 - F#6 - B6 -
			""",
		},
		{ # Off-beat harmony
			"wave": ChipSynth.Wave.PULSE_12,
			"volume": 0.06,
			"notes": """
				. B4 . E5 . B4 . E5 | . B4 . E5 . B4 . E5 | . C5 . E5 . C5 . E5 | . D5 . F#5 . D5 . F#5
				. B4 . E5 . B4 . E5 | . B4 . E5 . B4 . E5 | . C5 . E5 . C5 . E5 | . B4 . D#5 . B4 . D#5
			""",
		},
		{ # Bass
			"wave": ChipSynth.Wave.TRIANGLE,
			"volume": 0.3,
			"notes": """
				E2 E3 E2 E3 E2 E3 E2 E3 | E2 E3 E2 E3 G2 G3 B2 B3 | C3 C4 C3 C4 C3 C4 C3 C4 | D3 D4 D3 D4 D3 D4 D3 D4
				E2 E3 E2 E3 E2 E3 E2 E3 | E2 E3 E2 E3 G2 G3 B2 B3 | C3 C4 C3 C4 C3 C4 C3 C4 | B2 B3 B2 B3 B2 B3 B2 B3
			""",
		},
		{ # Drums
			"wave": ChipSynth.Wave.NOISE,
			"volume": 0.12,
			"notes": "k h s h k k s s",
		},
	],
}

## "Eyes meet": the short loop while a trainer who spotted you walks over.
const SPOTTED := {
	"bpm": 140,
	"steps_per_beat": 2,
	"channels": [
		{ # Lead
			"wave": ChipSynth.Wave.PULSE_25,
			"volume": 0.1,
			"notes": """
				E5 . E5 G5 . G5 A#5 B5 | E6 - D6 - B5 - G5 - | E5 . E5 G5 . G5 A#5 B5 | D6 - C6 - B5 - A#5 -
			""",
		},
		{ # Bass
			"wave": ChipSynth.Wave.TRIANGLE,
			"volume": 0.3,
			"notes": """
				E2 . E3 . E2 . E3 . | E2 . E3 . E2 . E3 . | C3 . C4 . C3 . C4 . | B2 . B3 . B2 . B3 .
			""",
		},
		{ # Drums
			"wave": ChipSynth.Wave.NOISE,
			"volume": 0.1,
			"notes": "k . h . s . h h",
		},
	],
}

const ALL := {&"town": TOWN, &"route": ROUTE, &"battle": BATTLE, &"trainer_battle": TRAINER_BATTLE,
	&"spotted": SPOTTED, &"victory": VICTORY}


static func get_song(id: StringName) -> Dictionary:
	return ALL.get(id, {})
