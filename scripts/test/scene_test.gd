extends Node2D

# --- PRÉCHARGEMENTS ---
var scene_carte = preload("res://scenes/characters/carte_perso.tscn")
var scene_transition_jour = preload("res://scenes/ui/DayTransition.tscn")

# --- VARIABLES ET NOEUDS ---
@export var tile_map : TileMapLayer

@onready var label_info = $UI/MessageInfo
@onready var deck_container = $UI/DeckContainer
@onready var bouton_mission = %BoutonMission

var personnage_selectionne = null
var heure_actuelle : int = 0
var nb_echecs_jour : int = 0
var personnages = []

# --- NAVIGATION A-STAR ---
var astar = AStar2D.new()
var map_coords_to_id = {}
var id_counter = 0
var chemin_visuel_actuel : PackedVector2Array = []

# --- GESTION MISSIONS ---
var mission_en_attente = null
var missions_locales_dispo = []
var cultistes_sur_le_lieu = []

# ==========================================
# INITIALISATION
# ==========================================

func _ready():
	if tile_map == null:
		push_error("ERREUR : Tile Map non assignée dans l'inspecteur !")
		return
	
	construire_graphe_astar()
	
	# Connexions sécurisées
	if not bouton_mission.pressed.is_connected(_on_bouton_mission_pressed):
		bouton_mission.pressed.connect(_on_bouton_mission_pressed)
		
	if not %PopupMission.confirmed.is_connected(_on_popup_mission_confirmed):
		%PopupMission.confirmed.connect(_on_popup_mission_confirmed)
		
	if not %ListeChoixMissions.item_selected.is_connected(_on_mission_list_item_selected):
		%ListeChoixMissions.item_selected.connect(_on_mission_list_item_selected)
	
	if has_node("UI/BoutonAvancer"):
		var btn_avancer = $UI/BoutonAvancer
		if not btn_avancer.pressed.is_connected(_on_bouton_avancer_pressed):
			btn_avancer.pressed.connect(_on_bouton_avancer_pressed)

	bouton_mission.hide()
	
	# Initialisation des personnages
	var noms_cultistes = ["Clovis", "Lilou", "Titouan", "Julien", "Karine"]
	for nom in noms_cultistes:
		if has_node(nom):
			var p = get_node(nom)
			personnages.append(p)
			
			# Positionnement initial
			var local_pos = tile_map.to_local(p.global_position)
			var case_depart = tile_map.local_to_map(local_pos)
			var centre_hex = tile_map.to_global(tile_map.map_to_local(case_depart))
			p.initialiser_position(case_depart, centre_hex)
			
			# Connexion
			if not p.is_connected("selection", _on_selection_demandee):
				p.selection.connect(_on_selection_demandee)
			
			# UI Carte
			var nouvelle_carte = scene_carte.instantiate()
			deck_container.add_child(nouvelle_carte)
			nouvelle_carte.setup(p)
			nouvelle_carte.carte_cliquee.connect(_on_selection_demandee)

	label_info.text = "Secte prête. En attente d'ordres."
	
	await get_tree().process_frame
	for p in personnages:
		reorganiser_positions_sur_case(p.coord_actuelle)

# ==========================================
# LOGIQUE DU TEMPS ET TRANSITION
# ==========================================

