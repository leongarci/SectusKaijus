extends Button

# Signal envoyé au "Chef d'orchestre" quand on clique la carte
signal carte_cliquee(le_perso)

var perso_reference = null # Lien vers le vrai bonhomme sur la map

func setup(perso_a_lier):
	perso_reference = perso_a_lier
	# Affiche le nom sur le bouton
	text = perso_a_lier.nom_personnage
	
	# --- STYLE NORMAL ---
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = perso_a_lier.couleur_point
	style_normal.bg_color.a = 0.8 # Un peu transparent
	
	# --- STYLE HOVER (Survol) ---
	# On crée une copie plus claire pour le survol
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = perso_a_lier.couleur_point.lightened(0.2) # +20% de luminosité
	style_hover.bg_color.a = 1.0 # Pleine opacité au survol
	
	# --- STYLE PRESSED (Clic) ---
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = perso_a_lier.couleur_point.darkened(0.2)
	
	# Application des styles
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)

func _pressed():
	# Quand on clique le bouton, on dit au jeu : "Sélectionne ce perso !"
	carte_cliquee.emit(perso_reference)

func mettre_a_jour_visuel(a_un_ordre: bool):
	if a_un_ordre:
		# On "grise" et on assombrit pour montrer que c'est fait
		# On ne change PAS le texte pour éviter que le bouton change de taille
		modulate = Color(0.5, 0.5, 0.5, 0.7)
	else:
		# On remet à la normale (Blanc éclatant = couleur d'origine)
		modulate = Color(1, 1, 1, 1)
