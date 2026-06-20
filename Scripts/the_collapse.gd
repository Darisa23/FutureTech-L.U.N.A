extends Node

func _ready():
	Dialogic.timeline_ended.connect(_on_collapse_ended)
	Dialogic.start('colapso')

func _on_collapse_ended():
	Dialogic.timeline_ended.disconnect(_on_collapse_ended)
	get_tree().change_scene_to_file("res://Scenes/arc2/Arc2_Terminal.tscn")