func _on_bouton_avancer_pressed():
	# 1. Mise à jour du temps
	var ancien_jour = $Main/TimeManager.day
	$Main/TimeManager.advance_hour()
	heure_actuelle = $Main/TimeManager.hour
	
	var nouveau_jour = $Main/TimeManager.day
	
	# --- DÉTECTION DU CHANGEMENT DE JOUR ---
	if nouveau_jour > ancien_jour:
		declencher_transition_nouveau_jour(nouveau_jour)
		nb_echecs_jour = 0 
	# ---------------------------------------

	# 2. Nettoyage
	label_info.text = "Heure : %02dh | Jour : %d" % [heure_actuelle, nouveau_jour]
	bouton_mission.hide()
	chemin_visuel_actuel.clear()
	personnage_selectionne = null
	queue_redraw()
	
	# 3. Mouvement
	for perso in personnages:
		var fini_maintenant = (perso.temps_mission_restant == 1)
		
		perso.avancer()
		
		if fini_maintenant and perso.mission_actuelle_data != null:
			terminer_et_afficher_mission(perso)
			
		var pos_monde = tile_map.to_global(tile_map.map_to_local(perso.coord_actuelle))
		perso.animer_deplacement(pos_monde)
		update_visuel_carte(perso, false)
	
	# 4. Empilements
	await get_tree().create_timer(0.35).timeout
	var cases_occupees = []
	for p in personnages:
		if not p.coord_actuelle in cases_occupees:
			cases_occupees.append(p.coord_actuelle)
	
	for case in cases_occupees:
		reorganiser_positions_sur_case(case)

func declencher_transition_nouveau_jour(numero_jour: int):
	if scene_transition_jour:
		var transition = scene_transition_jour.instantiate()
		$UI.add_child(transition)
		
		if transition.has_method("setup"):
			# --- CORRECTION ICI : On caste le tableau vide en Array[String] ---
			transition.setup(numero_jour - 1, numero_jour, [] as Array[String])
		elif transition.has_method("set_day"):
			transition.set_day(numero_jour)
			
		print("🌅 Transition visuelle vers le Jour ", numero_jour)

func forcer_passage_jour_suivant():
	# 1. Avance rapide
	var jour_actuel = $Main/TimeManager.day
	while $Main/TimeManager.day == jour_actuel:
		$Main/TimeManager.advance_hour()
	
	# 2. Nouvelles infos
	heure_actuelle = $Main/TimeManager.hour
	var nouveau_jour = $Main/TimeManager.day
	
	# 3. Transition
	declencher_transition_nouveau_jour(nouveau_jour)
	
	# 4. Nettoyage
	label_info.text = "Repli stratégique... Jour %d" % nouveau_jour
	bouton_mission.hide()
	chemin_visuel_actuel.clear()
	personnage_selectionne = null
	queue_redraw()
	
	# 5. Reset échecs
	nb_echecs_jour = 0

# ==========================================
# NAVIGATION ET ENTRÉES
# ==========================================

func construire_graphe_astar():
	astar.clear()
	map_coords_to_id.clear()
	id_counter = 0
	var used_cells = tile_map.get_used_cells()
	
	for cell in used_cells:
		var id = id_counter
		map_coords_to_id[cell] = id
		id_counter += 1
		astar.add_point(id, tile_map.map_to_local(cell))
	
	for cell in used_cells:
		var id_actuel = map_coords_to_id[cell]
		for voisin in tile_map.get_surrounding_cells(cell):
			if map_coords_to_id.has(voisin):
				astar.connect_points(id_actuel, map_coords_to_id[voisin])

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if personnage_selectionne != null:
			var souris_pos = get_global_mouse_position()
			var coord_cible = tile_map.local_to_map(tile_map.to_local(souris_pos))
			
			if map_coords_to_id.has(coord_cible):
				var id_depart = map_coords_to_id[personnage_selectionne.coord_actuelle]
				var id_arrivee = map_coords_to_id[coord_cible]
				var id_path = astar.get_id_path(id_depart, id_arrivee)
				
				if id_path.size() > 1:
					var chemin_grid : Array[Vector2i] = []
					chemin_visuel_actuel.clear()
					
					for i in range(1, id_path.size()):
						var pos_point = astar.get_point_position(id_path[i])
						chemin_grid.append(tile_map.local_to_map(pos_point))
						chemin_visuel_actuel.append(tile_map.to_global(pos_point))
					
					var dest_world = tile_map.to_global(tile_map.map_to_local(coord_cible))
					personnage_selectionne.programmer_itineraire(chemin_grid, dest_world)
					
					update_visuel_carte(personnage_selectionne, true)
					personnage_selectionne = null
					queue_redraw()

