extends Node2D

# Signal pour dire au Main "Eh, on a cliqué sur moi !"
signal clic_mission(coords)

var coord_grille : Vector2i

func setup(coords: Vector2i):
	coord_grille = coords




func _on_button_pressed() -> void:
	emit_signal("clic_mission", coord_grille)
