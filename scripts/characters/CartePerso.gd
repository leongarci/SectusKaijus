extends Button

# --- SIGNAUX ---
signal carte_cliquee(le_perso)
signal demande_fiche(perso)

# --- VARIABLES ---
var perso_reference = null
var a_un_ordre_valide : bool = false
var est_selectionne : bool = false 

const LARGEUR_VOULUE = 120.0 
const COULEUR_NORMALE = Color.WHITE
const COULEUR_HOVER = Color(1.15, 1.15, 1.15, 1) # Un peu plus lumineux
const COULEUR_OCCUPE = Color(0.5, 0.5, 0.5, 1)   # Gris sombre
const COULEUR_DOREE = Color(1, 0.85, 0, 1)       # Or vif

func _ready():
	# 1. On s'assure que le bouton réagit à la souris
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 2. On enlève le style par défaut (fond gris moche)
	var style_vide = StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", style_vide)
	add_theme_stylebox_override("hover", style_vide)
	add_theme_stylebox_override("pressed", style_vide)
	add_theme_stylebox_override("focus", style_vide)
	
	# 3. On connecte le redimensionnement pour le pivot
	resized.connect(func(): pivot_offset = size / 2.0)
	
	# 4. Connexions manuelles des signaux (Sécurité absolue)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Force la mise à jour du pivot au démarrage
	pivot_offset = size / 2.0

# --- LE DESSIN DU CADRE (La solution infaillible) ---

func _draw():
	if est_selectionne and icon:
		var taille_image = icon.get_size()
		var taille_bouton = size
		
		# On calcule les ratios
		var ratio_image = taille_image.x / taille_image.y
		var ratio_bouton = taille_bouton.x / taille_bouton.y
		
		var rect_final = Rect2()
		
		# Logique de centrage "Keep Aspect"
		if ratio_bouton > ratio_image:
			# Le bouton est plus large -> On cale sur la hauteur
			var largeur_visuelle = taille_bouton.y * ratio_image
			var decalage_x = (taille_bouton.x - largeur_visuelle) / 2.0
			rect_final = Rect2(decalage_x, 0, largeur_visuelle, taille_bouton.y)
		else:
			# Le bouton est plus haut -> On cale sur la largeur
			var hauteur_visuelle = taille_bouton.x / ratio_image
			var decalage_y = (taille_bouton.y - hauteur_visuelle) / 2.0
			rect_final = Rect2(0, decalage_y, taille_bouton.x, hauteur_visuelle)
			
		# Dessin du cadre
		draw_rect(rect_final, COULEUR_DOREE, false, 4.0)

# --- CONFIGURATION ---

func setup(perso_a_lier):
	perso_reference = perso_a_lier
	
	if perso_a_lier.texture_carte != null:
		icon = perso_a_lier.texture_carte
		expand_icon = true 
		
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Calcul de la hauteur proportionnelle
		var s = icon.get_size()
		var ratio = s.y / s.x
		custom_minimum_size = Vector2(LARGEUR_VOULUE, LARGEUR_VOULUE * ratio)
		
		text = "" 
	else:
		text = perso_a_lier.nom_personnage
		custom_minimum_size = Vector2(LARGEUR_VOULUE, LARGEUR_VOULUE * 1.4)

	# On force le pivot au centre immédiatement
	pivot_offset = custom_minimum_size / 2.0
	modulate = COULEUR_NORMALE

# --- GESTION DES CLICS ---

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			anim_clic()
			carte_cliquee.emit(perso_reference)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			demande_fiche.emit(perso_reference)

# --- ANIMATIONS (HOVER & CLIC) ---

func _on_mouse_entered():
	if a_un_ordre_valide: return
	
	# Z-Index haut pour passer devant les autres cartes
	z_index = 10 
	modulate = COULEUR_HOVER
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15)

func _on_mouse_exited():
	if a_un_ordre_valide: return
	
	# Si on est sélectionné, on reste un peu surélevé (z=5)
	z_index = 5 if est_selectionne else 0
	modulate = COULEUR_NORMALE
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func anim_clic():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.05)

# --- ÉTATS (SÉLECTION & ORDRES) ---

func set_selection(active: bool):
	if est_selectionne != active:
		est_selectionne = active
		# Cette commande magique demande à Godot de relancer la fonction _draw()
		queue_redraw() 
	
	if active:
		z_index = 5
	else:
		z_index = 0
		
	# Si la souris n'est pas dessus, on remet la taille normale
	if not is_hovered():
		scale = Vector2(1, 1)

func mettre_a_jour_visuel(a_un_ordre: bool):
	a_un_ordre_valide = a_un_ordre
	
	# Si occupé : on désactive la sélection visuelle
	if a_un_ordre and est_selectionne:
		est_selectionne = false
		queue_redraw()
		
	if a_un_ordre:
		modulate = COULEUR_OCCUPE
		scale = Vector2(0.95, 0.95)
	else:
		modulate = COULEUR_NORMALE
		scale = Vector2(1, 1)
