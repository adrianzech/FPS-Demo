extends Node

# The maximal framerate at which the application can run
static func max_fps(value):
	Engine.set_target_fps(int(value))

# Change the fov of the camera
static func fov(value):
	console.fov(int(value))