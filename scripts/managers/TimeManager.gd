extends Node

signal hour_changed(day: int, hour: int)

var day := 1
var hour := 0

func advance_hour() -> void:
	hour += 1
	if hour >= 24:
		hour = 0
		day += 1
	hour_changed.emit(day, hour)
