extends Node2D

# ── 1. VARIABLES ONREADY (Tus nodos exactos del árbol) ──────────────────────
@onready var game_tag = $UILayer/UIControl/LeftPanel/GameTag
@onready var game_title = $UILayer/UIControl/LeftPanel/GameTitle
@onready var game_sub = $UILayer/UIControl/LeftPanel/GameSub
@onready var play_btn = $UILayer/UIControl/LeftPanel/ButtonGroup/PlayButton
@onready var settings_btn = $UILayer/UIControl/LeftPanel/ButtonGroup/SettingsButton
@onready var quit_btn = $UILayer/UIControl/LeftPanel/ButtonGroup/QuitButton
@onready var version_label = $UILayer/UIControl/VersionLabel
@onready var luna_label = $UILayer/UIControl/RightPanel/VBoxContainer/LunaLabel
@onready var status_label = $UILayer/UIControl/RightPanel/VBoxContainer/StatusLabel
@onready var bar_mem = $UILayer/UIControl/RightPanel/VBoxContainer/BarsContainer/BarMEM
@onready var bar_sys = $UILayer/UIControl/RightPanel/VBoxContainer/BarsContainer/BarSYS
@onready var bar_red = $UILayer/UIControl/RightPanel/VBoxContainer/BarsContainer/BarRED
@onready var play_icon = $UILayer/UIControl/LeftPanel/ButtonGroup/PlayButton/IconLabel
@onready var settings_icon = $UILayer/UIControl/LeftPanel/ButtonGroup/SettingsButton/IconLabel
@onready var quit_icon = $UILayer/UIControl/LeftPanel/ButtonGroup/QuitButton/IconLabel

# ── 2. INICIALIZACIÓN PRINCIPAL ─────────────────────────────────────────────
func _ready():
	_setup_positions()
	_setup_labels()
	_setup_buttons()
	_setup_luna_panel()

	# Conexiones de señales de los botones
	if not play_btn.pressed.is_connected(_on_play):
		play_btn.pressed.connect(_on_play)
	if not quit_btn.pressed.is_connected(_on_quit):
		quit_btn.pressed.connect(_on_quit)

# ── 3. POSICIONAMIENTO Y COORDENADAS GLOBAL ─────────────────────────────────
func _setup_positions():
	var left = $UILayer/UIControl/LeftPanel
	var right = $UILayer/UIControl/RightPanel
	var button_group = $UILayer/UIControl/LeftPanel/ButtonGroup

	# Panel Izquierdo (Textos del título y bloque de botones)
	left.position = Vector2(80, 120)
	left.size = Vector2(460, 500)
	left.add_theme_constant_override("separation", 16)
	button_group.add_theme_constant_override("separation", 14)

	# Panel Derecho (Contenedor estético Cyberpunk)
	right.position = Vector2(820, 360)
	right.size = Vector2(260, 250)

	# Etiqueta de Versión (Abajo a la izquierda)
	version_label.position = Vector2(80, 660)

	# Centrado del Avatar de Luna (Si existe en tu árbol de nodos)
	if has_node("UILayer/UIControl/RightPanel/LunaSprite"):
		var sprite = $UILayer/UIControl/RightPanel/LunaSprite
		sprite.position = Vector2(130, 75) # Lo centra perfectamente arriba del texto

# ── 4. CONFIGURACIÓN DE TEXTOS DE IDENTIDAD ──────────────────────────────────
func _setup_labels():
	game_tag.text = "//  S I S T E M A   D E   I A  ·  V E R S I Ó N   1 . 0"
	game_tag.add_theme_color_override("font_color", Color("#4a9eff"))
	game_tag.add_theme_font_size_override("font_size", 11)

	game_title.text = "LUNA"
	game_title.add_theme_font_size_override("font_size", 64)
	game_title.add_theme_color_override("font_color", Color.WHITE)

	game_sub.text = "PROTOCOLO  DE  RECONSTRUCCIÓN  NEURAL"
	game_sub.add_theme_color_override("font_color", Color("#4a6080"))
	game_sub.add_theme_font_size_override("font_size", 10)

	version_label.text = "LUNA  ·  BUILD 1.0.0  ·  ARC I"
	version_label.add_theme_color_override("font_color", Color("#2a3040"))
	version_label.add_theme_font_size_override("font_size", 10)

