extends Node2D

var personnage_selectionne = null
var heure_actuelle : int = 0
var scene_carte = preload("res://scenes/characters/carte_perso.tscn")

# Glisse ta TileMapLayer ici dans l'inspecteur !
@export var tile_map : TileMapLayer 
@onready var label_info = $UI/MessageInfo 
@onready var deck_container = $UI/DeckContainer

var personnages = []

# --- A-STAR ---
var astar = AStar2D.new()
var map_coords_to_id = {} 
var id_counter = 0
var chemin_visuel_actuel : PackedVector2Array = []

func _ready():
	if tile_map == null:
		push_error("ERREUR : Tile Map non assignée !")
		return
	
	construire_graphe_astar()
	
	var noms_puants = ["Clovis", "Lilou", "Titouan", "Julien", "Karine"]
	for nom in noms_puants:
		if has_node(nom):
			var p = get_node(nom)
			personnages.append(p)
			
			# Initialisation position
			var local_pos = tile_map.to_local(p.global_position)
			var case_depart = tile_map.local_to_map(local_pos)
			var centre_hex = tile_map.to_global(tile_map.map_to_local(case_depart))
			
			p.initialiser_position(case_depart, centre_hex)
			
			if not p.is_connected("selection", _on_selection_demandee):
				p.selection.connect(_on_selection_demandee)
			
			var nouvelle_carte = scene_carte.instantiate()
			deck_container.add_child(nouvelle_carte)
			nouvelle_carte.setup(p) 
			nouvelle_carte.carte_cliquee.connect(_on_selection_demandee)

	if has_node("UI/BoutonAvancer"): 
		$UI/BoutonAvancer.pressed.connect(_on_bouton_avancer_pressed)
	
	label_info.text = "Journée commencée."
	
	await get_tree().process_frame
	for p in personnages:
		reorganiser_positions_sur_case(p.coord_actuelle)

func construire_graphe_astar():
	astar.clear()
	map_coords_to_id.clear()
	id_counter = 0
	var used_cells = tile_map.get_used_cells()
	
	for cell in used_cells:
		var id = id_counter
		map_coords_to_id[cell] = id
		id_counter += 1
		var pos_monde = tile_map.map_to_local(cell)
		astar.add_point(id, pos_monde)
	
	for cell in used_cells:
		var id_actuel = map_coords_to_id[cell]
		var voisins = tile_map.get_surrounding_cells(cell)
		for voisin in voisins:
			if map_coords_to_id.has(voisin):
				var id_voisin = map_coords_to_id[voisin]
				if not astar.are_points_connected(id_actuel, id_voisin):
					astar.connect_points(id_actuel, id_voisin)
	print("Graphe A* construit avec ", id_counter, " points.")

func _draw():
	if personnage_selectionne != null:
		var centre = tile_map.to_global(tile_map.map_to_local(personnage_selectionne.coord_actuelle))
		dessiner_hexagone(centre, Color(0, 0.2, 1, 0.5))
		
		if chemin_visuel_actuel.size() > 1:
			draw_polyline(chemin_visuel_actuel, Color(1, 1, 1, 0.8), 3.0)
			draw_circle(chemin_visuel_actuel[-1], 5.0, Color(1, 0, 0))

func dessiner_hexagone(centre: Vector2, couleur: Color):
	var taille = tile_map.tile_set.tile_size
	var rayon = taille.y * 0.48 
	var points = PackedVector2Array()
	for i in range(6):
		var angle_rad = deg_to_rad(60 * i - 30)
		points.append(Vector2(centre.x + rayon * cos(angle_rad), centre.y + rayon * sin(angle_rad)))
	draw_colored_polygon(points, couleur)
	points.append(points[0])
	draw_polyline(points, couleur.lightened(0.4), 2.0)


