extends Node2D

# Signal envoyé au jeu quand on clique
signal clic_mission(coords)

var coord_grille : Vector2i

# Cette fonction sert à stocker les coordonnées
func setup(coords: Vector2i):
	coord_grille = coords

# Cette fonction réagit au clic
func _on_button_pressed():
	print("✅ Clic détecté sur le bouton en : ", coord_grille)
	emit_signal("clic_mission", coord_grille)
