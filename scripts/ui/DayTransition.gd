extends Control

signal confirmed(day_to: int)

@onready var anim: AnimationPlayer = $AnimationPlayerTransi

@onready var day_label: Label = $PanelTransition/VBoxTransition/DayTransiLabel
@onready var subtitle: Label = $PanelTransition/VBoxTransition/SubtitleTransi
@onready var perks_box: VBoxContainer = $PanelTransition/VBoxTransition/AvantagesTransi
@onready var ok_button: TextureButton = $OkButton


var day_from: int = 1
var day_to: int = 2
var perks: Array[String] = []
var subtitle_text: String = "Nouveau jour !"

func setup(_day_from: int, _day_to: int, _perks: Array[String], _subtitle := "Nouveau jour !") -> void:
	day_from = _day_from
	day_to = _day_to
	perks = _perks
	subtitle_text = _subtitle

func _ready() -> void:
	# UI initiale
	ok_button.disabled = true
	ok_button.visible = true
	# On s'assure que le bouton est connecté à la fonction ci-dessous
	if not ok_button.pressed.is_connected(_on_ok_pressed):
		ok_button.pressed.connect(_on_ok_pressed)

	day_label.text = "Jour %d" % day_from
	subtitle.text = subtitle_text

	# Empêcher le saut visuel du label
	day_label.custom_minimum_size.y = max(day_label.custom_minimum_size.y, 40)

	_populate_perks(perks)
	_play_sequence()

func _play_sequence() -> void:
	# 1) Intro
	if anim.has_animation("intro"):
		anim.play("intro")
		await anim.animation_finished

	# 2) Sun cycle
	if anim.has_animation("sun_cycle"):
		anim.play("sun_cycle")
		await anim.animation_finished
	else:
		_set_day_to()

	# 3) Activation du bouton
	ok_button.disabled = false
	ok_button.grab_focus()

func _set_day_to() -> void:
	day_label.text = "Jour %d" % day_to

func _on_ok_pressed() -> void:
	# On désactive pour éviter le double-clic
	ok_button.disabled = true
	
	# 1. On prévient le reste du jeu
	emit_signal("confirmed", day_to)
	
	# 2. Fondu de sortie fluide
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	
	# 3. On supprime la scène une fois fini
	await tween.finished
	queue_free()

func _populate_perks(list: Array[String]) -> void:
	# On vide la liste avant de la remplir
	for c in perks_box.get_children():
		c.queue_free()

	for p in list:
		var lbl := Label.new()
		lbl.text = "• " + p
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		perks_box.add_child(lbl)
