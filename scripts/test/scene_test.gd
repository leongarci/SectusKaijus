extends Node2D

# --- PRÉCHARGEMENTS ---
var scene_carte = preload("res://scenes/characters/carte_perso.tscn")
var scene_transition_jour = preload("res://scenes/ui/DayTransition.tscn")
var transition_overlay = preload("res://scenes/ui/TransitionOverlay.tscn")
var scene_echec_transi = preload("res://scenes/ui/EchecTransiDay.tscn")
var scene_bouton_monde = preload("res://scenes/ui/BoutonMission.tscn")

# --- VARIABLES EXPORTÉES ---
@export var tile_map : TileMapLayer

# --- NOEUDS UI ---
@onready var conteneur_boutons = $ConteneurBoutonsMission
@onready var label_info = $UI/MessageInfo
@onready var deck_container = $UI/DeckContainer
@onready var bouton_mission = %BoutonMission

# --- VARIABLES DE JEU ---
var personnage_selectionne = null
var heure_actuelle : int = 0
var nb_echecs_jour : int = 0
var personnages = []
var coords_base : Vector2i = Vector2i.ZERO

# --- NAVIGATION A-STAR ---
var astar = AStar2D.new()
var map_coords_to_id = {}
var id_counter = 0
var chemin_visuel_actuel : PackedVector2Array = []

# --- GESTION MISSIONS ---
var mission_en_attente = null
var missions_locales_dispo = []

# ==========================================
# INITIALISATION
# ==========================================

func _ready():
	if tile_map == null:
		push_error("ERREUR : Tile Map non assignée dans l'inspecteur !")
		return
	
	construire_graphe_astar()
	
	# Connexions UI
	bouton_mission.pressed.connect(_on_bouton_mission_pressed)
	%PopupMission.confirmed.connect(_on_popup_mission_confirmed)
	%ListeChoixMissions.item_selected.connect(_on_mission_list_item_selected)
	
	if has_node("UI/BoutonAvancer"):
		$UI/BoutonAvancer.pressed.connect(_on_bouton_avancer_pressed)

	bouton_mission.hide()
	
	# Configuration des Personnages
	var configs_persos = {
		"Clovis":  ["Hercule", "Nyctophobe", "Ignare"],
		"Lilou":   ["Fantôme", "Ailurophobe", "Faible"],
		"Titouan": ["Erudit", "Claustrophobe", "Maladroit"],
		"Julien":  ["Charmeur", "Athée", "Timide"],
		"Karine":  ["Kleptomane", "Nyctophobe", "Ignare"]
	}
	
	trouver_la_base()
	
	for nom in configs_persos.keys():
		if has_node(nom):
			var p = get_node(nom)
			personnages.append(p)
			
			# Positionnement initial
			var centre_hex = tile_map.to_global(tile_map.map_to_local(coords_base))
			p.initialiser_position(coords_base, centre_hex)
			
			# Signaux
			p.selection.connect(_on_selection_demandee)
			
			# UI Carte (Deck)
			var nouvelle_carte = scene_carte.instantiate()
			deck_container.add_child(nouvelle_carte)
			nouvelle_carte.setup(p)
			nouvelle_carte.carte_cliquee.connect(_on_selection_demandee)
			
			if not nouvelle_carte.has_user_signal("demande_fiche"):
				nouvelle_carte.add_user_signal("demande_fiche")
			nouvelle_carte.demande_fiche.connect(afficher_fiche_personnage)
			
			p.traits.assign(configs_persos[nom])

	label_info.text = "Secte prête. En attente d'ordres."
	actualiser_liste_missions_hud()
	
	await get_tree().process_frame
	for p in personnages:
		reorganiser_positions_sur_case(p.coord_actuelle)
	actualiser_boutons_monde()

# ==========================================
# LOGIQUE DU TEMPS ET TRANSITION
# ==========================================

func trouver_la_base():
	for cell in tile_map.get_used_cells():
		if get_nom_lieu(cell) == "Base":
			coords_base = cell
			return
	print("⚠️ Base non trouvée !")

func demarrer_nouvelle_journee():
	for m in $Main/MissionManager.missions:
		m["status"] = 0
	actualiser_liste_missions_hud()
	
	if coords_base != Vector2i.ZERO:
		var pos_monde_base = tile_map.to_global(tile_map.map_to_local(coords_base))
		for p in personnages:
			p.temps_mission_restant = 0
			p.mission_actuelle_data = null
			p.coord_actuelle = coords_base
			create_tween().tween_property(p, "global_position", pos_monde_base, 0.5).set_trans(Tween.TRANS_CUBIC)
			update_visuel_carte(p, false)
			
		await get_tree().create_timer(0.6).timeout
		reorganiser_positions_sur_case(coords_base)
	
	personnage_selectionne = null
	chemin_visuel_actuel.clear()
	queue_redraw()