# ==========================================
# GESTION DES MISSIONS
# ==========================================

func _on_bouton_mission_pressed():
	if personnage_selectionne:
		var lieu = get_nom_lieu(personnage_selectionne.coord_actuelle)
		preparer_popup_mission(lieu, personnage_selectionne.coord_actuelle)

func preparer_popup_mission(lieu_nom: String, coords: Vector2i):
	missions_locales_dispo.clear()
	var liste = %ListeChoixMissions
	liste.clear()
	_nettoyer_checkboxes_participants()
	
	for m in $Main/MissionManager.missions:
		if m["status"] == 0 and lieu_nom in m["places"]:
			if is_hour_in_range(heure_actuelle, m["hours"]):
				missions_locales_dispo.append(m)
				liste.add_item(m["title"] + " (" + str(m["duration"]) + "h)")
	
	if missions_locales_dispo.is_empty():
		label_info.text = "Aucune mission ici pour le moment."
		return

	%PopupMission.set_meta("coords_actuelles", coords)
	%PopupMission.title = "Missions à : " + lieu_nom
	%PopupMission.popup_centered()

func _on_popup_mission_confirmed():
	var participants = []
	var vbox = %PopupMission.get_node("VBoxContainer")
	for child in vbox.get_children():
		if child is CheckBox and child.button_pressed:
			participants.append(child.get_meta("perso"))
	
	if participants.size() > 0:
		var resultat = $Main/MissionManager.calculer_resultat_final(mission_en_attente, participants)
		mission_en_attente["status"] = 1 # En cours
		
		for p in participants:
			p.temps_mission_restant = mission_en_attente["duration"]
			p.mission_actuelle_data = mission_en_attente
			p.resultat_secret = resultat
			update_visuel_carte(p, false)
			
		label_info.text = "Mission lancée !"
		bouton_mission.hide()
		personnage_selectionne = null

func terminer_et_afficher_mission(perso):
	var m = perso.mission_actuelle_data
	var res = perso.resultat_secret
	
	m["status"] = 2 if res.success else 3
	
	# --- LOGIQUE D'ÉCHEC ---
	if not res.success:
		nb_echecs_jour += 1
		print("💥 Échec n°", nb_echecs_jour, "/ 3")
	
	var popup_res = %PopupResultat
	popup_res.title = "Rapport : " + m["title"]
	popup_res.dialog_text = res.msg
	
	if not res.success and nb_echecs_jour < 3:
		popup_res.dialog_text += "\n\n(Attention : %d/3 échecs avant repli forcé)" % nb_echecs_jour

	# --- DÉTECTION DU GAME OVER ---
	if nb_echecs_jour >= 3:
		if not popup_res.confirmed.is_connected(_sur_fermeture_popup_echec_critique):
			popup_res.confirmed.connect(_sur_fermeture_popup_echec_critique, CONNECT_ONE_SHOT)
			popup_res.canceled.connect(_sur_fermeture_popup_echec_critique, CONNECT_ONE_SHOT)

	popup_res.popup_centered()
	
	perso.mission_actuelle_data = null
	update_visuel_carte(perso, false)

func _sur_fermeture_popup_echec_critique():
	print("🚨 3 échecs atteints ! Fin de journée forcée.")
	if nb_echecs_jour >= 3:
		forcer_passage_jour_suivant()

# ==========================================
# FONCTIONS UTILITAIRES / VISUEL
# ==========================================

func _on_selection_demandee(le_perso):
	if le_perso.est_occupe():
		label_info.text = le_perso.nom_personnage + " est occupé (%dh)" % le_perso.temps_mission_restant
		personnage_selectionne = null
	else:
		personnage_selectionne = le_perso
		label_info.text = "Destination pour " + le_perso.nom_personnage + " ?"
		actualiser_visibilite_bouton_mission(le_perso)
	
	chemin_visuel_actuel.clear()
	queue_redraw()