# ── 5. ESTILIZACIÓN DE BOTONES (Solución al texto desaparecido) ──────────────
func _setup_buttons():
	var buttons_data = [
		[play_btn,     play_icon,     "J U G A R",         Color("#ff2d9b")],
		[settings_btn, settings_icon, "C O N F I G U R A C I Ó N", Color("#4a9eff")],
		[quit_btn,     quit_icon,     "S A L I R",         Color("#ff5555")],
	]

	for b in buttons_data:
		var btn: Button = b[0]
		var icon: Label = b[1]
		var label_text: String = b[2]
		var accent_color: Color = b[3]

		# Configuración base del botón corporativo
		btn.text = label_text
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		btn.custom_minimum_size = Vector2(340, 52)
		btn.focus_mode = Control.FOCUS_NONE
		
		# Forzamos a que el renderizador no oculte a sus hijos
		btn.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED

		# Ajuste de tipografía nativa del botón
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color("#ffffff"))
		btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
		btn.add_theme_color_override("font_pressed_color", accent_color)

		# Creamos estilos planos ultra limpios con márgenes internos controlados
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.02, 0.03, 0.08, 0.45)
		normal_style.border_color = Color(0.18, 0.22, 0.35, 0.60)
		normal_style.set_border_width_all(1)
		normal_style.set_corner_radius_all(8)
		normal_style.content_margin_left = 64 # Deja espacio exacto para el icono izquierdo
		normal_style.content_margin_top = 2

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.04, 0.06, 0.14, 0.65)
		hover_style.border_color = accent_color
		hover_style.set_border_width_all(1)
		hover_style.set_corner_radius_all(8)
		hover_style.content_margin_left = 64
		hover_style.content_margin_top = 2
		hover_style.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.15)
		hover_style.shadow_size = 5

		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = Color(accent_color.r * 0.1, accent_color.g * 0.1, accent_color.b * 0.1, 0.40)
		pressed_style.border_color = accent_color
		pressed_style.set_border_width_all(1)
		pressed_style.set_corner_radius_all(8)
		pressed_style.content_margin_left = 66
		pressed_style.content_margin_top = 4

		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		# Ajuste posicional del icono interno
		icon.position = Vector2(24, 15)
		icon.add_theme_font_size_override("font_size", 15)
		icon.add_theme_color_override("font_color", accent_color)

# ── 6. CONFIGURACIÓN COMPLETA DEL PANEL DERECHO DE LUNA ─────────────────────
func _setup_luna_panel():
	var right_panel = $UILayer/UIControl/RightPanel
	var vbox = $UILayer/UIControl/RightPanel/VBoxContainer
	var bars_container = $UILayer/UIControl/RightPanel/VBoxContainer/BarsContainer

	# Aseguramos que los contenedores llenen el ancho de manera correcta
	vbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	vbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	# Establecemos los límites internos del recuadro (Padding)
	vbox.offset_left = 22
	vbox.offset_right = -22
	vbox.offset_bottom = -22
	vbox.offset_top = 0

	# Separación estricta de elementos verticales
	vbox.add_theme_constant_override("separation", 6)
	bars_container.add_theme_constant_override("separation", 10)
	bars_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Estilizamos cada barra una sola vez de forma segura
	_format_and_align_bar(bar_mem, "MEM", Color("#4a9eff"), 75)
	_format_and_align_bar(bar_sys, "SYS", Color("#b555ff"), 42)
	_format_and_align_bar(bar_red, "RED", Color("#ff2d9b"), 88)

	# Textos informativos de estado del agente
	luna_label.text = "A G E N T E   ·   L U N A"
	luna_label.add_theme_font_size_override("font_size", 10)
	luna_label.add_theme_color_override("font_color", Color("#555d7e"))
	luna_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	status_label.text = "E N   E S P E R A"
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color("#b555ff"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Estilo del marco contenedor general
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.03, 0.08, 0.40)
	panel_style.border_color = Color(0.18, 0.22, 0.35, 0.50)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	right_panel.add_theme_stylebox_override("panel", panel_style)

# Helper para reconstruir las filas de las barras de forma alineada abajo
func _format_and_align_bar(bar: ProgressBar, label_text: String, color: Color, default_val: float):
	if not bar or not bar.is_inside_tree(): return
	
	# Si ya fue formateada previamente (evitamos bucles infinitos), solo actualizamos datos
	if bar.get_parent() is HBoxContainer:
		bar.value = default_val
		return

	var original_container = bar.get_parent()

	# Diseñamos una fila horizontal para clavar el texto al lado de su barra
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)

	# Operación segura de traspaso de nodos
	original_container.remove_child(bar)
	original_container.add_child(row)

	# Indicador de texto alineado uniformemente
	var indicator := Label.new()
	indicator.text = label_text
	indicator.custom_minimum_size = Vector2(34, 0) # Mantiene todas las barras al mismo nivel inicial
	indicator.add_theme_font_size_override("font_size", 11)
	indicator.add_theme_color_override("font_color", Color("#555d7e"))
	row.add_child(indicator)

	# Reinsertamos la barra dentro de la nueva fila organizada
	row.add_child(bar)

	# Diseño minimalista Cyberpunk de la barra de progreso
	bar.show_percentage = false
	bar.value = default_val
	bar.custom_minimum_size.y = 5
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.07, 0.09, 0.16, 0.70)
	bg_style.set_corner_radius_all(3)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.set_corner_radius_all(3)

	bar.add_theme_stylebox_override("background", bg_style)
	bar.add_theme_stylebox_override("fill",       fill_style)

# ── 7. RESPUESTAS A SEÑALES ──────────────────────────────────────────────────
func _on_play():
	pass

func _on_quit():
	get_tree().quit()
