extends Control

# Signal envoyé quand le joueur a fini de lire tous les dialogues
signal fin_dialogue

# --- DONNÉES ---
var Echec = [
	"Quelle manque cruel d'efficacité... Médiocre !!!",
	"Les membres de la secte ont échoué à 3 missions... Sous vos ordres !",
	"La secte est désormais repérée... Attendez demain pour que la ville se calme",
	"J'attends bien mieux, Titouan, je place de grands espoirs en vous !",
    "N'oubliez pas, vos cultistes sont... différents. Bon courage"
]

var etape_actuelle = 0

# Assure-toi que les noeuds existent bien dans ta scène avec ces noms exacts
@onready var label_texte = $TexteETD
@onready var bouton_suite = $BoutonSuiteETD
@onready var fond_dialogue = $DialETD

func _ready():
	# Connexion sécurisée
	if not bouton_suite.pressed.is_connected(_on_bouton_suite_pressed):
		bouton_suite.pressed.connect(_on_bouton_suite_pressed)
	
	arrondir_le_fond()
	
	# On lance le premier texte après un petit délai
	await get_tree().create_timer(0.5).timeout
	afficher_texte_anime()

func arrondir_le_fond():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.8)
	style.set_corner_radius_all(25)
	if fond_dialogue:
		fond_dialogue.add_theme_stylebox_override("panel", style)

func afficher_texte_anime():
	if etape_actuelle >= Echec.size():
		return

	var texte_a_afficher = Echec[etape_actuelle]
	label_texte.text = texte_a_afficher
	
	bouton_suite.disabled = true
	
	var tween = create_tween()
	tween.tween_property(label_texte, "modulate:a", 1.0, 0.5).from(0.0)
	
	var duree_ecriture = texte_a_afficher.length() * 0.03
	tween.parallel().tween_property(label_texte, "visible_ratio", 1.0, duree_ecriture).from(0.0)
	
	await tween.finished
	bouton_suite.disabled = false 

func _on_bouton_suite_pressed():
	# Effet de sortie
	var tween_sortie = create_tween()
	tween_sortie.tween_property(label_texte, "modulate:a", 0.0, 0.5)
	await tween_sortie.finished
	
	etape_actuelle += 1
	
	if etape_actuelle < Echec.size():
		afficher_texte_anime()
	else:
		terminer_sequence()

func terminer_sequence():
	# Au lieu de changer de scène, on prévient scene_test
	fin_dialogue.emit()
	# On se supprime proprement
	queue_free()
