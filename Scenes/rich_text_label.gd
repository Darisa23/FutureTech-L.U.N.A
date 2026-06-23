extends RichTextLabel

@export var velocidad_letras: float = 0.03  # segundos entre cada letra
var texto_completo: String = ""

func mostrar_texto(nuevo_texto: String) -> void:
	texto_completo = nuevo_texto
	text = texto_completo
	visible_characters = 0
	
	var num_letras = texto_completo.length()
	for i in range(num_letras + 1):
		visible_characters = i
		await get_tree().create_timer(velocidad_letras).timeout

func saltar_animacion() -> void:
	visible_characters = -1  # muestra todo de inmediato
