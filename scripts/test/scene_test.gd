extends Node2D

# --- VARIABLES ---

var personnage_selectionne = null
var heure_actuelle : int = 0

# Référence vers la scène de la carte
var scene_carte = preload("res://scenes/characters/carte_perso.tscn")

@onready var label_info = $UI/MessageInfo 
@onready var deck_container = $UI/DeckContainer

# Liste pour stocker les instances des personnages
var personnages = []

# --- INITIALISATION ---

func _ready():
	# 1. RÉCUPÉRATION DES 5 PERSONNAGES
	# On définit la liste des noms que tu as donnés
	var noms_puants = ["Clovis", "Lilou", "Titouan", "Julien", "Karine"]
	
	for nom in noms_puants:
		if has_node(nom):
			var p = get_node(nom)
			personnages.append(p)
			
			# A. Connexion des signaux de sélection
			if p.has_signal("selection"):
				p.selection.connect(_on_selection_demandee)
			elif p.has_signal("demande_selection"):
				p.demande_selection.connect(_on_selection_demandee)
			
			# B. Création de la carte
			var nouvelle_carte = scene_carte.instantiate()
			deck_container.add_child(nouvelle_carte)
			nouvelle_carte.setup(p) # On passe le perso pour configurer l'image
			
			# C. Connexion du clic carte
			nouvelle_carte.carte_cliquee.connect(_on_selection_demandee)

	# 2. BOUTON AVANCER
	if has_node("UI/BoutonAvancer"): 
		$UI/BoutonAvancer.pressed.connect(_on_bouton_avancer_pressed)

	label_info.text = "Journée commencée. Il est 0h."

# --- LOGIQUE DE SÉLECTION ---

func update_visuel_carte(perso, a_un_ordre: bool):
	for carte in deck_container.get_children():
		if carte.perso_reference == perso:
			carte.mettre_a_jour_visuel(a_un_ordre)

func _on_selection_demandee(le_perso):
	personnage_selectionne = le_perso
	update_visuel_carte(le_perso, false)
	label_info.text = "Où doit aller " + le_perso.nom_personnage + " ?"

# --- LOGIQUE D'ORDRE ---

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if personnage_selectionne != null:
			var souris_pos = get_global_mouse_position()
			var coord_grid = Vector2i(souris_pos.x / 64, souris_pos.y / 64)
			
			personnage_selectionne.programmer_deplacement(coord_grid)
			update_visuel_carte(personnage_selectionne, true)
			
			label_info.text = "Ordre donné à " + personnage_selectionne.nom_personnage
			personnage_selectionne = null

# --- RÉSOLUTION DU TOUR ---

func _on_bouton_avancer_pressed():
	heure_actuelle += 1
	label_info.text = "Heure : " + str(heure_actuelle) + "h. Cliquez sur un personnage."
	for perso in personnages:
		perso.avancer()
		update_visuel_carte(perso, false)
