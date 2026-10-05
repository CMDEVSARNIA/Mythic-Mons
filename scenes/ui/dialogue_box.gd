extends CanvasLayer
## Pokémon-style text box (autoload "Dialogue"). From any script:
##
##     await Dialogue.say(["Hello!", "Each entry is one page."])
##     if await Dialogue.ask("Would you like to SURF?") == 0:
##         ...  # 0 = first option ("YES")
##
## A page holds three lines of about 27 characters; use "\n" to break lines.
## Confirm (A) or cancel (B) finishes the typewriter effect, then turns the page.

signal _page_typed
signal _confirmed

const CHARS_PER_SECOND := 50.0

var is_open := false

var _typing := false
var _waiting := false
var _shown := 0.0

@onready var _box: PanelContainer = $Box
@onready var _text: Label = $Box/Text
@onready var _arrow: Label = $Arrow
@onready var _choices: ChoiceBox = $ChoiceArea/Choices


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box.hide()
	_arrow.hide()


## Shows each page in turn and returns once the player dismisses the last one.
func say(pages: PackedStringArray) -> void:
	_open()
	for page in pages:
		await _show_page(page)
		await _wait_for_confirm()
	_close()


## Shows `prompt` with a choice list. Returns the chosen index; cancelling
## picks the last option (so "NO" for the default YES/NO).
func ask(prompt: String, options: PackedStringArray = ["YES", "NO"]) -> int:
	_open()
	await _show_page(prompt)
	var choice: int = await _choices.choose(options)
	_close()
	return choice if choice >= 0 else options.size() - 1


func _process(delta: float) -> void:
	_arrow.visible = _waiting and int(Time.get_ticks_msec() / 400.0) % 2 == 0
	if not _typing:
		return
	_shown += delta * CHARS_PER_SECOND
	_text.visible_characters = int(_shown)
	if _text.visible_characters >= _text.get_total_character_count():
		_finish_typing()


func _input(event: InputEvent) -> void:
	if not is_open or not (event.is_action_pressed(&"confirm") or event.is_action_pressed(&"cancel")):
		return
	if _typing:
		get_viewport().set_input_as_handled()
		_finish_typing()
	elif _waiting:
		get_viewport().set_input_as_handled()
		Audio.play_sfx(&"select")
		_confirmed.emit()


func _open() -> void:
	is_open = true
	_box.show()


func _close() -> void:
	is_open = false
	_box.hide()
	_arrow.hide()


func _show_page(text: String) -> void:
	_text.text = text
	_text.visible_characters = 0
	_shown = 0.0
	_typing = true
	await _page_typed


func _finish_typing() -> void:
	_typing = false
	_text.visible_characters = -1
	_page_typed.emit()


func _wait_for_confirm() -> void:
	_waiting = true
	await _confirmed
	_waiting = false
