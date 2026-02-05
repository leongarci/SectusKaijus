extends Node2D

var personnage_selectionne = null
var heure_actuelle : int = 0
var scene_carte = preload("res://scenes/characters/carte_perso.tscn")

# Glisse ta TileMapLayer ici dans l'inspecteur !
@export var tile_map : TileMapLayer 
@onready var label_info = $UI/MessageInfo 
@onready var deck_container = $UI/DeckContainer
@onready var bouton_mission = %BoutonMission


var personnages = []

# --- A-STAR ---
var astar = AStar2D.new()
var map_coords_to_id = {} 
var id_counter = 0
var chemin_visuel_actuel : PackedVector2Array = []
var mission_en_attente = null
var cultistes_sur_le_lieu = []

func _ready():
	if tile_map == null:
		push_error("ERREUR : Tile Map non assignée !")
		return
	construire_graphe_astar()
	bouton_mission.pressed.connect(_on_bouton_mission_pressed)
	%PopupMission.confirmed.connect(_on_popup_mission_confirmed)
	bouton_mission.hide() # Caché au départ
	if not %ListeChoixMissions.item_selected.is_connected(_on_mission_list_item_selected):
		%ListeChoixMissions.item_selected.connect(_on_mission_list_item_selected)
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



func _on_bouton_mission_pressed():
	print("Clic sur le bouton Lancer Mission détecté !")
	print("Personnage_selectionne : ",personnage_selectionne)
	if personnage_selectionne:
		var lieu = get_nom_lieu(personnage_selectionne.coord_actuelle)
		# On réutilise ta fonction de popup existante
		print("Lieu :",lieu)
		preparer_popup_mission(lieu, personnage_selectionne.coord_actuelle)
		
func get_nom_lieu(coords: Vector2i) -> String:
	var data = tile_map.get_cell_tile_data(coords)
	if data:
		return data.get_custom_data("nom_lieu")
	return ""
	
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
	# AJOUT : Vérification si le personnage est occupé
	if le_perso.est_occupe():
		label_info.text = le_perso.nom_personnage + " est en mission (" + str(le_perso.temps_mission_restant) + "h restantes)."
		# On désélectionne le personnage actuel s'il y en avait un
		personnage_selectionne = null
		chemin_visuel_actuel.clear()
		queue_redraw()
		return # On arrête la fonction ici, le perso ne sera pas sélectionné
		
	personnage_selectionne = le_perso
	chemin_visuel_actuel.clear()
	update_visuel_carte(le_perso, false)
	label_info.text = "Où envoyer " + le_perso.nom_personnage + " ?"
	actualiser_visibilite_bouton_mission(le_perso)
	queue_redraw()

func actualiser_visibilite_bouton_mission(perso):
	# On ne montre le bouton que si le perso est immobile et sur un lieu valide
	if not perso.est_occupe() and perso.chemin_a_parcourir.size() == 0:
		var lieu = get_nom_lieu(perso.coord_actuelle)
		if lieu != "" and est_mission_disponible_ici(lieu):
			bouton_mission.show()
			return
	bouton_mission.hide()

func est_mission_disponible_ici(lieu_nom: String) -> bool:
	for m in $Main/MissionManager.missions:
		# La mission n'est disponible que si son status est 0
		if m["status"] == 0 and lieu_nom in m["places"]:
			if is_hour_in_range(heure_actuelle, m["hours"]):
				return true
	return false

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		# --- DEBUG : Est-ce que le clic est détecté ? ---
		print("🖱️ SOURIS : Clic détecté à la position ", event.position)
		
		if personnage_selectionne != null:
			var souris_pos = get_global_mouse_position()
			var local_pos = tile_map.to_local(souris_pos)
			var coord_cible = tile_map.local_to_map(local_pos)
			
			
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



func _actualiser_affichage_chances():
	var participants = []
	var vbox = %PopupMission.get_node("VBoxContainer")
	
	# On regarde qui est coché
	for child in vbox.get_children():
		if child is CheckBox and child.button_pressed:
			participants.append(child.get_meta("perso"))
	
	# On demande au MissionManager de calculer la probabilité
	var proba = $Main/MissionManager.calculer_probabilite(mission_en_attente, participants)
	
	# On met à jour le texte (ex: "Chances de succès : 65%")
	var label = vbox.get_node("LabelChances")
	label.text = "Chances de succès : " + str(snapped(proba * 100, 1)) + "%"

var missions_locales_dispo = []

func preparer_popup_mission(lieu_nom: String, coords: Vector2i):
	print("Recherche de missions pour : ", lieu_nom)
	
	# 1. On nettoie les anciennes données
	missions_locales_dispo.clear()
	var liste = $UI/PopupMission/VBoxContainer.get_node("ListeChoixMissions")
	liste.clear()
	_nettoyer_checkboxes_participants()
	$UI/PopupMission/VBoxContainer/LabelChances.text = "Sélectionnez une mission..."
	%PopupMission.get_ok_button().disabled = true # On désactive le bouton tant qu'on a pas choisi
	
	# 2. On cherche TOUTES les missions disponibles (pas de 'break' après la première)
	for m in $Main/MissionManager.missions:
		if m["status"] == 0 and lieu_nom in m["places"]:
			# Vérification horaire
			if is_hour_in_range(heure_actuelle, m["hours"]):
				missions_locales_dispo.append(m)
	
	if missions_locales_dispo.size() == 0:
		print("❌ Aucune mission disponible ici et maintenant.")
		return

	# 3. On remplit la liste visuelle
	for m in missions_locales_dispo:
		%ListeChoixMissions.add_item(m["title"] + " (" + str(m["duration"]) + "h)")
	
	# 4. On stocke les coordonnées pour plus tard (pour filtrer les cultistes)
	# On peut les stocker dans une variable de script ou en méta sur la popup
	%PopupMission.set_meta("coords_actuelles", coords)

	%PopupMission.title = "Missions à : " + lieu_nom
	%PopupMission.popup_centered()
	

