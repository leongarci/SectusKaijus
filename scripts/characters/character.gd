extends Node2D

signal mouvement_termine(perso_nom, nouvelle_coord)
signal selection(mon_instance)

@export var nom_personnage: String = "Personnage"
@export var couleur_point: Color = Color.WHITE
@export var vitesse: int = 1
@export var coord_actuelle: Vector2i = Vector2i(0, 0)
@export var texture_carte : Texture2D
@export var traits: Array[String] = []
@export var competences: Dictionary = {"vol": 0.0, "savoir": 0.0, "force": 0.0, "rituel": 0.0, "discretion": 0.0}

var temps_mission_restant: int = 0
var mission_actuelle_titre: String = ""
var mission_actuelle_data = null
var resultat_secret = {}
var chemin_a_parcourir: Array[Vector2i] = []

func _ready():
	if not has_node("ColorRect"):
		var c = ColorRect.new()
		c.name = "ColorRect"
		add_child(c)
	$ColorRect.color = couleur_point
	var taille=15
	$ColorRect.size = Vector2(taille,taille)
	$ColorRect.position = Vector2(-taille/2, -taille/2)
	
	if has_node("Area2D"):
		if not $Area2D.input_event.is_connected(_on_area_2d_input_event):
			$Area2D.input_event.connect(_on_area_2d_input_event)

var traits_decouverts: Array = []

func reveler_trait(nom_trait: String):
	if not traits_decouverts.has(nom_trait) and nom_trait in traits:
		traits_decouverts.append(nom_trait)
		print("💡 DÉCOUVERTE : " + nom_trait + " est désormais connu pour " + nom_personnage)
		# Ici tu pourras ajouter un petit effet visuel ou sonore plus tard

func initialiser_position(case_grille: Vector2i, position_monde: Vector2):
	coord_actuelle = case_grille
	global_position = position_monde

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selection.emit(self)

func programmer_itineraire(chemin: Array[Vector2i], _pos_finale_monde: Vector2):
	if est_occupe():
		print("❌ " + nom_personnage + " est occupé et ne peut pas recevoir d'ordres.")
		return
	chemin_a_parcourir = chemin

# --- CORRECTION DEMANDÉE : Occupé SEULEMENT si mission ---
func est_occupe() -> bool:
	print("Temps mission restant : ",temps_mission_restant)
	return temps_mission_restant > 0

func avancer():
	# 1. Gestion Mission
	if temps_mission_restant > 0:
		temps_mission_restant -= 1
		print(nom_personnage + " travaille. Reste : " + str(temps_mission_restant))
		return # On ne bouge pas si on travaille

	# 2. Gestion Mouvement
	if chemin_a_parcourir.size() > 0:
		var pas_ce_tour = min(vitesse, chemin_a_parcourir.size())
		var nouvelle_case : Vector2i
		for i in range(pas_ce_tour):
			nouvelle_case = chemin_a_parcourir.pop_front()
		
		coord_actuelle = nouvelle_case
		mouvement_termine.emit(nom_personnage, coord_actuelle)
	
func animer_deplacement(nouvelle_pos_monde: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "global_position", nouvelle_pos_monde, 0.3)
