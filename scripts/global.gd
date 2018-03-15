extends Node

signal debug_info_toggled(debug_info)

var debug_info = true setget debug_info_toggled

func debug_info_toggled(new_value):
	debug_info = new_value
	emit_signal("debug_info_toggled")