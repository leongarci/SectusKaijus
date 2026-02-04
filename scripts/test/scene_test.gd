extends Node2D

# --- VARIABLES ---

# Pour stocker le personnage sélectionné
var personnage_selectionne = null

# Compteur de temps
var heure_actuelle : int = 0

# Référence vers la scène de la carte (assure-toi que le fichier s'appelle bien ainsi)
var scene_carte = preload("res://scenes/characters/carte_perso.tscn")

# Lien vers l'interface
@onready var label_info = $UI/MessageInfo 
@onready var deck_container = $UI/DeckContainer

# Liste pour stocker les références trouvées
var personnages = []

# --- INITIALISATION ---

func _ready():
	# 1. RÉCUPÉRATION DE TES PERSONNAGES (Noms spécifiques)
	if has_node("Character"): personnages.append($Character)
	if has_node("Character2"): personnages.append($Character2)
	if has_node("Character3"): personnages.append($Character3)
	
	# 2. SETUP AUTOMATIQUE (Signaux + Cartes)
	for perso in personnages:
		# A. Connexion du signal pour savoir quand on clique sur le perso
		if perso.has_signal("demande_selection"):
			perso.demande_selection.connect(_on_selection_demandee)
		elif perso.has_signal("selection"):
			perso.selection.connect(_on_selection_demandee)
		
		# B. Création de la carte dans l'interface
		var nouvelle_carte = scene_carte.instantiate()
		deck_container.add_child(nouvelle_carte)
		nouvelle_carte.setup(perso) # On configure le visuel de la carte
		
		# C. Connexion du clic sur la CARTE vers la même fonction de sélection
		nouvelle_carte.carte_cliquee.connect(_on_selection_demandee)

	# 3. BOUTON AVANCER
	if has_node("UI/BoutonAvancer"): 
		$UI/BoutonAvancer.pressed.connect(_on_bouton_avancer_pressed)
	elif has_node("BoutonAvancer"):
		$BoutonAvancer.pressed.connect(_on_bouton_avancer_pressed)

	print("Journée commencée. Il est 0h.")
	label_info.text = "Journée commencée. Il est 0h."

# --- LOGIQUE DE SÉLECTION ---

func update_visuel_carte(perso, a_un_ordre: bool):
	# On cherche dans les enfants de DeckContainer
	for carte in deck_container.get_children():
		# Si cette carte appartient au perso qu'on cherche
		if carte.perso_reference == perso:
			carte.mettre_a_jour_visuel(a_un_ordre)

# Cette fonction est appelée par le clic sur la MAP ou sur la CARTE
func _on_selection_demandee(le_perso):
	personnage_selectionne = le_perso
	
	# Quand on sélectionne, on "réveille" la carte visuellement (elle n'est plus grise)
	update_visuel_carte(le_perso, false)
	
	# Mise à jour du texte
	label_info.text = "Où doit aller " + le_perso.nom_personnage + " ?"
	print("Sélection active : ", le_perso.nom_personnage)

# --- LOGIQUE D'ORDRE (CLIC MAP) ---

func _unhandled_input(event):
	# Si on clique avec le bouton gauche
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Et qu'on a déjà choisi un perso
		if personnage_selectionne != null:
			
			# Conversion position souris -> Grille
			var souris_pos = get_global_mouse_position()
			var coord_grid = Vector2i(souris_pos.x / 64, souris_pos.y / 64)
			
			# Envoi de l'ordre au script du personnage
			personnage_selectionne.programmer_deplacement(coord_grid)
			
			# On grise la carte pour dire "C'est bon, il a son ordre"
			update_visuel_carte(personnage_selectionne, true)
			
			# Feedback et désélection
			label_info.text = "Ordre donné à " + personnage_selectionne.nom_personnage + ". Sélectionnez un autre."
			personnage_selectionne = null

# --- RÉSOLUTION DU TOUR ---

func _on_bouton_avancer_pressed():
	heure_actuelle += 1
	label_info.text = "Heure : " + str(heure_actuelle) + "h. Cliquez sur un personnage."
	print("--- TOUR SUIVANT : Il est maintenant ", heure_actuelle, "h ---")
	
	# On déclenche le mouvement pour tout le monde
	for perso in personnages:
		perso.avancer()
		# On remet toutes les cartes en mode normal pour le nouveau tour
		update_visuel_carte(perso, false)
