extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayerTO

func transition_to(scene: PackedScene) -> void:
	# 1) Ferme l'écran (la coulée descend)
	anim.play("wipe_down")
	await anim.animation_finished

	# 2) Change de scène quand c'est couvert
	get_tree().change_scene_to_file ("res://scenes/ui/EchecTransiDay.tscn")
	
	queue_free()
