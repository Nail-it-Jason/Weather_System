extends Camera3D

@export_group("Control Speeds")
@export var rotation_speed: float = 2.0
@export var vertical_speed: float = 20.0
@export var sun_speed: float = 30.0

# get the Node
@onready var atmosphere: Node = $"../AtmosphereManager"

# current euler angle
var yaw: float = 0.0
var pitch: float = 0.0

func _ready():
	yaw = rotation.y
	pitch = rotation.x

func _process(delta):
	# W: head up
	if Input.is_key_pressed(KEY_W):
		pitch += rotation_speed * delta
	# S: head down
	if Input.is_key_pressed(KEY_S):
		pitch -= rotation_speed * delta
	# A: look left
	if Input.is_key_pressed(KEY_A):
		yaw += rotation_speed * delta
	# D: look right
	if Input.is_key_pressed(KEY_D):
		yaw -= rotation_speed * delta
		
	pitch = clamp(pitch, -PI/2.0, PI/2.0)
	
	# apply to camera
	rotation = Vector3(pitch, yaw, 0.0)

	## E: go upward
	#if Input.is_key_pressed(KEY_E):
		#position.y += vertical_speed * delta
	## Q: downward
	#if Input.is_key_pressed(KEY_Q):
		#position.y -= vertical_speed * delta
		#position.y = max(position.y, 1.0) 

	if atmosphere:
		var earth_radius_km = 6360.0 
		# unit change to kilometer
		var camera_height_km = position.y / 1000.0 
		atmosphere.view_height = earth_radius_km + camera_height_km
		# sun angle (Elevation)
		if Input.is_key_pressed(KEY_UP):
			atmosphere.sun_elevation += sun_speed * delta
		if Input.is_key_pressed(KEY_DOWN):
			atmosphere.sun_elevation -= sun_speed * delta
		#if Input.is_key_pressed(KEY_LEFT):
			#atmosphere.sun_azimuth -= sun_speed * delta
		#if Input.is_key_pressed(KEY_RIGHT):
			#atmosphere.sun_azimuth += sun_speed * delta
		
		atmosphere.sun_elevation = clamp(atmosphere.sun_elevation, -10.0, 90.0)
