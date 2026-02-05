extends CanvasLayer

# Signal émis quand l'écran est totalement noir
signal ecran_couvert

@onready var anim: AnimationPlayer = $AnimationPlayerTO

# On retire le code dans _ready(). C'est scene_test qui décidera quand le lancer.
func _ready():
	pass 

func couvrir_ecran() -> void:
	# On vérifie si l'animation existe (attention à la majuscule/minuscule de ton anim)
	if anim.has_animation("wipe_down"):
		anim.play("wipe_down")
		await anim.animation_finished
		ecran_couvert.emit() # Dit au chef "C'est bon, c'est noir !"
	else:
		# Sécurité si l'anim n'existe pas ou s'appelle autrement
		push_warning("Animation 'wipe_down' introuvable dans TransitionOverlay.")
		ecran_couvert.emit()

func decouvrir_ecran() -> void:
	# Si tu as une animation "wipe_up", tu peux la mettre ici
	# Pour l'instant, on se contentera de supprimer le noeud depuis le parent
	queue_free()
