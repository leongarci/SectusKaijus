extends Control

@onready var time_label: Label = $TimeLabel

@onready var mission_list: ItemList = $MissionPanel/MissionBox/MissionList
@onready var mission_hint: Label = $MissionPanel/MissionBox/MissionHint

@onready var time_manager: Node = $"../../TimeManager"
@onready var mission_manager: Node = $"../../MissionManager"

func _ready() -> void:
	# temps
	time_manager.hour_changed.connect(_on_hour_changed)

	# missions
	mission_manager.missions_changed.connect(_refresh_missions)
	mission_list.item_selected.connect(_on_mission_selected)

	# init
	_on_hour_changed(time_manager.day, time_manager.hour)
	_refresh_missions()
	mission_hint.text = "Astuce : les lieux sont cachés tant que la mission n'est pas accomplie"

func _on_hour_changed(day: int, hour: int) -> void:
	time_label.text = "Jour %d - %02dh" % [day, hour]

func _on_next_hour_pressed() -> void:
	time_manager.advance_hour()

func _refresh_missions() -> void:
	mission_list.clear()

	for m in mission_manager.get_missions():
		var title: String = str(m["title"])

		var place_text := "???"
		if bool(m["done"]):
			var revealed := str(m.get("revealed_place", ""))
			if revealed != "":
				place_text = revealed

		var line := "%s  —  Lieu : %s" % [title, place_text]

		# (optionnel) check visuel
		if bool(m["done"]):
			line += " ✔"

		mission_list.add_item(line)

	# Le hint sert juste d'info générale, pas "Lieu : ???"
	mission_hint.text = "Astuce : teste des lieux sur la carte pour révéler où se fait une mission."

func _on_mission_selected(index: int) -> void:
	var m = mission_manager.get_missions()[index]
	mission_hint.text = "Mission sélectionnée : %s" % str(m["title"])
