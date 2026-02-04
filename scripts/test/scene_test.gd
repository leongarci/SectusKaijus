extends Node2D

var personnage_selectionne = null
var heure_actuelle : int = 0
var scene_carte = preload("res://scenes/characters/carte_perso.tscn")

@export var tile_map : TileMapLayer 
@onready var label_info = $UI/MessageInfo 
@onready var deck_container = $UI/DeckContainer

var personnages = []

# --- A-STAR (PATHFINDING) ---
var astar = AStar2D.new()
# Dictionnaire pour convertir "Coordonnée Hex" <-> "ID unique entier" (nécessaire pour AStar)
var map_coords_to_id = {} 
var id_counter = 0

# Pour le dessin du chemin
var chemin_visuel_actuel : PackedVector2Array = []

func _ready():
	if tile_map == null:
		push_error("ERREUR : Tile Map non assignée !")
		return
	z_index = 10 

	# 1. INITIALISER LE GRAPH A*
	construire_graphe_astar()

	# 2. INITIALISATION PERSONNAGES
	var noms_puants = ["Clovis", "Lilou", "Titouan", "Julien", "Karine"]
	for nom in noms_puants:
		if has_node(nom):
			var p = get_node(nom)
			personnages.append(p)
			
			var local_pos = tile_map.to_local(p.global_position)
			var case_depart = tile_map.local_to_map(local_pos)
			var centre_hex = tile_map.to_global(tile_map.map_to_local(case_depart))
			
			p.initialiser_position(case_depart, centre_hex)
			
			if p.has_signal("selection"):
				p.selection.connect(_on_selection_demandee)
			
			var nouvelle_carte = scene_carte.instantiate()
			deck_container.add_child(nouvelle_carte)
			nouvelle_carte.setup(p) 
			nouvelle_carte.carte_cliquee.connect(_on_selection_demandee)

	if has_node("UI/BoutonAvancer"): 
		$UI/BoutonAvancer.pressed.connect(_on_bouton_avancer_pressed)
	label_info.text = "Journée commencée. Il est 0h."
	
	await get_tree().process_frame
	for p in personnages:
		reorganiser_positions_sur_case(p.coord_actuelle)


# --- CONSTRUCTION DU GRAPHE DE CHEMIN ---
func construire_graphe_astar():
	astar.clear()
	map_coords_to_id.clear()
	id_counter = 0
	
	# A. On récupère TOUTES les cases utilisées dans la map
	var used_cells = tile_map.get_used_cells()
	
	# B. On ajoute les points au graphe
	for cell in used_cells:
		# On ne prend que les cases "sol" (id != -1 est déjà garanti par get_used_cells, 
		# mais si tu as des murs avec un autre ID, filtre-les ici)
		
		# On crée un ID unique pour cette coordonnée
		var id = id_counter
		map_coords_to_id[cell] = id
		id_counter += 1
		
		# On ajoute le point à AStar (ID, Position Monde pour l'heuristique de distance)
		var pos_monde = tile_map.map_to_local(cell)
		astar.add_point(id, pos_monde)
	
	# C. On connecte les voisins
	for cell in used_cells:
		var id_actuel = map_coords_to_id[cell]
		var voisins = tile_map.get_surrounding_cells(cell)
		
		for voisin in voisins:
			# Si le voisin existe dans notre graphe (donc c'est une case valide)
			if map_coords_to_id.has(voisin):
				var id_voisin = map_coords_to_id[voisin]
				# On connecte (bidirectionnel par défaut)
				if not astar.are_points_connected(id_actuel, id_voisin):
					astar.connect_points(id_actuel, id_voisin)
	
	print("Graphe A* construit avec ", id_counter, " points.")


