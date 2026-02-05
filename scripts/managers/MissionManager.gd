extends Node
class_name MissionManager

signal missions_changed

var missions: Array = [
	# NIVEAU 1 (Facile - 80% de base)
	{ "id": 5, "title": "Voler le repas", "places": ["Maison de retraite"], "diff": 0.0, "duration": 1, "hours": [11, 14], "status": 0, "skill": "vol" },
	{ "id": 1, "title": "Catnapper un chat", "places": ["SPA", "Parc"], "diff": 0.1, "duration": 2, "hours": [9, 18], "status": 0, "skill": "discretion" }, # 70%

	# NIVEAU 2 (Moyen - Demande un peu de compétence)
	{ "id": 2, "title": "Kidnapper un gosse", "places": ["Ecole"], "diff": 0.3, "duration": 4, "hours": [8, 17], "status": 0, "skill": "force" }, # 50%
	{ "id": 4, "title": "Récupérer une écaille", "places": ["Musée"], "diff": 0.3, "duration": 3, "hours": [10, 19], "status": 0, "skill": "savoir" }, # 50%
	{ "id": 8, "title": "Danse sacrée", "places": ["Salle de sport"], "diff": 0.4, "duration": 2, "hours": [7, 21], "status": 0, "skill": "rituel" }, # 40%

	# NIVEAU 3 (Difficile - Risque d'échec élevé sans le bon trait)
	{ "id": 3, "title": "Déterrer un OS", "places": ["Cimetiere"], "diff": 0.5, "duration": 3, "hours": [21, 5], "status": 0, "skill": "force" }, # 30%
	{ "id": 7, "title": "Livre ancien", "places": ["Bibliothèque"], "diff": 0.5, "duration": 3, "hours": [10, 18], "status": 0, "skill": "savoir" }, # 30%
	
	# NIVEAU 4 (Expert - Presque impossible sans bonus)
	{ "id": 6, "title": "Sourire au Saule", "places": ["Parc"], "diff": 0.6, "duration": 5, "hours": [0, 24], "status": 0, "skill": "charisme" }, # 20%
	{ "id": 9, "title": "Trouver la grotte", "places": ["Grotte"], "diff": 0.7, "duration": 4, "hours": [0, 24], "status": 0, "skill": "orientation" }, # 10%
	{ "id": 10, "title": "Cérémonie finale", "places": ["Base"], "diff": 0.8, "duration": 4, "hours": [0, 4], "status": 0, "skill": "rituel" } # 0% (Besoin absolu de bonus)
]

var database_traits = {
	# --- BONUS (1 par cultiste) ---
	"Hercule": { 
		"type": "bonus", "skill": "force", "val": 0.3, 
		"msg_win": "Grâce à sa force herculéenne, %s a tout écrasé sur son passage !" 
	},
	"Fantôme": { 
		"type": "bonus", "skill": "discretion", "val": 0.3, 
		"msg_win": "%s s'est faufilé comme une ombre, personne n'a rien vu." 
	},
	"Erudit": { 
		"type": "bonus", "skill": "savoir", "val": 0.3, 
		"msg_win": "La culture immense de %s a permis de résoudre l'énigme instantanément." 
	},
	"Charmeur": { 
		"type": "bonus", "skill": "charisme", "val": 0.3, 
		"msg_win": "Avec son sourire ravageur, %s a obtenu tout ce qu'il voulait." 
	},
	"Kleptomane": { 
		"type": "bonus", "skill": "vol", "val": 0.3, 
		"msg_win": "Les mains agiles de %s ont subtilisé l'objet avant même qu'on cligne des yeux." 
	},
	"Occultiste": { 
		"type": "bonus", "skill": "rituel", "val": 0.3, 
		"msg_win": "La maîtrise des arcanes de %s a rendu le rituel parfait." 
	},

	# --- DÉFAUTS MAJEURS / BLOQUANTS ---
	"Nyctophobe": { 
		"type": "bloquant", "condition": "NUIT", 
		"msg_fail": "ÉCHEC CRITIQUE : %s a fait une crise de panique dans le noir !" 
	},
	"Ailurophobe": { 
		"type": "bloquant", "condition": "CHAT", 
		"msg_fail": "ÉCHEC CRITIQUE : %s s'est enfui en hurlant à la vue d'un chat !" 
	},
	"Claustrophobe": { 
		"type": "bloquant", "condition": "GROTTE", 
		"msg_fail": "ÉCHEC CRITIQUE : %s refuse catégoriquement d'entrer dans un endroit si serré." 
	},
	"Athée": { 
		"type": "bloquant", "condition": "RITUEL", # Bloque les missions "Rituel" ou "Cérémonie"
		"msg_fail": "ÉCHEC CRITIQUE : %s refuse de participer à ces 'bêtises mystiques'." 
	},

	# --- DÉFAUTS MINEURS (Malus de stats) ---
	"Maladroit": { 
		"type": "malus_stat", "skill": "discretion", "val": -0.2, 
		"msg_fail": "%s a trébuché et fait tomber un vase, alertant les gardes..." 
	},
	"Faible": { 
		"type": "malus_stat", "skill": "force", "val": -0.2, 
		"msg_fail": "%s n'a pas eu la force nécessaire pour accomplir la tâche..." 
	},
	"Ignare": { 
		"type": "malus_stat", "skill": "savoir", "val": -0.2, 
		"msg_fail": "%s n'a rien compris aux instructions et a tout gâché." 
	},
	"Timide": { 
		"type": "malus_stat", "skill": "charisme", "val": -0.2, 
		"msg_fail": "%s a bafouillé et n'a pas osé demander l'objet." 
	}
}

