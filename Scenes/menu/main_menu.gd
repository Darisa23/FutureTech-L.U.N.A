extends Node2D

# ══════════════════════════════════════════════════════════════════════════════
#  LUNA · MENÚ PRINCIPAL — Versión Dreamy Reescrita (Optimizado)
#  Animaciones: glow pulsante en título, parpadeo de status, hover en botones,
#  entrada suave (fade-in) de todos los elementos al iniciar.
# ══════════════════════════════════════════════════════════════════════════════

# ── NODOS ────────────────────────────────────────────────────────────────────
@onready var game_tag       = $UILayer/UIControl/LeftPanel/GameTag
@onready var game_title     = $UILayer/UIControl/LeftPanel/GameTitle
@onready var game_sub       = $UILayer/UIControl/LeftPanel/GameSub
@onready var play_btn       = $UILayer/UIControl/LeftPanel/ButtonGroup/PlayButton
@onready var settings_btn   = $UILayer/UIControl/LeftPanel/ButtonGroup/SettingsButton
@onready var quit_btn       = $UILayer/UIControl/LeftPanel/ButtonGroup/QuitButton
@onready var version_label  = $UILayer/UIControl/VersionLabel
@onready var luna_label     = $UILayer/UIControl/RightPanel/VBoxContainer/LunaLabel
@onready var status_label   = $UILayer/UIControl/RightPanel/VBoxContainer/StatusLabel
@onready var bar_mem        = $UILayer/UIControl/RightPanel/VBoxContainer/BarsContainer/BarMEM
@onready var bar_sys        = $UILayer/UIControl/RightPanel/VBoxContainer/BarsContainer/BarSYS
@onready var bar_red        = $UILayer/UIControl/RightPanel/VBoxContainer/BarsContainer/BarRED
@onready var play_icon      = $UILayer/UIControl/LeftPanel/ButtonGroup/PlayButton/IconLabel
@onready var settings_icon  = $UILayer/UIControl/LeftPanel/ButtonGroup/SettingsButton/IconLabel
@onready var quit_icon      = $UILayer/UIControl/LeftPanel/ButtonGroup/QuitButton/IconLabel

# ── PALETA DREAMY ─────────────────────────────────────────────────────────────
const C_WHITE        := Color("#FFFFFF")
const C_TAG          := Color("#c9e8ff")   # Celeste muy suave
const C_SUB          := Color("#e8d5f5")   # Lavanda claro
const C_VERSION      := Color("#7a6e99")   # Morado apagado
const C_LUNA_LABEL   := Color("#b8c8ff")   # Azul lavanda
const C_STATUS       := Color("#ffb8d9")   # Rosa suave
const C_ACCENT_PLAY  := Color("#ffb8d9")   # Rosa pastel
const C_ACCENT_CFG   := Color("#b8e8ff")   # Cian pastel
const C_ACCENT_QUIT  := Color("#c8a0e8")   # Morado pastel
const C_BORDER_BASE  := Color(0.45, 0.30, 0.60, 0.35)
const C_BG_BTN       := Color(0.05, 0.03, 0.10, 0.45)
const C_PANEL_BG     := Color(0.06, 0.04, 0.12, 0.50)

# ── ESTADO DE ANIMACIONES ────────────────────────────────────────────────────
var _time            : float = 0.0
var _title_base_size : int   = 110 # Aumentado de 80 a 110 para mayor impacto visual
var _status_blink    : float = 0.0
var _bars_target     := {"MEM": 75.0, "SYS": 42.0, "RED": 88.0}
var _bars_current    := {"MEM": 0.0,  "SYS": 0.0,  "RED": 0.0}
var _intro_done      : bool  = false
var _intro_t         : float = 0.0          # 0 → 1 durante el fade-in

# Referencias a nodos de barras (se llenan en _setup_luna_panel)
var _bar_nodes := {}

# StyleBox del panel derecho — se crea una vez y se muta en _process
var _panel_style : StyleBoxFlat = null


