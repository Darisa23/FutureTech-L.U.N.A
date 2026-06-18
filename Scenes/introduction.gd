extends Node
# Le decimos a Godot exactamente en qué sub-nodo está la cámara
@onready var camara = $Node2D/Camera2D

# Variables para controlar el temblor
var tiempo_temblor: float = 0.0
var fuerza_temblor: float = 0.0

func _ready():
	# Escuchamos la señal de Dialogic
	Dialogic.signal_event.connect(_al_recibir_senal_dialogic)
	
	# Inicia tu línea de tiempo (reemplaza 'nombre_de_tu_timeline' con la tuya)
	Dialogic.start('introduction')

# Esta función se activa cuando pones el bloque "Signal" en Dialogic
func _al_recibir_senal_dialogic(argumento: String):
	if argumento == "temblor":
		fuerza_temblor = 15.0 # Qué tan violento es el temblor (puedes subir o bajar esto)
		tiempo_temblor = 0.5  # Cuántos segundos dura temblando

# Aquí ocurre la magia de mover la cámara físicamente
func _process(delta: float):
	if tiempo_temblor > 0:
		tiempo_temblor -= delta
		# Mueve el lente de la cámara a posiciones locas
		camara.offset = Vector2(
			randf_range(-fuerza_temblor, fuerza_temblor), 
			randf_range(-fuerza_temblor, fuerza_temblor)
		)
	else:
		# Centra la cámara cuando termina el temblor
		camara.offset = Vector2.ZERO
	# FUNCIÓN REQUERIDA POR DIALOGIC PARA RETRATOS PERSONALIZADOS
