extends MeshInstance

func _ready():
	$area.connect("body_entered", self, "_on_area_body_entered")
	$area.connect("body_exited", self, "_on_area_body_exited")

func _on_area_body_entered(body):
	if body.is_in_group("player"):
		body.flying = true

func _on_area_body_exited(body):
	if body.is_in_group("player"):
		body.flying = false