# ══════════════════════════════════════════════════════════════════════════════
#  INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════════════════
func _ready():
	# Ocultamos todo antes de la animación de entrada
	modulate = Color(1, 1, 1, 0)

	_setup_positions()
	_setup_labels()
	_setup_buttons()
	_setup_luna_panel()
	_connect_signals()


func _connect_signals():
	if not play_btn.pressed.is_connected(_on_play):
		play_btn.pressed.connect(_on_play)
	if not quit_btn.pressed.is_connected(_on_quit):
		quit_btn.pressed.connect(_on_quit)


# ══════════════════════════════════════════════════════════════════════════════
#  PROCESS — ANIMACIONES ACTIVAS
# ══════════════════════════════════════════════════════════════════════════════
func _process(delta: float):
	_time += delta

	# 1. FADE-IN DE ENTRADA (primer segundo)
	if not _intro_done:
		_intro_t = minf(_intro_t + delta * 0.9, 1.0)
		modulate.a = _ease_out_cubic(_intro_t)
		if _intro_t >= 1.0:
			_intro_done = true
			modulate.a  = 1.0

	# 2. GLOW PULSANTE EN EL TÍTULO (respiración suave)
	var glow_pulse := 0.82 + 0.18 * sin(_time * 1.4)
	game_title.add_theme_color_override(
		"font_color",
		Color(1.0, 1.0, 1.0, glow_pulse)
	)
	# Sombra que pulsa de intensidad
	var shadow_alpha := 0.20 + 0.30 * sin(_time * 1.4)
	game_title.add_theme_color_override(
		"font_shadow_color",
		Color(0.72, 0.55, 1.0, shadow_alpha)
	)

	# 3. PARPADEO DEL STATUS "EN ESPERA"
	_status_blink += delta * 1.8
	var blink_alpha := 0.55 + 0.45 * sin(_status_blink * PI)
	status_label.add_theme_color_override(
		"font_color",
		Color(C_STATUS.r, C_STATUS.g, C_STATUS.b, blink_alpha)
	)

	# [NOTA] Se eliminó la flotación del tag superior para mantenerlo estático y limpio.

	# 4. BARRAS CON ANIMACIÓN DE LLENADO SUAVE al inicio
	if not _intro_done:
		var fill_progress := _ease_out_cubic(_intro_t)
		_bars_current["MEM"] = _bars_target["MEM"] * fill_progress
		_bars_current["SYS"] = _bars_target["SYS"] * fill_progress
		_bars_current["RED"] = _bars_target["RED"] * fill_progress
		for key in _bar_nodes:
			if _bar_nodes[key]:
				_bar_nodes[key].value = _bars_current[key]

	# 5. PULSO SUTIL EN EL BORDE DEL PANEL DERECHO
	if _panel_style:
		var border_alpha := 0.28 + 0.22 * sin(_time * 1.1)
		_panel_style.border_color = Color(C_ACCENT_PLAY.r, C_ACCENT_PLAY.g, C_ACCENT_PLAY.b, border_alpha)


# ══════════════════════════════════════════════════════════════════════════════
#  LAYOUT Y POSICIONAMIENTO
# ══════════════════════════════════════════════════════════════════════════════
func _setup_positions():
	var left          = $UILayer/UIControl/LeftPanel
	var right         = $UILayer/UIControl/RightPanel
	var button_group  = $UILayer/UIControl/LeftPanel/ButtonGroup

	left.position  = Vector2(72, 108)
	left.size      = Vector2(550, 520) # Incrementado ligeramente el ancho para albergar los textos más grandes
	left.add_theme_constant_override("separation", 24) # Ajustado el espacio entre textos
	button_group.add_theme_constant_override("separation", 16)

	right.position = Vector2(820, 340)
	right.size     = Vector2(280, 270)

	version_label.position = Vector2(72, 668)

	if has_node("UILayer/UIControl/RightPanel/LunaSprite"):
		$UILayer/UIControl/RightPanel/LunaSprite.position = Vector2(140, 70)