func actualiser_visibilite_bouton_mission(perso):
	var lieu = get_nom_lieu(perso.coord_actuelle)
	if lieu != "" and est_mission_disponible_ici(lieu):
		bouton_mission.show()
	else:
		bouton_mission.hide()

func est_mission_disponible_ici(lieu_nom: String) -> bool:
	for m in $Main/MissionManager.missions:
		if m["status"] == 0 and lieu_nom in m["places"]:
			if is_hour_in_range(heure_actuelle, m["hours"]): return true
	return false

func get_nom_lieu(coords: Vector2i) -> String:
	var data = tile_map.get_cell_tile_data(coords)
	return data.get_custom_data("nom_lieu") if data else ""

func is_hour_in_range(h, range_arr):
	if range_arr[0] <= range_arr[1]:
		return h >= range_arr[0] and h < range_arr[1]
	return h >= range_arr[0] or h < range_arr[1]

func update_visuel_carte(perso, a_un_ordre: bool):
	for carte in deck_container.get_children():
		if carte.perso_reference == perso:
			carte.mettre_a_jour_visuel(a_un_ordre)

func reorganiser_positions_sur_case(case_grille: Vector2i):
	var persos_ici = personnages.filter(func(p): return p.coord_actuelle == case_grille)
	var centre_hex = tile_map.to_global(tile_map.map_to_local(case_grille))
	
	if persos_ici.size() <= 1:
		if persos_ici.size() == 1:
			create_tween().tween_property(persos_ici[0], "global_position", centre_hex, 0.2)
		return

	var rayon = 25.0
	var angle_step = (2 * PI) / persos_ici.size()
	for i in range(persos_ici.size()):
		var offset = Vector2(cos(i * angle_step - PI/2), sin(i * angle_step - PI/2)) * rayon
		create_tween().tween_property(persos_ici[i], "global_position", centre_hex + offset, 0.3)

func _draw():
	if personnage_selectionne:
		var centre = tile_map.to_global(tile_map.map_to_local(personnage_selectionne.coord_actuelle))
		dessiner_hexagone(centre, Color(0, 0.2, 1, 0.5))
		if chemin_visuel_actuel.size() > 0:
			draw_polyline(chemin_visuel_actuel, Color(1, 1, 1, 0.8), 3.0)

func dessiner_hexagone(centre: Vector2, couleur: Color):
	var rayon = tile_map.tile_set.tile_size.y * 0.48
	var points = PackedVector2Array()
	for i in range(6):
		var a = deg_to_rad(60 * i - 30)
		points.append(centre + Vector2(rayon * cos(a), rayon * sin(a)))
	draw_colored_polygon(points, couleur)

func _on_mission_list_item_selected(index):
	mission_en_attente = missions_locales_dispo[index]
	%PopupMission.get_ok_button().disabled = false
	_generer_choix_cultistes(%PopupMission.get_meta("coords_actuelles"))

func _generer_choix_cultistes(coords: Vector2i):
	_nettoyer_checkboxes_participants()
	var vbox = %PopupMission.get_node("VBoxContainer")
	for p in personnages:
		if p.coord_actuelle == coords and not p.est_occupe():
			var check = CheckBox.new()
			check.text = p.nom_personnage
			check.set_meta("perso", p)
			check.toggled.connect(func(_t): _actualiser_affichage_chances())
			vbox.add_child(check)

func _nettoyer_checkboxes_participants():
	for child in %PopupMission.get_node("VBoxContainer").get_children():
		if child is CheckBox: child.queue_free()

func _actualiser_affichage_chances():
	var participants = []
	for child in %PopupMission.get_node("VBoxContainer").get_children():
		if child is CheckBox and child.button_pressed:
			participants.append(child.get_meta("perso"))
	var proba = $Main/MissionManager.calculer_probabilite(mission_en_attente, participants)
	%PopupMission.get_node("VBoxContainer/LabelChances").text = "Chances : %d%%" % (proba * 100)