func _on_selection_demandee(le_perso):
	personnage_selectionne = le_perso
	chemin_visuel_actuel.clear()
	update_visuel_carte(le_perso, false)
	label_info.text = "Où envoyer " + le_perso.nom_personnage + " ?"
	queue_redraw()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		# --- DEBUG : Est-ce que le clic est détecté ? ---
		print("🖱️ SOURIS : Clic détecté à la position ", event.position)
		
		if personnage_selectionne != null:
			var souris_pos = get_global_mouse_position()
			var local_pos = tile_map.to_local(souris_pos)
			var coord_cible = tile_map.local_to_map(local_pos)
			
			print("🎯 TENTATIVE : Vers la case grille ", coord_cible)
			
			if map_coords_to_id.has(coord_cible):
				var coord_depart = personnage_selectionne.coord_actuelle
				var id_depart = map_coords_to_id[coord_depart]
				var id_arrivee = map_coords_to_id[coord_cible]
				var id_path = astar.get_id_path(id_depart, id_arrivee)
				
				if id_path.size() > 0:
					var chemin_grid : Array[Vector2i] = []
					chemin_visuel_actuel.clear()
					
					# On ajoute le départ pour le tracé visuel
					chemin_visuel_actuel.append(tile_map.to_global(tile_map.map_to_local(coord_depart)))
					
					for i in range(1, id_path.size()):
						var id = id_path[i]
						var pos_point = astar.get_point_position(id)
						var coord_hex = tile_map.local_to_map(pos_point)
						chemin_grid.append(coord_hex)
						chemin_visuel_actuel.append(tile_map.to_global(pos_point))
					
					var dest_world = tile_map.to_global(tile_map.map_to_local(coord_cible))
					
					# ENVOI DE L'ORDRE
					personnage_selectionne.programmer_itineraire(chemin_grid, dest_world)
					
					# Feedback
					var tours = ceil(float(chemin_grid.size()) / float(personnage_selectionne.vitesse))
					label_info.text = "Ordre validé ! (" + str(tours) + " tours)"
					update_visuel_carte(personnage_selectionne, true)
					
					personnage_selectionne = null
					queue_redraw()
				else:
					label_info.text = "Pas de chemin (Mur ou trop loin ?)"
					print("❌ Echec : AStar ne trouve pas de chemin.")
			else:
				# C'est souvent ici que ça échoue si on clique un peu à côté
				print("❌ Echec : La case ", coord_cible, " n'est pas connue du système A*.")

# --- LE CŒUR DU PROBLÈME ÉTAIT ICI ---
func _on_bouton_avancer_pressed():
	heure_actuelle += 1
	$Main/TimeManager.advance_hour()
	label_info.text = "Sélectionnez un membre"
	chemin_visuel_actuel.clear()
	queue_redraw()
	personnage_selectionne = null
	
	for perso in personnages:
		# 1. On met à jour la logique (coord_actuelle change)
		perso.avancer()
		
		# 2. On calcule la position PIXELS correspondante
		var pos_monde = tile_map.to_global(tile_map.map_to_local(perso.coord_actuelle))
		
		# 3. On déclenche l'animation visuelle (C'EST ÇA QUI MANQUAIT)
		perso.animer_deplacement(pos_monde)
		
		update_visuel_carte(perso, false)
	
	# Gestion des empilements après l'anim
	await get_tree().create_timer(0.35).timeout
	var cases_a_verifier = []
	for p in personnages:
		if not p.coord_actuelle in cases_a_verifier:
			cases_a_verifier.append(p.coord_actuelle)
	for case in cases_a_verifier:
		reorganiser_positions_sur_case(case)

func update_visuel_carte(perso, a_un_ordre: bool):
	for carte in deck_container.get_children():
		if carte.perso_reference == perso:
			carte.mettre_a_jour_visuel(a_un_ordre)

func reorganiser_positions_sur_case(case_grille: Vector2i):
	var persos_sur_place = []
	for p in personnages:
		if p.coord_actuelle == case_grille:
			persos_sur_place.append(p)
	
	var nombre = persos_sur_place.size()
	var centre_hex = tile_map.to_global(tile_map.map_to_local(case_grille))
	
	if nombre <= 1:
		if nombre == 1:
			# Recentre le perso unique au cas où
			var tween = create_tween()
			tween.tween_property(persos_sur_place[0], "global_position", centre_hex, 0.2)
		return

	var rayon = 25.0 
	var angle_step = (2 * PI) / nombre 
	for i in range(nombre):
		var angle = i * angle_step - (PI / 2) 
		var offset = Vector2(cos(angle), sin(angle)) * rayon
		var tween = create_tween()
		tween.tween_property(persos_sur_place[i], "global_position", centre_hex + offset, 0.3)
