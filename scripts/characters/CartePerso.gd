extends Button

# Signal envoyé au "Chef d'orchestre" quand on clique la carte
signal carte_cliquee(le_perso)

var perso_reference = null # Lien vers le vrai bonhomme sur la map

func setup(perso_a_lier):
	perso_reference = perso_a_lier
	# Affiche le nom sur le bouton
	text = perso_a_lier.nom_personnage
	
	if perso_a_lier.texture_carte != null:
		# Oui ! On l'affiche
		icon = perso_a_lier.texture_carte
		
		# --- Réglages pour que l'image rentre bien dans le bouton ---
		expand_icon = true      # Autorise l'image à être redimensionnée
		ignore_texture_size = true # Force l'image à prendre la taille du bouton
		
		# Centrer l'image
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# On cache le texte si tu veux juste voir l'image
		text = "" 
		
		# On garde une couleur blanche neutre pour bien voir l'image
		self.modulate = Color(1, 1, 1, 1)
		
	else:
		# 2. PAS D'IMAGE ? (Sécurité)
		# On garde l'ancien système avec le nom et la couleur
		text = perso_a_lier.nom_personnage
		var style = StyleBoxFlat.new()
		style.bg_color = perso_a_lier.couleur_point
		add_theme_stylebox_override("normal", style)
	
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
	carte_cliquee.emit(perso_reference)

func mettre_a_jour_visuel(a_un_ordre: bool):
	if a_un_ordre:
		# On assombrit l'image (gris foncé) pour dire "C'est fait"
		modulate = Color(0.4, 0.4, 0.4, 1) 
	else:
		# On remet l'image en pleine lumière
		modulate = Color(1, 1, 1, 1)
