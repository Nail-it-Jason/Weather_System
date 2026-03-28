extends Camera3D

@export var rotation_speed: float = 2.5
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rot_x = 0.0 # Pitch
	var rot_y = 0.0 # Left/Right

	if Input.is_key_pressed(KEY_W): rot_x -= 1.0 # W: head down
	if Input.is_key_pressed(KEY_S): rot_x += 1.0 # S: head up
	if Input.is_key_pressed(KEY_A): rot_y += 1.0 # A: look left
	if Input.is_key_pressed(KEY_D): rot_y -= 1.0 # D: look right

	if rot_y != 0.0:
		rotate_y(rot_y * rotation_speed * delta)

	if rot_x != 0.0:
		rotate_object_local(Vector3.RIGHT, -rot_x * rotation_speed * delta)

	# Lock in -90~90
	rotation.x = clamp(rotation.x, -PI/2 + 0.05, PI/2 - 0.05)
	
	rotation.z = 0.0