func _on_mission_list_item_selected(index):
	# On récupère la mission correspondant à l'index cliqué
	mission_en_attente = missions_locales_dispo[index]
	
	# Mise à jour UI
	%PopupMission.get_ok_button().disabled = false
	$Main/CanvasLayer/UI_mission/MissionPanel/MissionBox/MissionTitle.text = mission_en_attente["title"]
	$Main/CanvasLayer/UI_mission/MissionPanel/MissionBox/MissionHint.text = "Difficulté : " + str(mission_en_attente.get("diff", 0.5) * 100) + "%"
	
	# On affiche les cultistes
	var coords = %PopupMission.get_meta("coords_actuelles")
	_generer_choix_cultistes(coords)
	_actualiser_affichage_chances()

func _generer_choix_cultistes(coords: Vector2i):
	_nettoyer_checkboxes_participants()
	
	cultistes_sur_le_lieu.clear()
	var vbox = %PopupMission.get_node("VBoxContainer")
	
	# On cherche les cultistes sur la case ET qui ne sont PAS occupés
	for p in personnages:
		if p.coord_actuelle == coords and not p.est_occupe():
			cultistes_sur_le_lieu.append(p)
			
	if cultistes_sur_le_lieu.is_empty():
		var label = Label.new()
		label.text = "Aucun cultiste disponible ici."
		vbox.add_child(label)
		%PopupMission.get_ok_button().disabled = true
	else:
		for c in cultistes_sur_le_lieu:
			var check = CheckBox.new()
			check.text = c.nom_personnage
			check.set_meta("perso", c)
			check.toggled.connect(func(_toggled): _actualiser_affichage_chances())
			vbox.add_child(check)

func _nettoyer_checkboxes_participants():
	var vbox = %PopupMission.get_node("VBoxContainer")
	for child in vbox.get_children():
		if child is CheckBox or (child is Label and child.name != "LabelChances"):
			pass 
	for child in vbox.get_children():
		if child is CheckBox:
			child.queue_free()

func _on_popup_mission_confirmed():
	print("📢 Confirmation reçue ! Traitement de la mission...") # Debug
	var participants = []
	var vbox = %PopupMission.get_node("VBoxContainer")
	for child in vbox.get_children():
		if child is CheckBox and child.button_pressed:
			participants.append(child.get_meta("perso"))
	
	if participants.size() > 0:
		# 1. Calcul immédiat
		var resultat = $Main/MissionManager.calculer_resultat_final(mission_en_attente, participants)
		
		# 2. Verrouillage de la mission
		mission_en_attente["status"] = 1 # "En cours"
		
		# 3. Verrouillage des cultistes
		for p in participants:
			p.temps_mission_restant = mission_en_attente["duration"]
			p.mission_actuelle_data = mission_en_attente
			p.resultat_secret = resultat
			# On met à jour le visuel de leur carte (pour montrer qu'ils travaillent)
			update_visuel_carte(p, false)
			
		label_info.text = "Mission '" + mission_en_attente["title"] + "' lancée !"
		bouton_mission.hide()
		personnage_selectionne = null # On désélectionne pour éviter les bugs

# Helper pour gérer le passage de minuit dans les horaires
func is_hour_in_range(h, range_arr):
	var start = range_arr[0]
	var end = range_arr[1]
	if start <= end:
		return h >= start and h < end
	else: # Cas où la mission traverse minuit (ex: 22h à 04h)
		return h >= start or h < end

func _on_bouton_avancer_pressed():
	# 1. Mise à jour du temps
	$Main/TimeManager.advance_hour()
	heure_actuelle = $Main/TimeManager.hour 
	
	# 2. Nettoyage de l'interface (On cache le bouton de mission ici !)
	label_info.text = "Sélectionnez un membre"
	bouton_mission.hide() 
	chemin_visuel_actuel.clear()
	queue_redraw()
	personnage_selectionne = null
	
	# 3. Mouvement des personnages
	for perso in personnages:
		var fini_maintenant = (perso.temps_mission_restant == 1)
		perso.avancer()
		
		if fini_maintenant and perso.mission_actuelle_data != null:
			terminer_et_afficher_mission(perso)
		var pos_monde = tile_map.to_global(tile_map.map_to_local(perso.coord_actuelle))
		perso.animer_deplacement(pos_monde)
		update_visuel_carte(perso, false)
		
	
	# 4. Gestion des empilements
	await get_tree().create_timer(0.35).timeout
	var cases_a_verifier = []
	for p in personnages:
		if not p.coord_actuelle in cases_a_verifier:
			cases_a_verifier.append(p.coord_actuelle)
	for case in cases_a_verifier:
		reorganiser_positions_sur_case(case)

func terminer_et_afficher_mission(perso):
	var m = perso.mission_actuelle_data
	var res = perso.resultat_secret
	
	print("🔔 Fin de mission pour ", perso.nom_personnage)

	# 1. On change le statut final dans le manager
	m["status"] = 2 if res.success else 3
	
	# 2. On affiche la popup
	var popup_res = %PopupResultat
	popup_res.title = "Rapport : " + m["title"]
	popup_res.dialog_text = res.msg
	popup_res.popup_centered()
	
	# 3. Nettoyage du perso
	perso.mission_actuelle_data = null
	perso.resultat_secret = {}
	update_visuel_carte(perso, false)

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
		var tween = create_tween()
		tween.tween_property(persos_sur_place[i], "global_position", centre_hex + offset, 0.3)
