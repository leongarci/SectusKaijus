extends Node2D

signal mouvement_termine(perso_nom, nouvelle_coord)
signal selection(mon_instance)

@export var nom_personnage: String = "Personnage"
@export var couleur_point: Color = Color.WHITE
@export var vitesse: int = 1
@export var est_occupe: bool = false
@export var coord_actuelle: Vector2i = Vector2i(0, 0)
@export var texture_carte : Texture2D

# --- NOUVEAU : Gestion du chemin long ---
# Liste des prochaines cases à atteindre (le chemin complet restant)
var chemin_a_parcourir: Array[Vector2i] = [] 
var destination_finale_visuelle: Vector2 

# Variables d'état
var mouvement_en_attente: bool = false

@export var competences = {
	"essence": 0.0, "ecaille": 0.0, "kidnapping": 0.0, "creuser": 0.0, "saule": 0.0
}

func _ready():
	$ColorRect.color = couleur_point
	$ColorRect.size = Vector2(50, 50)
	$ColorRect.position = Vector2(-25, -25)
	$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if has_node("Area2D"):
		$Area2D.input_event.connect(_on_area_2d_input_event)

func initialiser_position(case_grille: Vector2i, position_monde: Vector2):
	coord_actuelle = case_grille
	global_position = position_monde
	print(nom_personnage + " initialisé en case " + str(case_grille))

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selection.emit(self)

# --- NOUVELLE LOGIQUE DE PROGRAMMATION ---
# On reçoit maintenant un CHEMIN (liste de cases) et non plus juste une case
func programmer_itineraire(chemin: Array[Vector2i], pos_finale_monde: Vector2):
	chemin_a_parcourir = chemin
	destination_finale_visuelle = pos_finale_monde
	mouvement_en_attente = true
	
	# La destination prévue pour CE tour dépend de la vitesse
	# Mais la vraie finalité est stockée dans chemin_a_parcourir
	print(nom_personnage + " a programmé un itinéraire de " + str(chemin.size()) + " étapes.")

func avancer():
	# Si on a un chemin à parcourir
	if chemin_a_parcourir.size() > 0:
		
		# 1. On détermine combien de pas on fait ce tour-ci
		# On prend le minimum entre la vitesse et ce qu'il reste à parcourir
		var pas_ce_tour = min(vitesse, chemin_a_parcourir.size())
		
		# 2. On avance virtuellement dans la liste
		var nouvelle_case : Vector2i
		
		# On "consomme" les étapes du chemin
		for i in range(pas_ce_tour):
			nouvelle_case = chemin_a_parcourir.pop_front() # Enlève la 1ère case et la renvoie
		
		# 3. Mise à jour officielle
		coord_actuelle = nouvelle_case
		
		# NOTE : Le déplacement visuel (Tween) sera géré par SceneTest (reorganiser_positions)
		# ou tu peux faire un tween ici vers la position monde de 'nouvelle_case'
		
		print(nom_personnage + " avance de " + str(pas_ce_tour) + " cases. Reste : " + str(chemin_a_parcourir.size()))
		mouvement_termine.emit(nom_personnage, coord_actuelle)
		
	else:
		print(nom_personnage + " n'a pas de chemin ou est arrivé.")

func calculer_succes(type_mission: String, proba_base: float) -> float:
	var bonus = competences.get(type_mission, 0.0)
	return clamp(proba_base + bonus, 0.0, 1.0)
