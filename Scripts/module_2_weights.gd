extends Node2D

var network: LunaNetwork

var challenges = [
	{
		"inputs": [0.1, 0.9],
		"target": "ENEMIGO",
		"target_value": 0.0,
		"description": "Una figura oscura se acerca...\nSeñales: [Hostil: 0.9, Velocidad: 0.9]",
		"hint": "Pesos negativos hacia output ayudan a identificar enemigos."
	},
	{
		"inputs": [0.9, 0.2],
		"target": "ALIADO",
		"target_value": 1.0,
		"description": "Una figura con emblema del reino...\nSeñales: [Hostil: 0.3, Velocidad: 0.2]",
		"hint": "Pesos positivos fuertes hacia output identifican aliados."
	},
	{
		"inputs": [0.5, 0.6],
		"target": "CONFUNDIDA",
		"target_value": 0.0,
		"description": "Señales confusas... pero algo está mal.\nSeñales: [Hostil: 0.5, Velocidad: 0.6]",
		"hint": "A veces necesitas ajustar la capa hidden para casos ambiguos."
	}
]

var current_challenge = 0
var challenge_solved = false

@onready var output_label = $OutputLabel
@onready var sliders_panel = $SlidersPanel
@onready var description_label = $DescriptionLabel
@onready var feedback_label = $FeedbackLabel
@onready var next_button = $NextButton
@onready var princess_sprite = $LunaSprite
@onready var luna = $LUNA
@onready var creature_sprite = $CreatureSprite
@onready var verify_button = $VerifyButton

# Recursos de SpriteFrames precargados
var enemy_frames = preload("res://assets/sprites/enemy_frames.tres")
var ally_frames = preload("res://assets/sprites/ally_frames.tres")
var confused_frames = preload("res://assets/sprites/confused_frames.tres")

# Escala "real" del sprite, capturada antes de animar el approach
var creature_target_scale: Vector2
var creature_base_position: Vector2

func _ready():
	network = LunaNetwork.new()
	_build_sliders()

	# Capturamos los valores originales puestos en el editor
	creature_target_scale = creature_sprite.scale
	creature_base_position = creature_sprite.position

	_load_challenge(0)

func _load_challenge(index: int):
	challenge_solved = false
	var c = challenges[index]
	description_label.text = c["description"]
	feedback_label.text = "Ajusta los pesos hasta que LUNA lo identifique correctamente."
	feedback_label.add_theme_color_override("font_color", Color.WHITE)
	next_button.visible = false
	verify_button.disabled = false

	_set_creature_for_target(c["target"])
	creature_sprite.play("approach")
	princess_sprite.play("idle")
	luna.get_node("AnimationPlayer").play("idle")

	_update_preview()
	_animate_approach()

func _set_creature_for_target(target: String):
	match target:
		"ENEMIGO":
			creature_sprite.sprite_frames = enemy_frames
		"ALIADO":
			creature_sprite.sprite_frames = ally_frames
		_:
			creature_sprite.sprite_frames = confused_frames
	creature_sprite.flip_h = true
func _update_preview():
	if not network:
		return
	var c = challenges[current_challenge]
	var output = network.forward(c["inputs"])

	var luna_says = "CONFUNDIDA"
	if output > 0.65:
		luna_says = "ALIADO"
	elif output < 0.35:
		luna_says = "ENEMIGO"

	output_label.text = "Lectura: %s\n(%.2f)" % [luna_says, output]
	output_label.set_meta("last_reading", luna_says)