func _on_bouton_avancer_pressed():
	var ancien_jour = $Main/TimeManager.day
	$Main/TimeManager.advance_hour()
	heure_actuelle = $Main/TimeManager.hour
	var nouveau_jour = $Main/TimeManager.day
	
	if nouveau_jour > ancien_jour:
		declencher_transition_nouveau_jour(ancien_jour, nouveau_jour)
		nb_echecs_jour = 0
		demarrer_nouvelle_journee()
	
	label_info.text = "Heure : %02dh | Jour : %d" % [heure_actuelle, nouveau_jour]
	bouton_mission.hide()
	
	for perso in personnages:
		var fini_maintenant = (perso.temps_mission_restant == 1)
		perso.avancer()
		if fini_maintenant and perso.mission_actuelle_data != null:
			terminer_et_afficher_mission(perso)
		
		var pos_monde = tile_map.to_global(tile_map.map_to_local(perso.coord_actuelle))
		perso.animer_deplacement(pos_monde)
		update_visuel_carte(perso, false)
	
	await get_tree().create_timer(0.35).timeout
	actualiser_boutons_monde()
	reorganiser_toutes_les_cases()

func reorganiser_toutes_les_cases():
	var cases_occupees = []
	for p in personnages:
		if not p.coord_actuelle in cases_occupees:
			cases_occupees.append(p.coord_actuelle)
	for case in cases_occupees:
		reorganiser_positions_sur_case(case)

func declencher_transition_nouveau_jour(jour_depart: int, jour_arrivee: int):
	if scene_transition_jour:
		var transition = scene_transition_jour.instantiate()
		if transition.has_method("setup"):
			transition.setup(jour_depart, jour_arrivee, [] as Array[String])
		$UI.add_child(transition)

func forcer_passage_jour_suivant():
	var overlay_instance = null
	if transition_overlay:
		overlay_instance = transition_overlay.instantiate()
		add_child(overlay_instance)
		overlay_instance.couvrir_ecran()
		await overlay_instance.ecran_couvert
	
	if scene_echec_transi:
		var echec_instance = scene_echec_transi.instantiate()
		if overlay_instance: overlay_instance.add_child(echec_instance)
		else: $UI.add_child(echec_instance)
		await echec_instance.fin_dialogue
	
	var jour_avant = $Main/TimeManager.day
	while $Main/TimeManager.day == jour_avant:
		$Main/TimeManager.advance_hour()
	
	demarrer_nouvelle_journee()
	nb_echecs_jour = 0
	if is_instance_valid(overlay_instance): overlay_instance.queue_free()
	
	declencher_transition_nouveau_jour(jour_avant, $Main/TimeManager.day)

# ==========================================
# NAVIGATION ET ENTRÉES
# ==========================================

func construire_graphe_astar():
	astar.clear()
	map_coords_to_id.clear()
	id_counter = 0
	var used_cells = tile_map.get_used_cells()
	
	for cell in used_cells:
		map_coords_to_id[cell] = id_counter
		astar.add_point(id_counter, tile_map.map_to_local(cell))
		id_counter += 1
	
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
					
					personnage_selectionne.programmer_itineraire(chemin_grid, tile_map.to_global(tile_map.map_to_local(coord_cible)))
					update_visuel_carte(personnage_selectionne, true)
					personnage_selectionne = null
					queue_redraw()

# ==========================================
# GESTION DES MISSIONS
# ==========================================

func _on_bouton_mission_pressed():
	if personnage_selectionne:
		preparer_popup_mission(get_nom_lieu(personnage_selectionne.coord_actuelle), personnage_selectionne.coord_actuelle)

func preparer_popup_mission(lieu_nom: String, coords: Vector2i):
	missions_locales_dispo.clear()
	%ListeChoixMissions.clear()
	_nettoyer_checkboxes_participants()
	
	for m in $Main/MissionManager.missions:
		if m["status"] == 0 and lieu_nom in m["places"] and is_hour_in_range(heure_actuelle, m["hours"]):
			missions_locales_dispo.append(m)
			%ListeChoixMissions.add_item(m["title"] + " (" + str(m["duration"]) + "h)")
	
	if not missions_locales_dispo.is_empty():
		%PopupMission.set_meta("coords_actuelles", coords)
		%PopupMission.popup_centered()

func _on_popup_mission_confirmed():
	var participants = []
	for child in %PopupMission.get_node("VBoxContainer").get_children():
		if child is CheckBox and child.button_pressed:
			participants.append(child.get_meta("perso"))
	
	if participants.size() > 0:
		var res = $Main/MissionManager.calculer_resultat_final(mission_en_attente, participants)
		mission_en_attente["status"] = 1
		for p in participants:
			p.temps_mission_restant = mission_en_attente["duration"]
			p.mission_actuelle_data = mission_en_attente
			p.resultat_secret = res
			update_visuel_carte(p, false)
		actualiser_boutons_monde()
		actualiser_liste_missions_hud()

