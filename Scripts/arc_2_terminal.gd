extends Node2D

var blocks = []
var current_block = 0
var current_line_index = 0
var typing_line: TypingLine
var cursor_visible = true
var blink_timer = 0.0
const SyntaxClassifier = preload("res://scripts/typing/SyntaxClassifier.gd")

# --- Métricas de accuracy ---
var total_chars_typed = 0
var total_chars_correct = 0

# --- Timer decorativo ---
var invasion_seconds_left = 20 * 60  # 20:00 inicial, ajustable

@onready var narrative_label = $NarrativeLabel
@onready var code_display = $code/CodeContainer/CodeDisplay
@onready var line_numbers = $code/CodeContainer/LineNumbers
@onready var cursor_bar = $code/CodeContainer/CodeDisplay/CursorBar
@onready var feedback_label = $FeedbackLabel
@onready var progress_label = $BarritaInfo/ColorRect2/block
@onready var accuracy_label = $BarritaInfo/Acc
@onready var invasion_label = $BarritaInfo/inv
@onready var blocks_progress = $BlocksProgress
@onready var input_field = $code/InputField
@onready var btn_underscore = $SymbolHelpers/BtnUnderscore
@onready var btn_bracket_left = $SymbolHelpers/BtnBracketLeft
@onready var btn_bracket_right = $SymbolHelpers/BtnBracketRight
@onready var btn_quote = $SymbolHelpers/BtnQuote

func _ready():
	blocks = Arc2CodeData.get_blocks()
	code_display.bbcode_enabled = true
	line_numbers.bbcode_enabled = true
	feedback_label.text = ""
	cursor_bar.color = Color("#dcdcaa")
	input_field.text_changed.connect(_on_text_changed)
	btn_underscore.pressed.connect(func(): _insert_symbol("_"))
	btn_bracket_left.pressed.connect(func(): _insert_symbol("["))
	btn_bracket_right.pressed.connect(func(): _insert_symbol("]"))
	btn_quote.pressed.connect(func(): _insert_symbol("'"))

	_build_blocks_progress()
	_load_block(0)

func _build_blocks_progress():
	for child in blocks_progress.get_children():
		child.queue_free()

	for i in blocks.size():
		var bar = ColorRect.new()
		bar.custom_minimum_size = Vector2(40, 8)
		bar.color = Color("#2a2a3a")  # pendiente por defecto
		bar.name = "BlockBar_%d" % i
		blocks_progress.add_child(bar)

	_update_blocks_progress()

func _update_blocks_progress():
	for i in blocks.size():
		var bar = blocks_progress.get_node("BlockBar_%d" % i)
		if i < current_block:
			bar.color = Color("#00ff88")   # bloque completado
		elif i == current_block:
			bar.color = Color("#4a9eff")   # bloque actual
		else:
			bar.color = Color("#2a2a3a")   # pendiente

func _load_block(index: int):
	current_block = index
	current_line_index = 0
	narrative_label.text = blocks[current_block]["narrative"]
	_load_line()
	_update_progress()
	_update_line_numbers()
	_update_blocks_progress()

func _load_line():
	var line_data = blocks[current_block]["lines"][current_line_index]
	typing_line = TypingLine.new(line_data["code"], line_data["indent"])

	input_field.release_focus()
	input_field.text = ""
	input_field.editable = true
	_render()
	_update_cursor()
	await get_tree().process_frame
	input_field.grab_focus()
	input_field.caret_column = 0

func _insert_symbol(symbol: String):
	if not input_field.editable:
		return
	var caret = input_field.caret_column
	var new_text = input_field.text.insert(caret, symbol)

	input_field.text_changed.disconnect(_on_text_changed)
	input_field.text = new_text
	input_field.caret_column = caret + symbol.length()
	input_field.text_changed.connect(_on_text_changed)

	_on_text_changed(new_text)
	input_field.grab_focus()

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

	if invasion_seconds_left > 0:
		invasion_seconds_left -= delta
		if invasion_seconds_left < 0:
			invasion_seconds_left = 0
		_update_invasion_timer()

	# Red de seguridad: si el campo debería tener foco y no lo tiene, se lo devolvemos
	if input_field.editable and not input_field.has_focus():
		print("RECOVERING FOCUS - frame: ", Engine.get_process_frames())
		input_field.grab_focus()

func _update_invasion_timer():
	var total_seconds = int(invasion_seconds_left)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	invasion_label.text = "INVASION IN: %d:%02d" % [minutes, seconds]

func _on_text_changed(new_text: String):
	if not input_field.editable:
		return

	# Detectar si se agregó un carácter nuevo (no borrado) para contar accuracy
	var prev_len = typing_line.typed.length()
	var new_len = new_text.length()

	if new_len > prev_len:
		var target = typing_line.current_target()
		var added_index = prev_len
		if added_index < new_text.length() and added_index < target.length():
			total_chars_typed += 1
			if new_text[added_index] == target[added_index]:
				total_chars_correct += 1
			_update_accuracy()

	var line_done = typing_line.update_typed(new_text)

	if input_field.text != typing_line.typed:
		input_field.text = typing_line.typed
		input_field.caret_column = typing_line.typed.length()

	_render()
	_update_cursor()

	if line_done:
		input_field.editable = false
		await get_tree().create_timer(0.15).timeout
		_on_line_complete()

func _update_accuracy():
	if total_chars_typed == 0:
		accuracy_label.text = "ACCURACY: 100%"
		return
	var pct = int(round(100.0 * float(total_chars_correct) / float(total_chars_typed)))
	accuracy_label.text = "ACCURACY: %d%%" % pct

func _on_line_complete():
	current_line_index += 1
	var lines = blocks[current_block]["lines"]
	print("LINE COMPLETE -> editable antes: ", input_field.editable, " has_focus antes: ", input_field.has_focus())

	if current_line_index >= lines.size():
		_on_block_complete()
	else:
		_load_line()
		_update_progress()
	print("LINE COMPLETE -> editable despues: ", input_field.editable, " has_focus despues: ", input_field.has_focus())

func _on_block_complete():
	_update_blocks_progress()

	if current_block < blocks.size() - 1:
		feedback_label.text = "Bloque restaurado. Cargando siguiente sistema..."
		feedback_label.add_theme_color_override("font_color", Color("#00ff88"))
		await get_tree().create_timer(1.0).timeout
		_load_block(current_block + 1)
	else:
		narrative_label.text = "LUNA ha sido reconstruida. Sus sistemas vuelven a la vida."
		feedback_label.text = "¡Arc II — Intro completada!"
		feedback_label.add_theme_color_override("font_color", Color("#00ff88"))
		cursor_bar.visible = false
		input_field.editable = false
		_update_blocks_progress()

func _update_progress():
	var lines = blocks[current_block]["lines"]
	progress_label.text = "BLOCK %d/%d" % [
		current_block + 1, blocks.size()
	]
