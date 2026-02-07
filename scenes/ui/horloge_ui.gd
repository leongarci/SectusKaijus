extends Control

@onready var aiguille = $Fond/Aiguille
@onready var label_jour = $Fond/LabelJour

func mettre_a_jour_temps(heure: int, jour: int):
	print("rotation")
	# 1. Mise à jour de l'aiguille (Rotation)
	# 24h = 360 degrés (ou 12h = 360, selon votre préférence)
	# Ici on fait un cycle de 24h pour que midi soit en bas ou en haut.
	# Formule : (heure / 24.0) * 360
	
	var rotation_cible = (heure / 24.0) * 360.0 - 57.1
	
	# Animation fluide de l'aiguille
	var tween = create_tween()
	tween.tween_property(aiguille, "rotation_degrees", rotation_cible, 0.5).set_trans(Tween.TRANS_ELASTIC)
	
	# 2. Mise à jour du jour
	label_jour.text = "J-%d" % jour
