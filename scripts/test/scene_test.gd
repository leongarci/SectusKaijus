extends Node2D

var personnage_selectionne = null
var heure_actuelle : int = 0
var scene_carte = preload("res://scenes/characters/carte_perso.tscn")

@export var tile_map : TileMapLayer 

@onready var label_info = $UI/MessageInfo 
@onready var deck_container = $UI/DeckContainer

var personnages = []

func _ready():
	if tile_map == null:
		push_error("ERREUR CRITIQUE : Tile Map non assignée dans SceneTest !")
		return

	# Vérifie bien que les noms ici sont EXACTEMENT les mêmes que tes nœuds dans la scène
	var noms_puants = ["Clovis", "Lilou", "Titouan", "Julien", "Karine"]
	
	for nom in noms_puants:
		if has_node(nom):
			var p = get_node(nom)
			personnages.append(p)
			
			# --- SNAP AUTOMATIQUE ---
			var local_pos_pour_map = tile_map.to_local(p.global_position)
			var case_depart = tile_map.local_to_map(local_pos_pour_map)
			var centre_hex_local = tile_map.map_to_local(case_depart)
			var centre_hex_global = tile_map.to_global(centre_hex_local)
			
			# On force le placement
			p.initialiser_position(case_depart, centre_hex_global)
			# ------------------------
			
			if p.has_signal("selection"):
				p.selection.connect(_on_selection_demandee)
			
			var nouvelle_carte = scene_carte.instantiate()
			deck_container.add_child(nouvelle_carte)
			nouvelle_carte.setup(p) 
			nouvelle_carte.carte_cliquee.connect(_on_selection_demandee)
		else:
			# Si tu vois ce message dans la sortie, c'est que le nom est mal écrit
			print("ATTENTION : Le personnage nommé '" + nom + "' est introuvable dans la scène !")

	if has_node("UI/BoutonAvancer"): 
		$UI/BoutonAvancer.pressed.connect(_on_bouton_avancer_pressed)

	label_info.text = "Journée commencée. Il est 0h."

func update_visuel_carte(perso, a_un_ordre: bool):
	for carte in deck_container.get_children():
		if carte.perso_reference == perso:
			carte.mettre_a_jour_visuel(a_un_ordre)

func _on_selection_demandee(le_perso):
	personnage_selectionne = le_perso
	update_visuel_carte(le_perso, false)
	label_info.text = "Où doit aller " + le_perso.nom_personnage + " ?"

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if personnage_selectionne != null:
			var souris_pos = get_global_mouse_position()
			var local_pos = tile_map.to_local(souris_pos)
			var coord_grid = tile_map.local_to_map(local_pos)
			
			if tile_map.get_cell_source_id(coord_grid) != -1:
				var destination_local = tile_map.map_to_local(coord_grid)
				var destination_world_pos = tile_map.to_global(destination_local)
				
				personnage_selectionne.programmer_deplacement(coord_grid, destination_world_pos)
				
				update_visuel_carte(personnage_selectionne, true)
				label_info.text = "Ordre donné à " + personnage_selectionne.nom_personnage
				personnage_selectionne = null
			else:
				label_info.text = "Zone invalide"

func _on_bouton_avancer_pressed():
	heure_actuelle += 1
	label_info.text = "Heure : " + str(heure_actuelle) + "h."
	for perso in personnages:
		perso.avancer()
		update_visuel_carte(perso, false)
