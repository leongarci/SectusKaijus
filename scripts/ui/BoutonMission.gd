extends Node2D

signal clic_mission(coords)

var coord_grille : Vector2i

func _ready():
	# Option A : Grossir tout le bouton (le texte peut devenir un peu flou)
	# scale = Vector2(2.0, 2.0) 
	
	# Option B (La meilleure) : Augmenter la taille de la police uniquement (texte net)
	# 32 est la taille en pixels (tu peux mettre 40, 50, etc.)
	$Button.add_theme_font_size_override("font_size", 80)
	
	# Si tu veux aussi changer la couleur du texte en rouge par exemple :
	# $Button.add_theme_color_override("font_color", Color.RED)

func setup(coords: Vector2i):
	coord_grille = coords

func _on_button_pressed() -> void:
	print("🖱️ CLIC DÉTECTÉ SUR LE BOUTON !")
	emit_signal("clic_mission", coord_grille)