# ══════════════════════════════════════════════════════════════════════════════
#  TEXTOS E IDENTIDAD (MÁS GRANDES Y SIN SUBRAYADO)
# ══════════════════════════════════════════════════════════════════════════════
func _setup_labels():
	# ── TAG SUPERIOR ──────────────────────────────────────────────────────────
	game_tag.text = "//  S I S T E M A   D E   I A   ·   V E R S I Ó N   1 . 0"
	game_tag.add_theme_color_override("font_color", C_TAG)
	game_tag.add_theme_font_size_override("font_size", 16)

	# ── TÍTULO PRINCIPAL ──────────────────────────────────────────────────────
	game_title.text = "LUNA"
	game_title.add_theme_font_size_override("font_size", _title_base_size)
	game_title.add_theme_color_override("font_color", C_WHITE)
	game_title.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.16, 0.5))
	game_title.add_theme_constant_override("outline_size", 4)

	# ── SUBTÍTULO ─────────────────────────────────────────────────────────────
	game_sub.text = "PROTOCOLO  DE  RECONSTRUCCIÓN  NEURAL"
	game_sub.add_theme_color_override("font_color", C_SUB)
	game_sub.add_theme_font_size_override("font_size", 18)
	
	# Forzamos eliminar el contorno para esta fuente
	game_sub.add_theme_constant_override("outline_size", 0)

	# ── VERSIÓN ───────────────────────────────────────────────────────────────
	version_label.text = "LUNA  ·  BUILD 1.0.0  ·  ARC I"
	version_label.add_theme_color_override("font_color", C_VERSION)
	version_label.add_theme_font_size_override("font_size", 10)

# ══════════════════════════════════════════════════════════════════════════════
#  BOTONES
# ══════════════════════════════════════════════════════════════════════════════
func _setup_buttons():
	var buttons_data := [
		[play_btn,     play_icon,     "J U G A R",             C_ACCENT_PLAY, "▶"],
		[settings_btn, settings_icon, "C O N F I G U R A C I Ó N", C_ACCENT_CFG,  "◈"],
		[quit_btn,     quit_icon,     "S A L I R",             C_ACCENT_QUIT, "✕"],
	]

	for b in buttons_data:
		var btn        : Button = b[0]
		var icon       : Label  = b[1]
		var label_text : String = b[2]
		var accent     : Color  = b[3]
		var icon_char  : String = b[4]

		btn.text                    = label_text
		btn.alignment               = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal   = Control.SIZE_SHRINK_BEGIN
		btn.custom_minimum_size     = Vector2(360, 62)
		btn.focus_mode              = Control.FOCUS_NONE
		btn.clip_children           = CanvasItem.CLIP_CHILDREN_DISABLED

		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color",         C_WHITE)
		btn.add_theme_color_override("font_hover_color",   C_WHITE)
		btn.add_theme_color_override("font_pressed_color", accent)

		# Estilo Normal
		var s_normal := StyleBoxFlat.new()
		s_normal.bg_color              = C_BG_BTN
		s_normal.border_color          = C_BORDER_BASE
		s_normal.set_border_width_all(1)
		s_normal.set_corner_radius_all(10)
		s_normal.content_margin_left   = 68
		s_normal.content_margin_top    = 4
		s_normal.content_margin_bottom = 4

		# Estilo Hover
		var s_hover := StyleBoxFlat.new()
		s_hover.bg_color              = Color(accent.r * 0.08, accent.g * 0.08, accent.b * 0.12, 0.60)
		s_hover.border_color          = Color(accent.r, accent.g, accent.b, 0.90)
		s_hover.set_border_width_all(1)
		s_hover.set_corner_radius_all(10)
		s_hover.content_margin_left   = 68
		s_hover.content_margin_top    = 4
		s_hover.content_margin_bottom = 4
		s_hover.shadow_color          = Color(accent.r, accent.g, accent.b, 0.18)
		s_hover.shadow_size           = 10

		# Estilo Pressed
		var s_pressed := StyleBoxFlat.new()
		s_pressed.bg_color              = Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.22, 0.55)
		s_pressed.border_color          = accent
		s_pressed.set_border_width_all(1)
		s_pressed.set_corner_radius_all(10)
		s_pressed.content_margin_left   = 70
		s_pressed.content_margin_top    = 6
		s_pressed.content_margin_bottom = 2

		btn.add_theme_stylebox_override("normal",  s_normal)
		btn.add_theme_stylebox_override("hover",   s_hover)
		btn.add_theme_stylebox_override("pressed", s_pressed)

		icon.text = icon_char
		icon.position = Vector2(22, 20)
		icon.add_theme_font_size_override("font_size", 16)
		icon.add_theme_color_override("font_color", accent)


