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

# Appelé AVANT le _ready par scene_test
func setup(_day_from: int, _day_to: int, _perks: Array[String], _subtitle := "Nouveau jour !") -> void:
	day_from = _day_from
	day_to = _day_to
	perks = _perks
	subtitle_text = _subtitle

func _ready() -> void:
	ok_button.disabled = true
	ok_button.visible = true # S'assurer qu'il est visible
	
	if not ok_button.pressed.is_connected(_on_ok_pressed):
		ok_button.pressed.connect(_on_ok_pressed)

	day_label.text = "Jour %d" % day_from
	subtitle.text = subtitle_text
	day_label.custom_minimum_size.y = max(day_label.custom_minimum_size.y, 40)

	_populate_perks(perks)
	_play_sequence()

func _play_sequence() -> void:
	if anim.has_animation("intro"):
		anim.play("intro")
		await anim.animation_finished

	if anim.has_animation("sun_cycle"):
		anim.play("sun_cycle")
		await anim.animation_finished
	else:
		_set_day_to()

	ok_button.disabled = false
	if ok_button.is_inside_tree():
		ok_button.grab_focus()

func _set_day_to() -> void:
	day_label.text = "Jour %d" % day_to

func _on_ok_pressed() -> void:
	ok_button.disabled = true
	confirmed.emit(day_to)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	
	await tween.finished
	queue_free()

func _populate_perks(list: Array[String]) -> void:
	for c in perks_box.get_children():
		c.queue_free()

	for p in list:
		var lbl := Label.new()
		lbl.text = "• " + p
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		perks_box.add_child(lbl)
