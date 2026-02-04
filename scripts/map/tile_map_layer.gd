extends TileMapLayer

@onready var selection_highlight = $SelectionHighlight
@onready var lieu_label = $"../CanvasLayer/PanelContainer/LieuLabel" # Ajuste le chemin selon ton arbre

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var global_mouse_pos = get_global_mouse_position()
		var tile_pos = local_to_map(to_local(global_mouse_pos))
		var data = get_cell_tile_data(tile_pos)
		
		if data:
			var nom = data.get_custom_data("nom_lieu")
			
			# 1. Gérer le surlignage
			selection_highlight.visible = true
			# map_to_local nous donne le centre exact de l'hexagone
			selection_highlight.position = map_to_local(tile_pos)
			
			# 2. Gérer le texte
			if nom != "":
				lieu_label.text = "Lieu : " + nom
			else:
				lieu_label.text = "Terrain vague"
				# Optionnel : masquer le contour si c'est vide
				# selection_highlight.visible = false 
		else:
			# Si on clique hors de la map
			selection_highlight.visible = false
			lieu_label.text = "---"
