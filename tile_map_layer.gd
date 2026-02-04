extends TileMapLayer

func _input(event):
	# On détecte le clic gauche
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		# 1. Position de la souris
		var global_mouse_pos = get_global_mouse_position()
		
		# 2. Conversion en coordonnées de grille
		# On utilise 'to_local' car le clic est en position globale (écran)
		var tile_pos = local_to_map(to_local(global_mouse_pos))
		
		# 3. Récupérer les données de la tuile
		# Note : On ne met plus "0" devant tile_pos !
		var tile_data = get_cell_tile_data(tile_pos)
		
		if tile_data:
			# 4. Lire ton Custom Data
			var lieu = tile_data.get_custom_data("nom_lieu")
			
			if lieu != "":
				print("Lieu identifié : ", lieu)
			else:
				print("Case vide en : ", tile_pos)
		else:
			print("Aucune tuile ici.")
