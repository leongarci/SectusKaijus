extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayerIris
@onready var iris: TextureRect = $Iris

func transition_to(scene: PackedScene) -> void:
	# pivot centre
	iris.pivot_offset = iris.size * 0.5

	# ferme
	anim.play("close")
	await anim.animation_finished

	# change scène pendant que c'est fermé
	get_tree().change_scene_to_packed(scene)

	# ouvre
	anim.play("open")
	await anim.animation_finished

	queue_free()
