extends Control

func _ready():
	# On connecte le signal du bouton
	# Assure-toi que le chemin vers ton bouton est bon ($MenuContainer/BoutonJouer)
	$MenuContainer/BoutonJouer.pressed.connect(_on_bouton_jouer_pressed)

func _on_bouton_jouer_pressed():
	print("Lancement du jeu...")
	# C'est ici qu'on change de scène vers ta scène principale
	get_tree().change_scene_to_file("res://scenes/test/scene_test.tscn")