# --- DESSIN (DEBUG + CHEMIN) ---
func _draw():
	if personnage_selectionne != null:
		# Case actuelle
		var centre = tile_map.to_global(tile_map.map_to_local(personnage_selectionne.coord_actuelle))
		dessiner_hexagone(centre, Color(0, 0.2, 1, 0.5))
		
		# DESSIN DU CHEMIN PRÉVU (Ligne blanche)
		if chemin_visuel_actuel.size() > 1:
			draw_polyline(chemin_visuel_actuel, Color(1, 1, 1, 0.8), 3.0)
			# Petit point rouge à la fin
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
	chemin_visuel_actuel.clear() # On efface l'ancien tracé
	update_visuel_carte(le_perso, false)
	label_info.text = "Où envoyer " + le_perso.nom_personnage + " ?"
	queue_redraw()


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if personnage_selectionne != null:
			var souris_pos = get_global_mouse_position()
			var local_pos = tile_map.to_local(souris_pos)
			var coord_cible = tile_map.local_to_map(local_pos)
			
			# EST-CE UNE CASE VALIDE ? (Connue par AStar)
			if map_coords_to_id.has(coord_cible):
				var coord_depart = personnage_selectionne.coord_actuelle
				
				# CALCUL DU CHEMIN A*
				var id_depart = map_coords_to_id[coord_depart]
				var id_arrivee = map_coords_to_id[coord_cible]
				
				# get_id_path renvoie la liste des IDs (longue liste d'entiers)
				var id_path = astar.get_id_path(id_depart, id_arrivee)
				
				if id_path.size() > 0:
					# On convertit les IDs en Vector2i pour le perso
					# On enlève le premier point (car c'est la case où on est déjà)
					var chemin_grid : Array[Vector2i] = []
					
					# Pour le dessin
					chemin_visuel_actuel.clear()
					chemin_visuel_actuel.append(tile_map.to_global(tile_map.map_to_local(coord_depart)))
					
					# On commence à 1 pour ignorer la case de départ
					for i in range(1, id_path.size()):
						var id = id_path[i]
						# Astuce inversée : On récupère la pos depuis Astar pour éviter de parcourir le dico à l'envers
						# Mais le mieux est de stocker l'inverse. 
						# Ici on va utiliser local_to_map sur la pos du point Astar par simplicité
						var pos_point = astar.get_point_position(id) # C'est en local pixels selon le setup
						# Attends, dans setup j'ai mis map_to_local, donc c'est du pixel local TileMapLayer
						
						var coord_hex = tile_map.local_to_map(pos_point)
						chemin_grid.append(coord_hex)
						
						# Pour le visuel global
						chemin_visuel_actuel.append(tile_map.to_global(pos_point))
					
					# ENVOI AU PERSONNAGE
					var destination_finale_world = tile_map.to_global(tile_map.map_to_local(coord_cible))
					personnage_selectionne.programmer_itineraire(chemin_grid, destination_finale_world)
					
					# FEEDBACK
					var tours_estimes = ceil(float(chemin_grid.size()) / float(personnage_selectionne.vitesse))
					label_info.text = "Chemin trouvé ! Arrivée dans " + str(tours_estimes) + " tours."
					update_visuel_carte(personnage_selectionne, true)
					
					personnage_selectionne = null # Désélection après ordre
					queue_redraw()
				else:
					label_info.text = "Pas de chemin possible vers là."
			else:
				label_info.text = "Case inaccessible ou hors carte."


func _on_bouton_avancer_pressed():
	heure_actuelle += 1
	label_info.text = "Heure : " + str(heure_actuelle) + "h."
	chemin_visuel_actuel.clear()
	queue_redraw()
	personnage_selectionne = null
	
	for perso in personnages:
		perso.avancer()
		update_visuel_carte(perso, false)
	
	await get_tree().create_timer(0.05).timeout
	
	var cases_a_verifier = []
	for p in personnages:
		if not p.coord_actuelle in cases_a_verifier:
			cases_a_verifier.append(p.coord_actuelle)
	
	for case in cases_a_verifier:
		reorganiser_positions_sur_case(case)

# Fonctions visuelles inchangées...
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
			var tween = create_tween()
			tween.tween_property(persos_sur_place[0], "global_position", centre_hex, 0.2)
		return

	var rayon = 25.0 
	var angle_step = (2 * PI) / nombre 
	
	for i in range(nombre):
		var angle = i * angle_step - (PI / 2) 
		var offset = Vector2(cos(angle), sin(angle)) * rayon
		var nouvelle_pos = centre_hex + offset
		
		var tween = create_tween()
		tween.tween_property(persos_sur_place[i], "global_position", nouvelle_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
