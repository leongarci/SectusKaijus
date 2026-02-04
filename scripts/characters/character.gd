extends Node2D

signal mouvement_termine(perso_nom, nouvelle_coord)
signal selection(mon_instance)

@export var nom_personnage: String = "Personnage"
@export var couleur_point: Color = Color.WHITE
@export var vitesse: int = 1
@export var coord_actuelle: Vector2i = Vector2i(0, 0)
@export var texture_carte : Texture2D

# Stockage du chemin
var chemin_a_parcourir: Array[Vector2i] = [] 

func _ready():
	# Carré de debug si pas d'image
	if not has_node("ColorRect"):
		var c = ColorRect.new()
		c.name = "ColorRect"
		add_child(c)
	
	$ColorRect.color = couleur_point
	$ColorRect.size = Vector2(50, 50)
	$ColorRect.position = Vector2(-25, -25)
	
	# Gestion du clic
	if has_node("Area2D"):
		if not $Area2D.input_event.is_connected(_on_area_2d_input_event):
			$Area2D.input_event.connect(_on_area_2d_input_event)

func initialiser_position(case_grille: Vector2i, position_monde: Vector2):
	coord_actuelle = case_grille
	global_position = position_monde
	print(nom_personnage + " initialisé en case " + str(case_grille))

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selection.emit(self)

# --- RECEPTION DE L'ORDRE ---
func programmer_itineraire(chemin: Array[Vector2i], _pos_finale_monde: Vector2):
	# On stocke le chemin complet pour les tours futurs
	chemin_a_parcourir = chemin
	print("✅ " + nom_personnage + " a reçu un itinéraire de " + str(chemin.size()) + " cases.")

# --- EXECUTION DU MOUVEMENT (LOGIQUE) ---
func avancer():
	if chemin_a_parcourir.size() > 0:
		# 1. On détermine le nombre de pas possibles (Vitesse)
		var pas_ce_tour = min(vitesse, chemin_a_parcourir.size())
		var nouvelle_case : Vector2i
		
		# 2. On consomme les étapes dans la liste
		for i in range(pas_ce_tour):
			nouvelle_case = chemin_a_parcourir.pop_front()
		
		# 3. Mise à jour de la coordonnée LOGIQUE
		coord_actuelle = nouvelle_case
		
		print(nom_personnage + " se déplace logiquement vers " + str(coord_actuelle))
		mouvement_termine.emit(nom_personnage, coord_actuelle)
	else:
		print(nom_personnage + " n'a pas de chemin ou est arrivé.")

# --- EXECUTION DU MOUVEMENT (VISUEL) ---
func animer_deplacement(nouvelle_pos_monde: Vector2):
	# C'est cette fonction qui fait bouger l'image !
	var tween = create_tween()
	tween.tween_property(self, "global_position", nouvelle_pos_monde, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