# ══════════════════════════════════════════════════════════════════════════════
#  PANEL DERECHO — LUNA
# ══════════════════════════════════════════════════════════════════════════════
func _setup_luna_panel():
	var right_panel    = $UILayer/UIControl/RightPanel
	var vbox           = $UILayer/UIControl/RightPanel/VBoxContainer
	var bars_container = $UILayer/UIControl/RightPanel/VBoxContainer/BarsContainer

	vbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	vbox.grow_vertical    = Control.GROW_DIRECTION_BEGIN
	vbox.offset_left      = 20
	vbox.offset_right     = -20
	vbox.offset_bottom    = -20
	vbox.offset_top       = 0
	vbox.add_theme_constant_override("separation", 8)

	bars_container.add_theme_constant_override("separation", 10)
	bars_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_bar_nodes["MEM"] = bar_mem
	_bar_nodes["SYS"] = bar_sys
	_bar_nodes["RED"] = bar_red

	_format_and_align_bar(bar_mem, "MEM", C_ACCENT_CFG,  _bars_target["MEM"])
	_format_and_align_bar(bar_sys, "SYS", C_ACCENT_QUIT, _bars_target["SYS"])
	_format_and_align_bar(bar_red, "RED", C_ACCENT_PLAY, _bars_target["RED"])

	bar_mem.value = 0.0
	bar_sys.value = 0.0
	bar_red.value = 0.0

	luna_label.text = "A G E N T E   ·   L U N A"
	luna_label.add_theme_font_size_override("font_size", 11)
	luna_label.add_theme_color_override("font_color", C_LUNA_LABEL)
	luna_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	status_label.text = "●   E N   E S P E R A"
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", C_STATUS)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color         = C_PANEL_BG
	_panel_style.border_color     = C_BORDER_BASE
	_panel_style.set_border_width_all(1)
	_panel_style.set_corner_radius_all(16)
	_panel_style.shadow_color     = Color(C_ACCENT_PLAY.r, C_ACCENT_PLAY.g, C_ACCENT_PLAY.b, 0.10)
	_panel_style.shadow_size      = 12
	right_panel.add_theme_stylebox_override("panel", _panel_style)


func _format_and_align_bar(bar: ProgressBar, label_text: String, color: Color, default_val: float):
	if not bar or not bar.is_inside_tree(): return
	if bar.get_parent() is HBoxContainer:
		bar.value = default_val
		return

	var original_container = bar.get_parent()

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)

	original_container.remove_child(bar)
	original_container.add_child(row)

	var indicator := Label.new()
	indicator.text = label_text
	indicator.custom_minimum_size = Vector2(36, 0)
	indicator.add_theme_font_size_override("font_size", 10)
	indicator.add_theme_color_override("font_color", C_LUNA_LABEL)
	row.add_child(indicator)

	row.add_child(bar)

	bar.show_percentage = false
	bar.value           = default_val
	bar.custom_minimum_size.y    = 6
	bar.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical      = Control.SIZE_SHRINK_CENTER

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.06, 0.15, 0.80)
	bg_style.set_corner_radius_all(4)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.set_corner_radius_all(4)
	fill_style.shadow_color = Color(color.r, color.g, color.b, 0.35)
	fill_style.shadow_size  = 4

	bar.add_theme_stylebox_override("background", bg_style)
	bar.add_theme_stylebox_override("fill",        fill_style)


# ══════════════════════════════════════════════════════════════════════════════
#  HELPERS / SEÑALES
# ══════════════════════════════════════════════════════════════════════════════
func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

func _on_play():
	get_tree().change_scene_to_file("res://Scenes/introduction.tscn")

func _on_quit():
	get_tree().quit()
