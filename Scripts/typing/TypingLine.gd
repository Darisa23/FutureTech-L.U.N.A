class_name TypingLine
extends RefCounted

const SyntaxClassifier = preload("res://scripts/typing/SyntaxClassifier.gd")

#const CURSOR_COLOR = "#dcdcaa"

var text: String
var indent: int = 0
var char_types: Array
var words: Array = []
var word_starts: Array = []
var cursor: int = 0
var current_word_index: int = 0
var typed: String = ""

func _init(line_text: String, indent_level: int = 0):
	text = line_text
	indent = indent_level
	char_types = SyntaxClassifier.classify_line(text)
	_split_words()

func _split_words():
	var word = ""
	var start = 0
	for i in text.length():
		if text[i] == " ":
			if word != "":
				words.append(word)
				word_starts.append(start)
			word = ""
			start = i + 1
		else:
			word += text[i]
	if word != "":
		words.append(word)
		word_starts.append(start)

func is_last_word() -> bool:
	return current_word_index >= words.size() - 1

func is_complete() -> bool:
	return current_word_index >= words.size()

# La "palabra objetivo" incluye su espacio final (si no es la última palabra)
func current_target() -> String:
	if current_word_index >= words.size():
		return ""
	var w = words[current_word_index]
	if not is_last_word():
		w += " "
	return w

func update_typed(new_text: String) -> bool:
	var target = current_target()

	if new_text.length() > target.length():
		new_text = new_text.substr(0, target.length())

	typed = new_text

	if typed == target and target != "":
		_commit_word()
		typed = ""
		return is_complete()

	return false

func _commit_word():
	cursor += current_target().length()
	current_word_index += 1

func indent_bbcode() -> String:
	if indent == 0:
		return ""
	var spaces = "    ".repeat(indent)
	return "[color=#3a3a3a]%s[/color]" % spaces

func render_bbcode() -> String:
	var result = ""

	for i in cursor:
		var ch = text[i]
		if ch == " ":
			result += " "
		else:
			result += "[color=%s]%s[/color]" % [SyntaxClassifier.get_color(char_types[i]), _escape(ch)]

	var target = current_target()
	var typed_len = typed.length()

	for j in target.length():
		var abs_index = cursor + j
		var ch = target[j]

		if j < typed_len:
			if typed[j] == ch:
				if ch == " ":
					result += " "
				else:
					result += "[color=%s]%s[/color]" % [SyntaxClassifier.get_color(char_types[abs_index]), _escape(ch)]
			else:
				# Carácter correcto (puede ser espacio) resaltado en rojo, sin reescribir
				if ch == " ":
					result += "[bgcolor=#ff5555] [/bgcolor]"
				else:
					result += "[bgcolor=#ff5555]%s[/bgcolor]" % _escape(ch)
		else:
			if ch == " ":
				result += " "
			else:
				result += "[color=%s]%s[/color]" % [SyntaxClassifier.COLOR_PENDING, _escape(ch)]

	for k in range(current_word_index + 1, words.size()):
		for ch in words[k]:
			result += "[color=%s]%s[/color]" % [SyntaxClassifier.COLOR_PENDING, _escape(ch)]
		if k < words.size() - 1:
			result += " "

	return result

func _escape(ch: String) -> String:
	match ch:
		"[": return "[lb]"
		_: return ch
