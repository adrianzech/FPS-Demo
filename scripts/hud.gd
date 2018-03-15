extends CanvasLayer

func _ready():
	if global.debug_info:
		$debug.show()
	else:
		$debug.hide()

	global.connect("debug_info_toggled", self, "_on_debug_info_toggled")

func _process(delta):
	if global.debug_info:
		$debug/lbl_fps_counter.text = "fps: " + str(Engine.get_frames_per_second())
		$debug/lbl_max_fps.text = "max_fps: " + str(Engine.target_fps)
		$debug/lbl_velocity.text = "velocity: (" + str(round($"../player".velocity.x)) + ", " + str(round($"../player".velocity.z)) + ")"

func _on_debug_info_toggled():
	if global.debug_info:
		$debug.show()
	else:
		$debug.hide()