func terminer_et_afficher_mission(perso):
	var m = perso.mission_actuelle_data
	var res = perso.resultat_secret
	m["status"] = 2 if res.success else 3
	actualiser_liste_missions_hud()

	if not res.success: nb_echecs_jour += 1
	
	%PopupResultat.dialog_text = res.msg
	if nb_echecs_jour >= 1:
		%PopupResultat.confirmed.connect(_sur_fermeture_popup_echec_critique, CONNECT_ONE_SHOT)
	%PopupResultat.popup_centered()
	
	perso.mission_actuelle_data = null
	update_visuel_carte(perso, false)

func _sur_fermeture_popup_echec_critique():
	forcer_passage_jour_suivant()

# ==========================================
# VISUEL ET UI
# ==========================================

func _on_selection_demandee(le_perso):
	if le_perso.est_occupe():
		label_info.text = "%s est occupé" % le_perso.nom_personnage
	else:
		personnage_selectionne = le_perso
		label_info.text = "Destination ?"
	queue_redraw()

func reorganiser_positions_sur_case(case_grille: Vector2i):
	var persos_ici = personnages.filter(func(p): return p.coord_actuelle == case_grille)
	var centre_hex = tile_map.to_global(tile_map.map_to_local(case_grille))
	if persos_ici.size() <= 1:
		if persos_ici.size() == 1:
			create_tween().tween_property(persos_ici[0], "global_position", centre_hex, 0.2)
		return
	var rayon = 25.0
	for i in range(persos_ici.size()):
		var angle = (i * 2 * PI / persos_ici.size()) - PI/2
		var offset = Vector2(cos(angle), sin(angle)) * rayon
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

func _actualiser_affichage_chances():
	var p_list = []
	for c in %PopupMission.get_node("VBoxContainer").get_children():
		if c is CheckBox and c.button_pressed: p_list.append(c.get_meta("perso"))
	var proba = $Main/MissionManager.calculer_probabilite(mission_en_attente, p_list)
	%PopupMission.get_node("VBoxContainer/LabelChances").text = "Chances : %d%%" % (proba * 100)

func actualiser_boutons_monde():
	for enfant in conteneur_boutons.get_children(): enfant.queue_free()
	var cases = {}
	for p in personnages:
		if not p.est_occupe(): cases[p.coord_actuelle] = true
	for coords in cases.keys():
		var lieu = get_nom_lieu(coords)
		if lieu != "" and est_mission_disponible_ici(lieu):
			creer_bouton_a(coords, lieu)

func creer_bouton_a(coords: Vector2i, lieu: String):
	var btn = scene_bouton_monde.instantiate()
	conteneur_boutons.add_child(btn)
	btn.global_position = tile_map.to_global(tile_map.map_to_local(coords)) + Vector2(0, -50)
	btn.setup(coords)
	btn.clic_mission.connect(func(c): preparer_popup_mission(lieu, c))

func actualiser_liste_missions_hud():
	var list = $Main/CanvasLayer/UI_mission/MissionPanel/MissionBox/MissionList
	if not list: return
	list.clear()
	for m in $Main/MissionManager.missions:
		var idx = list.add_item(m["title"])
		match m["status"]:
			1: list.set_item_custom_bg_color(idx, Color(0.8, 0.6, 0, 0.5))
			2: list.set_item_custom_bg_color(idx, Color(0.2, 0.8, 0.2, 0.5))
			3: list.set_item_custom_bg_color(idx, Color(0.8, 0.2, 0.2, 0.5))

# --- Helpers ---
func get_nom_lieu(coords: Vector2i) -> String:
	var data = tile_map.get_cell_tile_data(coords)
	return data.get_custom_data("nom_lieu") if data else ""

func est_mission_disponible_ici(lieu: String) -> bool:
	return $Main/MissionManager.missions.any(func(m): return m["status"] == 0 and lieu in m["places"] and is_hour_in_range(heure_actuelle, m["hours"]))

func is_hour_in_range(h, r):
	return (h >= r[0] and h < r[1]) if r[0] <= r[1] else (h >= r[0] or h < r[1])

func update_visuel_carte(perso, order: bool):
	for c in deck_container.get_children():
		if c.perso_reference == perso: c.mettre_a_jour_visuel(order)

func _nettoyer_checkboxes_participants():
	for child in %PopupMission.get_node("VBoxContainer").get_children():
		if child is CheckBox: child.queue_free()

func afficher_fiche_personnage(perso):
	%LabelNom.text = "Fiche de " + perso.nom_personnage
	%FichePersoPopup.popup_centered()