func _build_sliders():
	var title = Label.new()
	title.text = "Pesos: Input → Hidden"
	title.add_theme_color_override("font_color", Color.WHITE)
	sliders_panel.add_child(title)

	for row in 2:
		for col in 2:
			var container = HBoxContainer.new()

			var lbl = Label.new()
			lbl.text = "w%d%d" % [row, col]
			lbl.custom_minimum_size = Vector2(40, 0)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			container.add_child(lbl)

			var slider = HSlider.new()
			slider.min_value = -2.0
			slider.max_value = 2.0
			slider.step = 0.01
			slider.value = network.weights_ih[row][col]
			slider.custom_minimum_size = Vector2(180, 20)
			var r = row; var c = col
			slider.value_changed.connect(func(val): _on_weight_ih_changed(r, c, val))
			container.add_child(slider)

			var val_label = Label.new()
			val_label.text = "%.2f" % network.weights_ih[row][col]
			val_label.custom_minimum_size = Vector2(45, 0)
			val_label.add_theme_color_override("font_color", Color.PALE_VIOLET_RED)
			val_label.name = "ValLabel_%d_%d" % [row, col]
			container.add_child(val_label)

			sliders_panel.add_child(container)

	var sep = HSeparator.new()
	sliders_panel.add_child(sep)

	var title2 = Label.new()
	title2.text = "Pesos: Hidden --> Output"
	title2.add_theme_color_override("font_color", Color.WHITE)
	sliders_panel.add_child(title2)

	for row in 2:
		var container = HBoxContainer.new()

		var lbl = Label.new()
		lbl.text = "wo%d" % row
		lbl.custom_minimum_size = Vector2(40, 0)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		container.add_child(lbl)

		var slider = HSlider.new()
		slider.min_value = -2.0
		slider.max_value = 2.0
		slider.step = 0.01
		slider.value = network.weights_ho[row][0]
		slider.custom_minimum_size = Vector2(180, 20)
		var r = row
		slider.value_changed.connect(func(val): _on_weight_ho_changed(r, val))
		container.add_child(slider)

		var val_label = Label.new()
		val_label.text = "%.2f" % network.weights_ho[row][0]
		val_label.custom_minimum_size = Vector2(45, 0)
		val_label.add_theme_color_override("font_color", Color.PALE_VIOLET_RED)
		val_label.name = "ValLabelO_%d" % row
		container.add_child(val_label)

		sliders_panel.add_child(container)

	var sep2 = HSeparator.new()
	sliders_panel.add_child(sep2)

	var hint_btn = Button.new()
	hint_btn.text = "Pedir pista"
	hint_btn.pressed.connect(_show_hint)
	sliders_panel.add_child(hint_btn)


func _show_hint():
	feedback_label.text = " " + challenges[current_challenge]["hint"]
	feedback_label.add_theme_color_override("font_color", Color.YELLOW)

func _on_next_pressed():
	if current_challenge < challenges.size() - 1:
		creature_sprite.visible = true
		current_challenge += 1
		_load_challenge(current_challenge)
	else:
		feedback_label.text = "¡Completaste el módulo! LUNA puede distinguir amigos de enemigos."
		feedback_label.add_theme_color_override("font_color", Color("#00ff88"))
		next_button.visible = true
		await get_tree().create_timer(3).timeout
		get_tree().change_scene_to_file("res://Scenes/arc2/the_collapse.tscn")


func _draw():
	var input_nodes = [Vector2(420, 200), Vector2(420, 350)]
	var hidden_nodes = [Vector2(570, 200), Vector2(570, 350)]
	var output_node = Vector2(720, 275)

	for i in input_nodes.size():
		for j in hidden_nodes.size():
			var w = network.weights_ih[i][j] if network else 0.0
			var col = Color(0.2, 0.8, 0.2) if w > 0 else Color(0.8, 0.2, 0.2)
			col.a = clamp(abs(w) / 2.0, 0.1, 1.0)
			draw_line(input_nodes[i], hidden_nodes[j], col, 2.0)

	for i in hidden_nodes.size():
		var w = network.weights_ho[i][0] if network else 0.0
		var col = Color(0.2, 0.8, 0.2) if w > 0 else Color(0.8, 0.2, 0.2)
		col.a = clamp(abs(w) / 2.0, 0.1, 1.0)
		draw_line(hidden_nodes[i], output_node, col, 2.0)

	for pos in input_nodes:
		draw_circle(pos, 18, Color("#4a9eff"))
		draw_arc(pos, 18, 0, TAU, 32, Color.WHITE, 1.5)

	for pos in hidden_nodes:
		draw_circle(pos, 18, Color("#9b59b6"))
		draw_arc(pos, 18, 0, TAU, 32, Color.WHITE, 1.5)

	draw_circle(output_node, 22, Color("#e74c3c"))
	draw_arc(output_node, 22, 0, TAU, 32, Color.WHITE, 2.0)


