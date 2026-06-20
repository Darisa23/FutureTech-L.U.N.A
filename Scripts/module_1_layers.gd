extends Node2D

var fragments_data = [
	{"id": "hostilidad", "label": "Hostilidad", "type": "input"},
	{"id": "velocidad", "label": "Velocidad", "type": "input"},
	{"id": "decision", "label": "¿Amigo o\nEnemigo?", "type": "output"},
]

var scatter_positions = []
var input_slots = []
var output_slot = Vector2.ZERO
var hidden_slots = []

var fragment_buttons = []
var fragment_placed = []
var selected_index = -1

var n_hidden = 0
var hidden_neuron_nodes = []
var min_hidden_reached = false
const MIN_HIDDEN = 2

var stage = "placing"

const FRAGMENT_SIZE = Vector2(140, 60)

@onready var zone_input = $ZoneInput
@onready var zone_hidden = $ZoneHidden
@onready var zone_output = $ZoneOutput
@onready var fragments_container = $FragmentsContainer
@onready var description_label = $DescriptionLabel
@onready var feedback_label = $FeedbackLabel
@onready var param_counter_label = $ParamCounterLabel
@onready var add_neuron_button = $AddNeuronButton
@onready var activate_button = $ActivateButton
@onready var next_button = $NextButton
@onready var princess_sprite = $PrincessSprite

const COLOR_INPUT = Color("#4a9eff")
const COLOR_OUTPUT = Color("#e74c3c")
const COLOR_HIDDEN = Color("#9b59b6")
const COLOR_SELECTED_BORDER = Color("#ffffff")
const COLOR_LINE_DIM = Color(0.4, 0.4, 0.4, 0.5)       # líneas permanentes, tenues
const COLOR_LINE_LIT = Color("#ffe066")                 # líneas "iluminadas" tras activar

var lit_input_lines = false
var lit_hidden_lines = false
@onready var lines_layer = $LinesLayer

func _ready():
	lines_layer.parent_module = self
	zone_input.mouse_filter = Control.MOUSE_FILTER_PASS
	zone_hidden.mouse_filter = Control.MOUSE_FILTER_PASS
	zone_output.mouse_filter = Control.MOUSE_FILTER_PASS

	zone_input.gui_input.connect(func(event): _on_zone_clicked(event, "input"))
	zone_output.gui_input.connect(func(event): _on_zone_clicked(event, "output"))
	zone_hidden.gui_input.connect(func(event): _on_zone_clicked(event, "hidden"))

	add_neuron_button.pressed.connect(_on_add_neuron_pressed)
	activate_button.pressed.connect(_on_activate_pressed)
	next_button.pressed.connect(_on_next_pressed)

	next_button.visible = false
	add_neuron_button.visible = false
	activate_button.visible = false
	param_counter_label.text = "Parámetros: 0"

	description_label.text = "Estos son fragmentos de la percepción de LUNA. Selecciónalos y haz click en la zona donde crees que pertenecen: los sensores van a ENTRADA, la decisión va a SALIDA."

	var luna = $LUNA  # o get_node("ruta/a/Luna")
	luna.get_node("AnimationPlayer").play("depresiva")
	
	_compute_layout_positions()
	_create_fragments()

func _compute_layout_positions():
	var n_inputs = 0
	for f in fragments_data:
		if f["type"] == "input":
			n_inputs += 1

	input_slots.clear()
	for i in n_inputs:
		var t = (float(i) + 0.5) / float(n_inputs)
		var x = zone_input.position.x + zone_input.size.x / 2
		var y = zone_input.position.y + zone_input.size.y * t
		input_slots.append(Vector2(x, y))

	output_slot = zone_output.position + zone_output.size / 2

	scatter_positions.clear()
	var n = fragments_data.size()
	for i in n:
		var t = (float(i) + 0.5) / float(n)
		var x = zone_hidden.position.x + zone_hidden.size.x * (0.25 + 0.5 * t)
		var y = zone_hidden.position.y + zone_hidden.size.y * (0.3 + 0.4 * sin(t * PI))
		scatter_positions.append(Vector2(x, y))

	#hidden_slots.clear()
	#for i in MIN_HIDDEN:
		#var t = (float(i) + 0.5) / float(MIN_HIDDEN)
		#var x = zone_hidden.position.x + zone_hidden.size.x / 2
		#var y = zone_hidden.position.y + zone_hidden.size.y * t
		#hidden_slots.append(Vector2(x, y))

