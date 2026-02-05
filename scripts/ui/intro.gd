extends Control

# --- DONNÉES ---
var histoire = [
	"Bienvenue à Méréville...",
	"Vous êtes Titouan, chef de la terrible secte Sectus Kaijus...",
	"Vous n'avez qu\'un seul objectif : réviller le Kaiju ancestral Angrak pour vous venger de cette ville...",
	"Pour ce faire, vous allez devoir compter sur les membres... pas comme les autres, de votre secte",
	"Bon courage maître Titouan"
]

var etape_actuelle = 0

@onready var label_texte = $TexteHistoire
@onready var bouton_suite = $BoutonSuite
@onready var fond_dialogue = $Dialogue

func _ready():
	# On s'assure que le bouton est connecté
	bouton_suite.pressed.connect(_on_bouton_suite_pressed)
	
	arrondir_le_fond()
	
	# On lance le premier texte après un petit délai
	await get_tree().create_timer(0.5).timeout
	afficher_texte_anime()

func arrondir_le_fond():
	# 1. On crée le style
	var style = StyleBoxFlat.new()
	
	# 2. On définit la couleur (celle de ton ancien ColorRect)
	# Exemple : Noir transparent (R, G, B, Alpha)
	style.bg_color = Color(1.0, 1.0, 1.0, 0.8)
	
	# 3. On arrondit les coins (Rayon en pixels)
	style.set_corner_radius_all(25)
	
	# 4. On applique ce style au Panel "Dialogue"
	# Le Panel utilise le thème "panel" pour son fond
	fond_dialogue.add_theme_stylebox_override("panel", style)

func afficher_texte_anime():
	# 1. On prépare le nouveau texte
	var texte_a_afficher = histoire[etape_actuelle]
	label_texte.text = texte_a_afficher
	
	# 2. On bloque le bouton pendant l'animation pour éviter les bugs
	bouton_suite.disabled = true
	
	# 3. CRÉATION DE L'ANIMATION (TWEEN)
	var tween = create_tween()
	
	# A. FONDU D'ENTRÉE (Transparence 0 -> 1)
	# On dit : "Passe l'alpha (transparence) à 1 en 0.5 seconde"
	tween.tween_property(label_texte, "modulate:a", 1.0, 0.5).from(0.0)
	
	# B. EFFET MACHINE À ÉCRIRE (visible_ratio 0 -> 1)
	# visible_ratio va de 0 (0% du texte) à 1 (100% du texte).
	# On veut que ça tape vite, donc on calcule le temps selon la longueur du texte.
	# Formule : 0.03 seconde par lettre.
	var duree_ecriture = texte_a_afficher.length() * 0.03
	
	# Le "set_parallel(true)" permet de lancer le fondu ET l'écriture en même temps
	# Mais pour faire joli, on veut souvent que l'écriture commence un tout petit peu après le début du fondu
	# Ici, on va les enchaîner légèrement ou les mettre en parallèle selon ton goût.
	
	# On lance l'écriture en partant de 0
	tween.parallel().tween_property(label_texte, "visible_ratio", 1.0, duree_ecriture).from(0.0)
	
	# 4. Quand l'animation est finie
	await tween.finished
	bouton_suite.disabled = false # On réactive le bouton

func _on_bouton_suite_pressed():
	# --- EFFET DE FONDU DE SORTIE (DISPARITION) ---
	var tween_sortie = create_tween()
	# On rend transparent en 0.5s
	tween_sortie.tween_property(label_texte, "modulate:a", 0.0, 0.5)
	await tween_sortie.finished
	
	# --- CHANGEMENT DE TEXTE ---
	etape_actuelle += 1
	
	if etape_actuelle < histoire.size():
		# On lance l'affichage du suivant (qui fera le fondu d'entrée)
		afficher_texte_anime()
	else:
		lancer_jeu()

func lancer_jeu():
	get_tree().change_scene_to_file("res://scenes/test/scene_test.tscn")