func _on_next_button_pressed() -> void:
	_on_next_pressed()

func _on_verify_pressed():
	if challenge_solved:
		return

	var c = challenges[current_challenge]
	var output = network.forward(c["inputs"])
	var target = c["target"]

	var luna_says = "CONFUNDIDA"
	if output > 0.65:
		luna_says = "ALIADO"
	elif output < 0.35:
		luna_says = "ENEMIGO"

	verify_button.disabled = true

	if luna_says == target:
		_play_success(target)
	else:
		_play_failure(target)

func _play_success(target: String):
	challenge_solved = true
	
	

	# Esperamos a que termine la animación de ataque antes de reaccionar la criatura
	#await princess_sprite.animation_finished

	match target:
		"ENEMIGO":
			princess_sprite.play("attack")
			luna.get_node("AnimationPlayer").play("ataque")
			
			creature_sprite.play("death")
			feedback_label.text = "¡LUNA identificó al enemigo!"
		"ALIADO":
			princess_sprite.play("jump")
			luna.get_node("AnimationPlayer").play("idle")
			
			creature_sprite.play("run")
			feedback_label.text = "¡LUNA reconoció a su aliado!"
		_:
			feedback_label.text = "¡Correcto!"

	feedback_label.add_theme_color_override("font_color", Color("#00ff88"))
	await get_tree().create_timer(4.3).timeout
	creature_sprite.visible =false
	await get_tree().create_timer(0.3).timeout
	
	princess_sprite.play("idle")
	luna.get_node("AnimationPlayer").play("idle")
	

	await get_tree().create_timer(1.0).timeout
	next_button.visible = true

func _play_failure(target: String):
	match target:
		"ENEMIGO":
			# LUNA bajó la guardia -> el enemigo ataca primero
			creature_sprite.play("attack")
			feedback_label.text = "LUNA bajó la guardia... ¡es un enemigo!"
			#await creature_sprite.animation_finished
		"ALIADO":
			princess_sprite.play("attack")
			luna.get_node("AnimationPlayer").play("ataque")
			
			feedback_label.text = "LUNA atacó a un aliado por error."
			#await princess_sprite.animation_finished
			creature_sprite.play("death")
		_:
			feedback_label.text = "Inténtalo de nuevo."

	feedback_label.add_theme_color_override("font_color", Color("#ff4444"))
	await get_tree().create_timer(3).timeout

	# Reset para reintentar
	creature_sprite.play("approach")
	princess_sprite.play("idle")
	luna.get_node("AnimationPlayer").play("idle")
	
	verify_button.disabled = false

func _on_weight_ih_changed(row: int, col: int, value: float):
	network.set_weight_ih(row, col, value)
	var lbl = sliders_panel.find_child("ValLabel_%d_%d" % [row, col], true, false)
	if lbl:
		lbl.text = "%.2f" % value
	_update_preview()

func _on_weight_ho_changed(row: int, value: float):
	network.set_weight_ho(row, 0, value)
	var lbl = sliders_panel.find_child("ValLabelO_%d" % row, true, false)
	if lbl:
		lbl.text = "%.2f" % value
	_update_preview()

func _animate_approach():
	creature_sprite.scale = creature_target_scale * 0.3
	creature_sprite.modulate.a = 0.5
	creature_sprite.position.x = creature_base_position.x - 100

	var tween = create_tween()
	tween.tween_property(creature_sprite, "scale", creature_target_scale, 1.0)
	tween.parallel().tween_property(creature_sprite, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(creature_sprite, "position:x", creature_base_position.x, 1.0)

func _on_verify_button_pressed() -> void:
	_on_verify_pressed()