func get_nombre_missions_reussies() -> int:
	var compteur = 0
	for m in missions:
		if m["status"] == 2: # 2 = RÉUSSIE
			compteur += 1
	return compteur

func get_nombre_total_missions() -> int:
	return missions.size()

func verifier_condition_blocage(condition: String, mission: Dictionary) -> bool:
	if condition == "NUIT":
		var debut = mission["hours"][0]
		return (debut >= 21 or debut < 6)
	if condition == "CHAT":
		return mission["title"].contains("chat") or "Parc" in mission["places"] or "SPA" in mission["places"]
	if condition == "GROTTE":
		return "Grotte" in mission["places"]
	if condition == "RITUEL":
		return mission["skill"] == "rituel"
	return false
	
func calculer_probabilite(mission, participants: Array) -> float:
	# --- MODIFICATION PRINCIPALE ICI ---
	# Ancien : 0.5 - diff (donc 50% si diff=0)
	# Nouveau : 0.8 - diff (donc 80% si diff=0)
	var chance_de_base = 0.8 
	var chance = chance_de_base - mission.get("diff", 0.0)
	# -----------------------------------
	
	var skill_requis = mission.get("skill", "")
	
	for p in participants:
		chance += (p.competences.get(skill_requis, 0.0) / 3.0)
		
		for nom_trait in p.traits:
			if database_traits.has(nom_trait):
				var data = database_traits[nom_trait]
				# On applique Bonus ou Malus de stat
				if (data["type"] == "bonus" or data["type"] == "malus_stat"):
					if data["skill"] == "ANY" or data["skill"] == skill_requis:
						chance += data["val"]
	
	return clamp(chance, 0.05, 0.95)

func calculer_resultat_final(mission, participants: Array) -> Dictionary:
	# 1. BLOQUANTS
	for p in participants:
		for nom_trait in p.traits:
			if database_traits.has(nom_trait):
				var data = database_traits[nom_trait]
				if data["type"] == "bloquant":
					if verifier_condition_blocage(data["condition"], mission):
						# --- AJOUT : ON RÉVÈLE LE TRAIT COUPABLE ---
						p.reveler_trait(nom_trait) 
						return {"success": false, "msg": data["msg_fail"] % p.nom_personnage}

	# 2. PROBA & TIRAGE
	var proba = calculer_probabilite(mission, participants)
	var success = randf() < proba
	var message_final = ""
	
	if success:
		message_final = "SUCCÈS : " + mission["title"] + " accomplie !"
		for p in participants:
			for nom_trait in p.traits:
				if database_traits.has(nom_trait):
					var data = database_traits[nom_trait]
					# Si c'est un BONUS qui a aidé
					if data["type"] == "bonus" and (data["skill"] == mission["skill"] or data["skill"] == "ANY"):
						message_final += "\n" + (data["msg_win"] % p.nom_personnage)
						# --- AJOUT : ON RÉVÈLE LE BONUS ---
						p.reveler_trait(nom_trait)
						break 
	else:
		message_final = "ÉCHEC : La mission " + mission["title"] + " a raté..."
		for p in participants:
			for nom_trait in p.traits:
				if database_traits.has(nom_trait):
					var data = database_traits[nom_trait]
					# Si c'est un MALUS qui a gêné
					if data["type"] == "malus_stat" and (data["skill"] == mission["skill"]):
						message_final += "\n" + (data["msg_fail"] % p.nom_personnage)
						# --- AJOUT : ON RÉVÈLE LE MALUS ---
						p.reveler_trait(nom_trait)
						break 
						
	return {"success": success, "msg": message_final}



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
