extends Node2D
#Déclarer un signal qui permet de dire si le mouvement est terminé
signal mouvement_termine(perso_nom, nouvelle_coord)

# signal pour voir si le perso est sélectionné
signal selection(mon_instance)

# Propriétés de base du personnage
@export var nom_personnage: String = "Personnage"
@export var couleur_point: Color = Color.WHITE
@export var est_occupe: bool = false # Si vrai, il ne peut pas faire d'autre mission
@export var coord_actuelle: Vector2i = Vector2i(0, 0) # Position réelle
@export var texture_carte : Texture2D

# Variables de planification
var destination_prevue: Vector2i = Vector2i(0, 0)
var mouvement_en_attente: bool = false

# Dictionnaire des bonus/malus selon la liste des missions
@export var competences = {
	"essence": 0.0,
	"ecaille": 0.0,
	"kidnapping": 0.0,
	"creuser": 0.0,
	"saule": 0.0
}

func _ready():
	# Initialisation visuelle pour la V0
	$ColorRect.color = couleur_point
	$ColorRect.size = Vector2(30, 30)
	$ColorRect.position = Vector2(-15, -15)
	$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Area2D.input_event.connect(_on_area_2d_input_event)
	# On place le perso au bon endroit au départ
	position = position.snapped(Vector2(64, 64))	# Vérification rapide des stats en console au lancement
	coord_actuelle = Vector2i(position.x / 64, position.y / 64)
	var test_mission = "kidnapping"
	var chance = calculer_succes(test_mission, 0.5)
	print("V0 - Perso: ", nom_personnage, " | Mission: ", test_mission, " | Chance: ", chance * 100, "%")
	if has_node("Area2D"):
		$Area2D.input_event.connect(_on_area_2d_input_event)
	else:
		print("ERREUR : Il manque un noeud Area2D sur ", nom_personnage)

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Clic détecté sur : ", nom_personnage)
		selection.emit(self) # On s'envoie soi-même au chef d'orchestre

# Fonction appelée par le joueur : clic sur la map pour choisir où ira le perso
func programmer_deplacement(nouvelle_coord: Vector2i):
	destination_prevue = nouvelle_coord
	mouvement_en_attente = true
	print(nom_personnage, " a pour ordre d'aller en : ", nouvelle_coord)

# Quand le joueur appuie sur 
func avancer():
	if mouvement_en_attente:
		coord_actuelle = destination_prevue
		# Mise à jour visuelle (on simule la grille par 64 pixels)
		self.position = Vector2(coord_actuelle.x * 64, coord_actuelle.y * 64)
		mouvement_en_attente = false
		mouvement_termine.emit(nom_personnage, coord_actuelle)
		print(nom_personnage, " est arrivé en ", coord_actuelle)

# Calcul de probabilité influencé par les points forts/faibles
func calculer_succes(type_mission: String, proba_base: float) -> float:
	var bonus = competences.get(type_mission, 0.0)
	# La formule simple : $P_{finale} = P_{base} + Bonus$
	return clamp(proba_base + bonus, 0.0, 1.0)
