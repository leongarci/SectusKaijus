extends Button

signal carte_cliquee(le_perso)
signal demande_fiche(perso)

var perso_reference = null
var a_un_ordre_valide : bool = false

# Tu peux changer cette valeur pour grossir/rétrécir tes cartes
const LARGEUR_VOULUE = 120.0 


func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Comportement actuel (Sélection)
			carte_cliquee.emit(perso_reference)
			
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# NOUVEAU : Demande d'affichage de la fiche
			# On va utiliser un signal ou appeler une méthode parente
			# Le plus simple ici est d'émettre le signal aussi, mais de gérer la différence dans scene_test
			# Mais pour faire propre, ajoutons un signal dédié :
			emit_signal("demande_fiche", perso_reference)

func setup(perso_a_lier):
	perso_reference = perso_a_lier
	
	if perso_a_lier.texture_carte != null:
		# 1. ASSIGNATION
		icon = perso_a_lier.texture_carte
		
		# 2. CALCUL DES PROPORTIONS (Règle de trois)
		var taille_reelle = icon.get_size()
		# On calcule le ratio (Hauteur / Largeur)
		var ratio = taille_reelle.y / taille_reelle.x
		
		# On applique ce ratio à notre largeur voulue (120px)
		var hauteur_calculee = LARGEUR_VOULUE * ratio
		
		# 3. APPLICATION DE LA TAILLE
		custom_minimum_size = Vector2(LARGEUR_VOULUE, hauteur_calculee)
		expand_icon = true # AUTORISE le redimensionnement de l'image
		
		# 4. SUPPRESSION DU CADRE (Style vide)
		var style_vide = StyleBoxEmpty.new()
		add_theme_stylebox_override("normal", style_vide)
		add_theme_stylebox_override("hover", style_vide)
		add_theme_stylebox_override("pressed", style_vide)
		add_theme_stylebox_override("focus", style_vide)
		
		text = "" 
		
		# Couleur de base un peu "éteinte" pour que le hover ressorte bien
		modulate = Color(0.85, 0.85, 0.85, 1)

	else:
		# Fallback sans image
		text = perso_a_lier.nom_personnage
		custom_minimum_size = Vector2(LARGEUR_VOULUE, LARGEUR_VOULUE * 1.4)

# --- GESTION DE LA LUMIÈRE (HOVER) ---

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	# Si le perso est disponible, on l'éclaire (Blanc pur voir un peu brillant)
	if not a_un_ordre_valide:
		modulate = Color(1.1, 1.1, 1.1, 1)

func _on_mouse_exited():
	# Retour à la couleur de base
	if not a_un_ordre_valide:
		modulate = Color(0.85, 0.85, 0.85, 1)

# --- CLIC ET ÉTAT ---

func _pressed():
	carte_cliquee.emit(perso_reference)

func mettre_a_jour_visuel(a_un_ordre: bool):
	a_un_ordre_valide = a_un_ordre
	
	if a_un_ordre:
		# Si le perso a fini son tour : Gris foncé
		modulate = Color(0.4, 0.4, 0.4, 1)
	else:
		# Si le perso redevient dispo : Couleur normale
		modulate = Color(0.85, 0.85, 0.85, 1)
