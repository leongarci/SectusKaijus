extends Node
class_name MissionManager

signal missions_changed

var missions: Array = [
	{
		"id": 1,
		"title": "Catnapper un chat",
		"places": ["Parc", "SPA"],
		"done": false,
		"difficulté" : 0.6,
		"revealed_place": ""
	},
	{
		"id": 2,
		"title": "Kidnapper un gosse",
		"places": ["Ecole", "Parc"],
		"done": false,
		"difficulté" : 1,
		"revealed_place": ""
	},
	{
		"id": 3,
		"title": "Déterrer un OS",
		"places": ["Cimetiere", "Hopital"],
		"done": false,
		"difficulté" : 0.5,
		"revealed_place": ""
	},
	{
		"id": 4,
		"title": "Récupérer une écaille de kaiju",
		"places": ["Musée"],
		"done": false,
		"difficulté" : 0.7,
		"revealed_place": ""
	},
	{
		"id": 5,
		"title": "Voler le repas d'une persone âgée",
		"places": ["Maison de retraite", "Parc"],
		"done": false,
		"difficulté" : 0.3,
		"revealed_place": ""
	},
	{
		"id": 6,
		"title": "Rendre le sourire à un Saule Pleureur",
		"places": ["Parc"],
		"done": false,
		"difficulté" : 0.5,
		"revealed_place": ""
	},
	{
		"id": 7,
		"title": "Se procurer un livre ancien",
		"places": ["Bibliothèque", "Musée"],
		"done": false,
		"difficulté" : 0.7,
		"revealed_place": ""
	},
	{
		"id": 8,
		"title": "Prendre un cours de danse sacrée",
		"places": ["Salle de sport", "Parc"],
		"done": false,
		"difficulté" : 0.2,
		"revealed_place": ""
	},
	{
		"id": 9,
		"title": "Trouver la grotte",
		"places": ["Grotte"],
		"done": false,
		"difficulté" : 0.4,
		"revealed_place": ""
	},
	{
		"id": 10,
		"title": "Faire la cérémonie",
		"places": ["Base"],
		"done": false,
		"difficulté" : 0.3,
		"revealed_place": ""
	},
]

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