func _create_fragments():
	for i in fragments_data.size():
		var data = fragments_data[i]
		var btn = Button.new()
		btn.text = data["label"]
		btn.custom_minimum_size = FRAGMENT_SIZE
		btn.position = scatter_positions[i] - FRAGMENT_SIZE / 2
		btn.mouse_filter = Control.MOUSE_FILTER_STOP

		var is_input = data["type"] == "input"

		# Estilo normal
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#0e1a2e") if is_input else Color("#1a0808")
		style.border_color = Color("#4a9eff") if is_input else Color("#e74c3c")
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.content_margin_left = 10
		style.content_margin_right = 10

		# Estilo hover
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color("#162840") if is_input else Color("#2a1010")
		style_hover.border_color = Color("#7dc8ff") if is_input else Color("#ff8080")
		style_hover.set_border_width_all(1)
		style_hover.set_corner_radius_all(6)
		style_hover.content_margin_left = 10
		style_hover.content_margin_right = 10

		# Estilo focus vacío
		var style_focus = StyleBoxEmpty.new()

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", style_focus)
		btn.add_theme_color_override("font_color", Color("#7dc8ff") if is_input else Color("#ff8080"))
		btn.add_theme_color_override("font_hover_color", Color("#c4e8ff") if is_input else Color("#ffb0b0"))

		var idx = i
		btn.pressed.connect(func(): _on_fragment_pressed(idx))

		fragments_container.add_child(btn)
		fragment_buttons.append(btn)
		fragment_placed.append(false)

func _on_fragment_pressed(index: int):
	if fragment_placed[index]:
		return
	if selected_index == index:
		_set_selected(-1)
	else:
		_set_selected(index)

func _set_selected(index: int):
	if selected_index != -1 and selected_index < fragment_buttons.size():
		var prev_style = fragment_buttons[selected_index].get_theme_stylebox("normal")
		if prev_style is StyleBoxFlat:
			prev_style.set_border_width_all(0)

	selected_index = index

	if index != -1:
		var style = fragment_buttons[index].get_theme_stylebox("normal")
		if style is StyleBoxFlat:
			style.border_color = COLOR_SELECTED_BORDER
			style.set_border_width_all(3)
		feedback_label.text = "Selecciona la zona donde crees que va este fragmento."
		feedback_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		feedback_label.text = ""

func _on_zone_clicked(event: InputEvent, zone_type: String):
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if selected_index == -1:
		return

	if zone_type == "hidden":
		_wrong_zone()
	else:
		_try_place(selected_index, zone_type)

