extends TextureButton

# On définit la taille normale et la taille "cliquée" (95%)
const ECHELLE_NORMALE = Vector2(1.0, 1.0)
const ECHELLE_CLIC = Vector2(0.95, 0.95)

func _ready():
	# 1. LE PIVOT (Très important)
	# Pour que le bouton rétrécisse vers son CENTRE et pas vers le coin haut-gauche,
	# on place le point de pivot pile au milieu de l'image.
	pivot_offset = size / 2
	
	# 2. COULEUR DE BASE
	# On le met très légèrement gris pour qu'il puisse devenir "Blanc éclatant" au survol
	modulate = Color(0.9, 0.9, 0.9, 1)
	
	# 3. CONNEXION AUTOMATIQUE (Pas besoin de le faire dans l'éditeur !)
	mouse_entered.connect(_on_survol_debut)
	mouse_exited.connect(_on_survol_fin)
	button_down.connect(_on_clic_enfonce)
	button_up.connect(_on_clic_relache)

# --- EFFET DE SURVOL (LUMIÈRE) ---

func _on_survol_debut():
	# On passe à une couleur > 1 (Surtension) pour un effet brillant
	# Si ça fait trop flash, mets juste Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.3, 1), 0.1)

func _on_survol_fin():
	# Retour au gris léger
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.9, 0.9, 0.9, 1), 0.1)

# --- EFFET DE CLIC (TAILLE) ---

func _on_clic_enfonce():
	# Le bouton rétrécit rapidement
	var tween = create_tween()
	tween.tween_property(self, "scale", ECHELLE_CLIC, 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _on_clic_relache():
	# Le bouton reprend sa taille avec un petit rebond (Elastic)
	var tween = create_tween()
	tween.tween_property(self, "scale", ECHELLE_NORMALE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
