extends KinematicBody

var camera_angle      = 0
var mouse_sensitivity = 0.3
var camera_change     = Vector2()

var velocity  = Vector3()
var direction = Vector3()

var has_contact = false

const GRAVITY      = -9.8 * 4
const WALK_SPEED   = 20
const SPRINT_SPEED = 30
const ACCEL        = 2
const DECEL        = 6

const JUMP_HEIGHT  = 15

const MAX_SLOPE_ANGLE = 35

var flying      = false
const FLY_SPEED = 10
const FLY_ACCEL = 2

func _physics_process(delta):
	aim()
	if flying:
		fly(delta)
	else:
		walk(delta)

func _input(event):
	if event is InputEventMouseMotion:
		camera_change = event.relative

func aim():
	if camera_change.length() > 0:
		$head.rotate_y(deg2rad(-camera_change.x * mouse_sensitivity))

		var rotation_angle = -camera_change.y * mouse_sensitivity
		if rotation_angle + camera_angle < 90 and rotation_angle + camera_angle > -90:
			$head/camera.rotate_x(deg2rad(rotation_angle))
			camera_angle += rotation_angle
		camera_change = Vector2()

func walk(delta):
	# reset the direction of the player
	direction = Vector3()

	# get the rotation of the camera
	var aim = $head.get_global_transform().basis

	if Input.is_action_pressed("move_forward"):
		direction -= aim.z
	if Input.is_action_pressed("move_backward"):
		direction += aim.z
	if Input.is_action_pressed("move_left"):
		direction -= aim.x
	if Input.is_action_pressed("move_right"):
		direction += aim.x

	direction.y = 0
	direction = direction.normalized()

	if is_on_floor():
		has_contact = true
		var n = $ray_cast.get_collision_normal()
		var slope_angle = rad2deg(acos(n.dot(Vector3(0, 1, 0))))
		if slope_angle > MAX_SLOPE_ANGLE:
			velocity.y += GRAVITY * delta
	else:
		if !$ray_cast.is_colliding():
			has_contact = false
		velocity.y += GRAVITY * delta

	if has_contact and !is_on_floor():
		move_and_collide(Vector3(0, -1, 0))

	var temp_velocity = velocity
	temp_velocity.y = 0

	var speed
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	var target = direction * speed

	var acceleration
	if direction.dot(temp_velocity) > 0:
		acceleration = ACCEL
	else:
		acceleration = DECEL

	temp_velocity = temp_velocity.linear_interpolate(target, acceleration * delta)

	velocity.x = temp_velocity.x
	velocity.z = temp_velocity.z

	if has_contact and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_HEIGHT
		has_contact = false

	velocity = move_and_slide(velocity, Vector3(0, 1, 0))

func fly(delta):
	# reset the direction of the player
	direction = Vector3()

	# get the rotation of the camera
	var aim = $head/camera.get_global_transform().basis

	if Input.is_action_pressed("move_forward"):
		direction -= aim.z
	if Input.is_action_pressed("move_backward"):
		direction += aim.z
	if Input.is_action_pressed("move_left"):
		direction -= aim.x
	if Input.is_action_pressed("move_right"):
		direction += aim.x

	direction = direction.normalized()

	var target = direction * FLY_SPEED

	velocity = velocity.linear_interpolate(target, FLY_ACCEL * delta)

	move_and_slide(velocity)