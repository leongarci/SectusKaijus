extends Node2D

# Déclarer un signal qui permet de dire si le mouvement est terminé
signal mouvement_termine(perso_nom, nouvelle_coord)

# Signal pour voir si le perso est sélectionné
signal selection(mon_instance)

# Propriétés de base du personnage
@export var nom_personnage: String = "Personnage"
@export var couleur_point: Color = Color.WHITE
@export var est_occupe: bool = false
@export var coord_actuelle: Vector2i = Vector2i(0, 0)
@export var texture_carte : Texture2D

# Variables de planification
var destination_prevue_grille: Vector2i = Vector2i(0, 0)
var prochaine_position_pixels: Vector2 # <-- NOUVEAU : On retient où on doit aller en pixels
var mouvement_en_attente: bool = false
var position_logique_grille : Vector2i

@export var competences = {
	"essence": 0.0, "ecaille": 0.0, "kidnapping": 0.0, "creuser": 0.0, "saule": 0.0
}

func _ready():
	# Initialisation visuelle
	$ColorRect.color = couleur_point
	$ColorRect.size = Vector2(50, 50)
	$ColorRect.position = Vector2(-15, -15)
	$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if has_node("Area2D"):
		$Area2D.input_event.connect(_on_area_2d_input_event)

# Appelée par scene_test au démarrage pour caler le perso
func initialiser_position(case_grille: Vector2i, position_monde: Vector2):
	coord_actuelle = case_grille
	destination_prevue_grille = case_grille
	prochaine_position_pixels = position_monde # On initialise la destination sur soi-même
	
	# Ici, on téléporte immédiatement car c'est le setup du début
	global_position = position_monde
	print(nom_personnage + " initialisé en case " + str(case_grille))

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selection.emit(self)

# Clic sur la map = On PRÉPARE le mouvement, on ne bouge pas encore
func programmer_deplacement(nouvelle_case_grille: Vector2i, nouvelle_pos_monde: Vector2):
	destination_prevue_grille = nouvelle_case_grille
	prochaine_position_pixels = nouvelle_pos_monde # On retient la destination pixel pour plus tard
	mouvement_en_attente = true
	
	# On met à jour la logique "virtuelle" tout de suite si besoin (pour empêcher d'autres actions)
	position_logique_grille = nouvelle_case_grille
	
	print(nom_personnage + " a prévu d'aller en " + str(nouvelle_case_grille) + " (Attente validation)")

# Appui sur le bouton AVANCER = On BOUGE vraiment
func avancer():
	if mouvement_en_attente:
		# 1. Validation logique
		coord_actuelle = destination_prevue_grille
		
		# 2. Validation Visuelle (C'est ici qu'on se téléporte maintenant)
		global_position = prochaine_position_pixels
		
		mouvement_en_attente = false
		mouvement_termine.emit(nom_personnage, coord_actuelle)
		print(nom_personnage, " se déplace et arrive en ", coord_actuelle)

func calculer_succes(type_mission: String, proba_base: float) -> float:
	var bonus = competences.get(type_mission, 0.0)
	return clamp(proba_base + bonus, 0.0, 1.0)
