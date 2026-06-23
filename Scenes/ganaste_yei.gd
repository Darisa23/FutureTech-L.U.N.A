extends Node2D

func _ready() -> void:
	$RichTextLabel.mostrar_texto("Certificado de guardiana neuronal")
	$RichTextLabel2.mostrar_texto(" [center]Felicidades haz logrado rescatar a LUNA[/center]")
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
