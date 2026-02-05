extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/intro.tscn")
	


func _on_quit_button_pressed():
	# 1. On attend 0.2 seconde (le temps que le bouton finisse son animation visuelle)
	await get_tree().create_timer(0.2).timeout
	
	# 2. Maintenant on ferme la boutique
	get_tree().quit()
