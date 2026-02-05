extends Node
class_name MissionManager

signal missions_changed

var missions: Array = [
	{ "id": 1, "title": "Catnapper un chat", "places": ["SPA", "Parc"], "diff": 0.4, "duration": 2, "hours": [9, 18], "status": 0 },
	{ "id": 2, "title": "Kidnapper un gosse", "places": ["Ecole"], "diff": 0.9, "duration": 4, "hours": [8, 17], "status": 0 },
	{ "id": 3, "title": "Déterrer un OS", "places": ["Cimetiere"], "diff": 0.5, "duration": 3, "hours": [21, 5], "status": 0 },
	{ "id": 4, "title": "Récupérer une écaille", "places": ["Musée"], "diff": 0.6, "duration": 3, "hours": [10, 19], "status": 0 },
	{ "id": 5, "title": "Voler le repas", "places": ["Maison de retraite"], "diff": 0.2, "duration": 1, "hours": [11, 14], "status": 0 },
	{ "id": 6, "title": "Sourire au Saule", "places": ["Parc"], "diff": 0.3, "duration": 5, "hours": [0, 24], "status": 0 },
	{ "id": 7, "title": "Livre ancien", "places": ["Bibliothèque"], "diff": 0.7, "duration": 3, "hours": [10, 18], "status": 0 },
	{ "id": 8, "title": "Danse sacrée", "places": ["Salle de sport"], "diff": 0.2, "duration": 2, "hours": [7, 21], "status": 0 },
	{ "id": 9, "title": "Trouver la grotte", "places": ["Grotte"], "diff": 0.4, "duration": 4, "hours": [0, 24], "status": 0 },
	{ "id": 10, "title": "Cérémonie finale", "places": ["Base"], "diff": 0.8, "duration": 4, "hours": [0, 4], "status": 0 }
]

func calculer_resultat_final(mission, participants: Array) -> Dictionary:
	var proba = calculer_probabilite(mission, participants)
	
	# Vérification des traits bloquants
	for p in participants:
		if p.traits.has("Ailurophobe") and ("Parc" in mission["places"] or "SPA" in mission["places"]):
			return {"success": false, "msg": p.nom_personnage + " a paniqué !"}

	if randf() < proba:
		return {"success": true, "msg": "SUCCÈS : " + mission["title"]}
	else:
		return {"success": false, "msg": "ÉCHEC : " + mission["title"]}

# --- LA FONCTION MANQUANTE ---
func calculer_probabilite(mission, participants: Array) -> float:
	# Base de 50% de réussite moins la difficulté
	var chance = 0.5 - mission.get("diff", 0.5)
	
	for p in participants:
		# On récupère le bonus de compétence du cultiste
		var competence_nom = mission.get("skill", "")
		var bonus = p.competences.get(competence_nom, 0.0)
		chance += bonus
	
	# On limite entre 5% et 95% pour garder un petit suspense
	return clamp(chance, 0.05, 0.95)

# --- LA FONCTION DE LANCEMENT ---
func tenter_mission(mission, participants: Array, _heure: int) -> Dictionary:
	# 1. Vérification des traits bloquants (ex: peur des chats)
	for p in participants:
		if p.traits.has("Ailurophobe") and ("Parc" in mission["places"] or "SPA" in mission["places"]):
			return {"success": false, "msg": p.nom_personnage + " a paniqué face à un chat !"}
	
	# 2. Calcul des chances
	var proba = calculer_probabilite(mission, participants)
	
	# 3. Tirage aléatoire
	if randf() < proba:
		return {"success": true, "msg": "Mission réussie : " + mission["title"]}
	else:
		return {"success": false, "msg": "Échec de la mission..."}
func get_missions() -> Array:
	return missions

func try_place(place_name: String) -> String:
	for m in missions:
		if m["done"]:
			continue

		if place_name in m["places"]:
			m["done"] = true
			m["revealed_place"] = place_name
			emit_signal("missions_changed")
			return "Mission accomplie : %s (lieu : %s)" % [m["title"], place_name]

	return "Rien ici..."