func _try_place(index: int, zone_type: String):
	var data = fragments_data[index]

	if data["type"] != zone_type:
		_wrong_zone()
		return

	var target_pos: Vector2
	if zone_type == "input":
		var slot_idx = _count_placed_inputs()
		target_pos = input_slots[slot_idx] - FRAGMENT_SIZE / 2
	else:
		target_pos = output_slot - FRAGMENT_SIZE / 2

	var btn = fragment_buttons[index]
	var tween = create_tween()
	tween.tween_property(btn, "position", target_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	fragment_placed[index] = true
	_set_selected(-1)

	feedback_label.text = "¡Bien! Fragmento conectado."
	feedback_label.add_theme_color_override("font_color", Color("#00ff88"))

	_check_phase1_complete()

func _count_placed_inputs() -> int:
	var count = 0
	for i in fragments_data.size():
		if fragments_data[i]["type"] == "input" and fragment_placed[i]:
			count += 1
	return count

func _wrong_zone():
	feedback_label.text = "LUNA se confunde... este fragmento no pertenece ahí."
	feedback_label.add_theme_color_override("font_color", Color("#ff4444"))

	var btn = fragment_buttons[selected_index]
	var original_pos = btn.position
	var tween = create_tween()
	tween.tween_property(btn, "position", original_pos + Vector2(10, 0), 0.05)
	tween.tween_property(btn, "position", original_pos - Vector2(10, 0), 0.05)
	tween.tween_property(btn, "position", original_pos, 0.05)

func _check_phase1_complete():
	for placed in fragment_placed:
		if not placed:
			return
	_on_phase1_complete()

func _on_phase1_complete():
	description_label.text = "Conexión directa: Entrada → Salida. Presiona el botón para ver cómo responde LUNA así, con esta conexión tan simple. Puedes activarla varias veces."
	feedback_label.text = ""
	param_counter_label.text = "Parámetros: 3"
	stage = "demo1"
	activate_button.text = "▶ Activar a LUNA"
	activate_button.visible = true

func _on_activate_pressed():
	activate_button.disabled = true

	if stage == "demo1" or stage == "demo1_seen":
		lit_input_lines = true
		await _run_pulse_direct()
		stage = "demo1_seen"
		description_label.text = "¿Notaste algo? La salida cambia siempre en la MISMA proporción que la entrada: una respuesta lineal, simple y predecible... pero limitada.\n\nPuedes activarla otra vez, o continuar."
		next_button.text = "Continuar →"
		next_button.visible = true

	elif stage == "ready2" or stage == "ready2_seen" or stage == "complete":
		lit_hidden_lines = true
		await _run_pulse_hidden()
		stage = "ready2_seen"
		description_label.text = "¡Ahora la información pasa por neuronas de pensamiento antes de llegar a la decisión final! Esta es la arquitectura clásica de una red neuronal: Entrada → Oculta → Salida."
		next_button.text = "Siguiente →"
		next_button.visible = true

	activate_button.disabled = false

func _on_next_pressed():
	if stage == "demo1_seen":
		next_button.visible = false
		activate_button.visible = false
		add_neuron_button.visible = true
		stage = "adding_hidden"
		description_label.text = "Agrega neuronas de pensamiento a LUNA. Necesita al menos 2 para empezar a reconocer patrones complejos."
	
	elif stage == "ready2_seen":
		# Cuando ve la animación con las neuronas ocultas, habilitamos el paso final
		next_button.visible = false
		activate_button.visible = false
		add_neuron_button.visible = false
		stage = "complete"
		# Forzamos a que avance directo o puedes mostrar un mensaje final antes del cambio
		_cambiar_a_siguiente_escena()
		
	elif stage == "complete":
		_cambiar_a_siguiente_escena()

func _cambiar_a_siguiente_escena():
	var ruta_siguiente_escena = "res://Scenes/arc1/concept_intro2.tscn" 
	
	get_tree().change_scene_to_file(ruta_siguiente_escena)

func _on_add_neuron_pressed():
	n_hidden += 1
	_recompute_hidden_slots(n_hidden)

	# Crear el panel de la neurona nueva (última posición)
	var pos = hidden_slots[n_hidden - 1]
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_HIDDEN
	style.set_corner_radius_all(20)
	style.border_color = Color.WHITE
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.size = Vector2(40, 40)
	panel.pivot_offset = panel.size / 2
	panel.position = pos - panel.size / 2
	panel.scale = Vector2(0, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fragments_container.add_child(panel)
	hidden_neuron_nodes.append(panel)

	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Reposicionar (con animación) las neuronas existentes a su nuevo slot
	for i in hidden_neuron_nodes.size() - 1:
		var node = hidden_neuron_nodes[i]
		var new_pos = hidden_slots[i] - node.size / 2
		var reposition_tween = create_tween()
		reposition_tween.tween_property(node, "position", new_pos, 0.3).set_trans(Tween.TRANS_SINE)

	param_counter_label.text = "Parámetros: %d" % (n_hidden * 4 + 1)
	feedback_label.text = "Nueva neurona de pensamiento conectada."
	feedback_label.add_theme_color_override("font_color", Color("#9b59b6"))

	if n_hidden >= MIN_HIDDEN and not min_hidden_reached:
		min_hidden_reached = true
		activate_button.text = "▶ Activar a LUNA"
		activate_button.visible = true
		activate_button.disabled = false
		stage = "ready2"
		description_label.text = "¡Neuronas de pensamiento conectadas! Puedes agregar más, o presiona Activar para ver el nuevo flujo completo."

func _recompute_hidden_slots(count: int):
	hidden_slots.clear()
	for i in count:
		var t = (float(i) + 0.5) / float(count)
		var x = zone_hidden.position.x + zone_hidden.size.x / 2
		var y = zone_hidden.position.y + zone_hidden.size.y * t
		hidden_slots.append(Vector2(x, y))

func _index_of_type(type: String) -> int:
	for i in fragments_data.size():
		if fragments_data[i]["type"] == type:
			return i
	return -1

func _run_pulse_direct():
	var output_idx = _index_of_type("output")
	var output_pos = fragment_buttons[output_idx].position + FRAGMENT_SIZE / 2

	for i in fragments_data.size():
		if fragments_data[i]["type"] == "input":
			var from = fragment_buttons[i].position + FRAGMENT_SIZE / 2
			_spawn_pulse(from, output_pos, Color("#ffe066"), 1.4)

	await get_tree().create_timer(1.5).timeout

func _run_pulse_hidden():
	var output_idx = _index_of_type("output")
	var output_pos = fragment_buttons[output_idx].position + FRAGMENT_SIZE / 2

	var input_positions = []
	for i in fragments_data.size():
		if fragments_data[i]["type"] == "input":
			input_positions.append(fragment_buttons[i].position + FRAGMENT_SIZE / 2)

	for h in hidden_slots:
		for ip in input_positions:
			_spawn_pulse(ip, h, Color("#ffe066"), 1.0)

	await get_tree().create_timer(1.1).timeout

	for h in hidden_slots:
		_spawn_pulse(h, output_pos, Color("#7CFC9A"), 1.0)

	await get_tree().create_timer(1.1).timeout

func _spawn_pulse(from: Vector2, to: Vector2, color: Color, duration: float):
	var pulse = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.shadow_color = Color(color.r, color.g, color.b, 0.6)
	style.shadow_size = 14
	pulse.add_theme_stylebox_override("panel", style)
	pulse.size = Vector2(20, 20)
	pulse.pivot_offset = pulse.size / 2
	pulse.position = from - pulse.size / 2
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pulse)

	var move_tween = create_tween()
	move_tween.tween_property(pulse, "position", to - pulse.size / 2, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	move_tween.tween_callback(pulse.queue_free)

	var pulse_tween = create_tween()
	pulse_tween.set_loops(int(duration / 0.4) + 1)
	pulse_tween.tween_property(pulse, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(pulse, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_SINE)

func _draw_lines(layer: Node2D):
	var output_idx = _index_of_type("output")
	if output_idx == -1 or not fragment_placed[output_idx]:
		return
	var output_pos = fragment_buttons[output_idx].position + FRAGMENT_SIZE / 2

	var input_positions = []
	for i in fragments_data.size():
		if fragments_data[i]["type"] == "input" and fragment_placed[i]:
			input_positions.append(fragment_buttons[i].position + FRAGMENT_SIZE / 2)

	if n_hidden == 0:
		var line_color = COLOR_LINE_LIT if lit_input_lines else COLOR_LINE_DIM
		for ip in input_positions:
			layer.draw_line(ip, output_pos, line_color, 2.0)
	else:
		var line_color_ih = COLOR_LINE_LIT if lit_hidden_lines else COLOR_LINE_DIM
		var line_color_ho = Color("#7CFC9A") if lit_hidden_lines else COLOR_LINE_DIM

		for i in n_hidden:
			var h = hidden_slots[i]
			for ip in input_positions:
				layer.draw_line(ip, h, line_color_ih, 2.0)
			layer.draw_line(h, output_pos, line_color_ho, 2.0)
