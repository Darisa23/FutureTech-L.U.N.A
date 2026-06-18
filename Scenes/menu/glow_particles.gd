extends Node2D

var particles = []
const N = 70

func _ready():
	randomize()

	var viewport_size = get_viewport_rect().size

	for i in N:
		particles.append({
			"x": randf() * viewport_size.x,
			"y": randf() * viewport_size.y,
			"size": randf_range(0.8, 2.5),
			"speed": randf_range(0.05, 0.25),
			"opacity": randf_range(0.08, 0.25),
			"blue": randf() > 0.5
		})

func _process(delta):
	var viewport_size = get_viewport_rect().size

	for p in particles:
		p["y"] -= p["speed"]

		if p["y"] < 0:
			p["y"] = viewport_size.y
			p["x"] = randf() * viewport_size.x

	queue_redraw()

func _draw():
	var viewport_size = get_viewport_rect().size

	# =========================
	# GLOW DE FONDO DIFUMINADO
	# =========================

	var glow_centers = [
		Vector2(260, viewport_size.y * 0.40),
		Vector2(300, viewport_size.y * 0.42),
		Vector2(340, viewport_size.y * 0.46)
	]

	for center in glow_centers:
		for r in range(400, 0, -10):

			var alpha = pow(float(r) / 400.0, 2.5) * 0.003

			draw_circle(
				center,
				r,
				Color(
					0.48,
					0.23,
					0.93,
					alpha
				)
			)

	# =========================
	# PARTÍCULAS CON GLOW
	# =========================

	for p in particles:

		var base_color = (
			Color(0.29, 0.62, 1.0, p["opacity"])
			if p["blue"]
			else Color(0.75, 0.45, 1.0, p["opacity"])
		)

		var pos = Vector2(p["x"], p["y"])

		# Halo exterior
		draw_circle(
			pos,
			p["size"] * 6.0,
			Color(
				base_color.r,
				base_color.g,
				base_color.b,
				0.01
			)
		)

		# Halo medio
		draw_circle(
			pos,
			p["size"] * 4.0,
			Color(
				base_color.r,
				base_color.g,
				base_color.b,
				0.03
			)
		)

		# Halo interno
		draw_circle(
			pos,
			p["size"] * 2.0,
			Color(
				base_color.r,
				base_color.g,
				base_color.b,
				0.08
			)
		)

		# Núcleo
		draw_circle(
			pos,
			p["size"],
			base_color
		)
