#class_name SyntaxClassifier
extends RefCounted

# Colores estilo VS Code Dark
const COLOR_KEYWORD = "#c586c0"
const COLOR_FUNCTION = "#dcdcaa"
const COLOR_STRING = "#ce9178"
const COLOR_NUMBER = "#b5cea8"
const COLOR_DEFAULT = "#d4d4d4"
const COLOR_PENDING = "#444444"
const COLOR_ERROR = "#ff5555"

const KEYWORDS = ["class", "def", "self", "return", "for", "in", "range",
	"if", "elif", "else", "while", "import", "from", "True", "False", "None"]

# Devuelve un array del mismo largo que `line`, con el tipo de cada carácter.
# Tipos: "keyword", "function", "string", "number", "default"
static func classify_line(line: String) -> Array:
	var types = []
	types.resize(line.length())

	var i = 0
	while i < line.length():
		var c = line[i]

		# Strings: 'texto'
		if c == "'":
			types[i] = "string"
			var j = i + 1
			while j < line.length() and line[j] != "'":
				types[j] = "string"
				j += 1
			if j < line.length():
				types[j] = "string"  # comilla de cierre
				i = j + 1
				continue

		# Números (incluye decimales)
		elif c.is_valid_int() or (c == "." and i + 1 < line.length() and line[i+1].is_valid_int()):
			var j = i
			while j < line.length() and (line[j].is_valid_int() or line[j] == "."):
				types[j] = "number"
				j += 1
			i = j
			continue

		# Palabras (identificadores, keywords, funciones)
		elif c.is_valid_identifier() or c == "_":
			var j = i
			var word = ""
			while j < line.length() and (line[j].is_valid_identifier() or line[j] == "_"):
				word += line[j]
				j += 1

			var word_type = "default"
			if word in KEYWORDS:
				word_type = "keyword"
			# Si después de la palabra viene "(" → es función
			elif j < line.length() and line[j] == "(":
				word_type = "function"
			# Si después viene "(" tras un punto → método
			elif i > 0 and line[i-1] == ".":
				word_type = "function"

			for k in range(i, j):
				types[k] = word_type
			i = j
			continue

		# Todo lo demás (símbolos, espacios, paréntesis, =, :, etc)
		else:
			types[i] = "default"
			i += 1

	return types

static func get_color(type: String) -> String:
	match type:
		"keyword": return COLOR_KEYWORD
		"function": return COLOR_FUNCTION
		"string": return COLOR_STRING
		"number": return COLOR_NUMBER
		_: return COLOR_DEFAULT
