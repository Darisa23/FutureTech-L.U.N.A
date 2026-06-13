extends Node2D

var blocks = []
var current_block = 0
var current_line_index = 0
var typing_line: TypingLine
var cursor_visible = true
var blink_timer = 0.0
const SyntaxClassifier = preload("res://scripts/typing/SyntaxClassifier.gd")

@onready var narrative_label = $NarrativeLabel
@onready var code_display = $code/CodeContainer/CodeDisplay
@onready var line_numbers = $code/CodeContainer/LineNumbers
@onready var cursor_bar = $code/CodeContainer/CodeDisplay/CursorBar
@onready var feedback_label = $FeedbackLabel
@onready var progress_label = $ProgressLabel
@onready var luna_status = $LunaStatus
@onready var input_field = $code/InputField

func _ready():
	blocks = Arc2CodeData.get_blocks()
	code_display.bbcode_enabled = true
	line_numbers.bbcode_enabled = true
	feedback_label.text = ""
	cursor_bar.color = Color("#dcdcaa")
	input_field.text_changed.connect(_on_text_changed)
	_load_block(0)

func _load_block(index: int):
	current_block = index
	current_line_index = 0
	narrative_label.text = blocks[current_block]["narrative"]
	_load_line()
	_update_progress()
	_update_line_numbers()

func _load_line():
	var line_data = blocks[current_block]["lines"][current_line_index]
	typing_line = TypingLine.new(line_data["code"], line_data["indent"])
	input_field.text = ""
	input_field.grab_focus()
	_render()
	_update_cursor()

func _update_line_numbers():
	var lines = blocks[current_block]["lines"]
	var nums = []
	for i in lines.size():
		nums.append("[color=#555555]%2d[/color]" % (i + 1))
	line_numbers.text = "\n".join(nums)

func _render():
	var lines_bbcode = []
	var lines = blocks[current_block]["lines"]

	for i in lines.size():
		var line_data = lines[i]
		if i < current_line_index:
			var completed = TypingLine.new(line_data["code"], line_data["indent"])
			completed.cursor = line_data["code"].length()
			completed.current_word_index = completed.words.size()
			lines_bbcode.append(completed.indent_bbcode() + completed.render_bbcode())
		elif i == current_line_index:
			lines_bbcode.append(typing_line.indent_bbcode() + typing_line.render_bbcode())
		else:
			var indent_str = "    ".repeat(line_data["indent"])
			lines_bbcode.append("[color=#3a3a3a]%s[/color][color=%s]%s[/color]" % [indent_str, SyntaxClassifier.COLOR_PENDING, line_data["code"]])

	code_display.text = "\n".join(lines_bbcode)

func _update_cursor():
	var font = code_display.get_theme_font("normal_font")
	var font_size = code_display.get_theme_font_size("normal_font_size")
	var line_height = font.get_height(font_size) + code_display.get_theme_constant("line_separation")

	var indent_str = "    ".repeat(typing_line.indent)
	var written = typing_line.text.substr(0, typing_line.cursor + typing_line.typed.length())
	var prefix = indent_str + written

	var width = font.get_string_size(prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	cursor_bar.position = Vector2(width, current_line_height_offset())
	cursor_bar.size = Vector2(2, line_height)

func current_line_height_offset() -> float:
	var font = code_display.get_theme_font("normal_font")
	var font_size = code_display.get_theme_font_size("normal_font_size")
	var line_height = font.get_height(font_size) + code_display.get_theme_constant("line_separation")
	return current_line_index * line_height

func _process(delta):
	blink_timer += delta
	if blink_timer > 0.5:
		blink_timer = 0.0
		cursor_visible = !cursor_visible
		cursor_bar.visible = cursor_visible

func _on_text_changed(new_text: String):
	var line_done = typing_line.update_typed(new_text)

	if input_field.text != typing_line.typed:
		input_field.text = typing_line.typed
		input_field.caret_column = typing_line.typed.length()

	if line_done:
		_on_line_complete()
	else:
		_render()
		_update_cursor()

func _on_line_complete():
	luna_status.color = Color("#00ff88")
	current_line_index += 1
	var lines = blocks[current_block]["lines"]

	if current_line_index >= lines.size():
		_on_block_complete()
	else:
		_load_line()
		_update_progress()

func _on_block_complete():
	if current_block < blocks.size() - 1:
		feedback_label.text = "Bloque restaurado. Cargando siguiente sistema..."
		feedback_label.add_theme_color_override("font_color", Color("#00ff88"))
		await get_tree().create_timer(1.0).timeout
		_load_block(current_block + 1)
	else:
		narrative_label.text = "LUNA ha sido reconstruida. Sus sistemas vuelven a la vida."
		feedback_label.text = "¡Arc II — Intro completada!"
		feedback_label.add_theme_color_override("font_color", Color("#00ff88"))
		luna_status.color = Color("#00ff88")
		cursor_bar.visible = false
		input_field.editable = false

func _update_progress():
	var lines = blocks[current_block]["lines"]
	progress_label.text = "Bloque %d/%d — Línea %d/%d" % [
		current_block + 1, blocks.size(),
		current_line_index + 1, lines.size()
	]
