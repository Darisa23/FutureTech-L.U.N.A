extends Node2D

@onready var luna_sprite = $LunaSprite
@onready var title_label = $TitleLabel
@onready var stars_container = $StarsContainer
@onready var skip_hint = $SkipHint
@onready var stars_particles = $StarsContainer  



func _setup_star_particles():
	stars_particles.texture = _create_soft_dot_texture()
	stars_particles.amount = 180               # Buena densidad para el flujo
	stars_particles.lifetime = 3.0              # Tiempo suficiente para hacer la curva
	stars_particles.one_shot = true
	stars_particles.emitting = false
	stars_particles.local_coords = false        
	

	stars_particles.position = luna_final_pos

	var material = ParticleProcessMaterial.new()
	
	# 1. Área de emisión: Nacen arriba de Luna, dispersas horizontalmente
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	# Nacen en un rectángulo arriba de ella (X: a lo largo de la pantalla, Y: arriba en el techo)
	material.emission_box_extents = Vector3(screen_size.x / 2, 20, 1)
	# Desplazamos el origen de emisión hacia arriba de la pantalla en el eje Y relativo
	material.direction = Vector3(0, 1, 0)
	
	# 2. Velocidad inicial de caída
	material.gravity = Vector3(0, 50, 0)        # Gravedad baja para que floten
	material.initial_velocity_min = 150.0       # Caen rápido desde arriba
	material.initial_velocity_max = 220.0


	material.orbit_velocity_min = 0.2           # Velocidad de giro/arco
	material.orbit_velocity_max = 0.4
	
	# Radial Accel con valor negativo las "atrae" hacia el centro a medida que caen
	material.radial_accel_min = -80.0
	material.radial_accel_max = -40.0

	# 4. Turbulencia para que parezca polvo mágico y no algo rígido
	material.turbulence_enabled = true
	material.turbulence_noise_scale = 5.0
	material.turbulence_influence_min = 0.02
	material.turbulence_influence_max = 0.06

	# 5. Escala Dinámica (Fade out de tamaño)
	material.scale_min = 0.6
	material.scale_max = 2.0
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0, 0))
	scale_curve.add_point(Vector2(0.15, 1))
	scale_curve.add_point(Vector2(0.8, 0.8))
	scale_curve.add_point(Vector2(1, 0))
	var scale_curve_texture = CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	material.scale_curve = scale_curve_texture

	# 6. Colores de la paleta expandidos
	var color_ramp = Gradient.new()
	color_ramp.add_point(0.0, Color("#b6effb", 0.0)) # Nace invisible (Cian)
	color_ramp.add_point(0.15, Color("#b6effb", 1.0))
	color_ramp.add_point(0.45, Color("#fef4af", 1.0)) # Amarillo Luna
	color_ramp.add_point(0.75, Color("#fca6d1", 0.9)) # Rosa capa
	color_ramp.add_point(1.0, Color("#4c2b69", 0.0))  # Se apaga en púrpura

	var color_ramp_texture = GradientTexture1D.new()
	color_ramp_texture.gradient = color_ramp
	material.color_ramp = color_ramp_texture

	stars_particles.process_material = material
func _create_soft_dot_texture() -> ImageTexture:
	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)

	for x in size:
		for y in size:
			var dist = Vector2(x, y).distance_to(center) / (size / 2.0)
			var alpha = clamp(1.0 - dist, 0.0, 1.0)
			alpha = pow(alpha, 2.0)  # falloff más suave, tipo glow
			img.set_pixel(x, y, Color(1, 1, 1, alpha))

	return ImageTexture.create_from_image(img)
	
var screen_size = Vector2(1152, 648)
var luna_final_pos: Vector2
var skipped = false

func _ready():
	skip_hint.modulate.a = 0
	title_label.modulate.a = 0

	# Posición final de la luna: centro-alto de la pantalla
	luna_final_pos = Vector2(screen_size.x / 2, screen_size.y * 0.38)

	# Posición inicial: fuera de pantalla, abajo
	luna_sprite.position = Vector2(screen_size.x / 2, screen_size.y + 150)
	luna_sprite.scale = Vector2(0.6, 0.6)
	luna_sprite.modulate.a = 0

	set_process_unhandled_input(true)
	_play_sequence()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		_skip_to_menu()
	elif event is InputEventKey and event.pressed:
		_skip_to_menu()

func _skip_to_menu():
	if skipped:
		return
	skipped = true
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _play_sequence():
	# 1. La luna sube y aparece (fade + movimiento con ease)
	luna_sprite.modulate.a = 1.0
	var tween_luna = create_tween()
	tween_luna.set_parallel(true)
	tween_luna.tween_property(luna_sprite, "position", luna_final_pos, 2.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_luna.tween_property(luna_sprite, "scale", Vector2(1.0, 1.0), 2.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(1.0).timeout

	# 2. Lluvia de estrellas en curva orbital alrededor de la luna
	_setup_star_particles()
	stars_particles.emitting = true
	stars_particles.emitting = true
	print("Particles emitting (despues): ", stars_particles.emitting)

	await get_tree().create_timer(2.2).timeout

	# 3. Revelar título
	await _reveal_title_letter_by_letter("Project L.U.N.A")
	_skip_to_menu()

func _reveal_title_letter_by_letter(text: String):
	title_label.modulate.a = 1.0
	title_label.bbcode_enabled = true
	title_label.text = ""

	for i in text.length():
		title_label.text += text[i]
		await get_tree().create_timer(0.08).timeout
func _spawn_orbital_stars():
	var star_count = 28
	var radius_x = 220.0
	var radius_y = 90.0

	for i in star_count:
		var t = float(i) / float(star_count)
		var angle = t * TAU

		# Posición final: elipse alrededor de la luna
		var end_pos = luna_final_pos + Vector2(cos(angle) * radius_x, sin(angle) * radius_y - 20)

		# Posición inicial: dispersa arriba de la pantalla, "cayendo"
		var start_pos = Vector2(
			randf_range(0, screen_size.x),
			randf_range(-150, -30)
		)

		_create_falling_star(start_pos, end_pos, t)

func _create_falling_star(start_pos: Vector2, end_pos: Vector2, delay_factor: float):
	var star = ColorRect.new()
	var size = randf_range(4, 8)
	star.size = Vector2(size, size)
	star.pivot_offset = star.size / 2
	star.color = Color("#fef4af")  # amarillo cabello, tono cálido para las estrellas
	star.position = start_pos
	star.rotation_degrees = 45
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars_container.add_child(star)

	var delay = delay_factor * 0.8

	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(star, "position", end_pos, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "rotation_degrees", 360, 1.4)

	# Brillo pulsante una vez llega a su órbita
	tween.tween_callback(func():
		var pulse = create_tween()
		pulse.set_loops(0)
		pulse.tween_property(star, "modulate:a", 0.4, 0.6).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(star, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	)
