@tool
extends WorldEnvironment

@export var sun_light: DirectionalLight3D
@export_range(2.0, 10.0) var turbidity: float = 2.0

@export var sun_label: Label
@export var turbidity_label: Label
@export var turbidity_slider: HSlider
@export var sun_height_slider: HSlider

var sky_material: ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sky_material = environment.sky.sky_material
	sun_height_slider.value_changed.connect(_on_sun_height_changed)
	_on_sun_height_changed(sun_height_slider.value)
	turbidity_slider.value_changed.connect(_on_turbidity_changed)
	_on_turbidity_changed(turbidity_slider.value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not sun_light:
		return
		
	if not sky_material and environment and environment.sky:
		sky_material = environment.sky.sky_material
		
	if not sky_material:
		return
	# vector sun ray direction from ground to sky
	var sun_dir = -sun_light.global_basis.z.normalized()
	
	sky_material.set_shader_parameter("sun_direction", sun_dir)
	
	if sun_dir.y <= 0.0:
		sun_light.light_energy = 0.0
	else:
		sun_light.light_energy = clamp(sun_dir.y * 5.0, 0.0, 1.0)

	# Appendix A.2
	# calculating a set of Y value
	var A_Y =  0.1787 * turbidity - 1.4630
	var B_Y = -0.3554 * turbidity + 0.4275
	var C_Y = -0.0227 * turbidity + 5.3251
	var D_Y =  0.1206 * turbidity - 2.5771
	var E_Y = -0.0670 * turbidity + 0.3703
	
	# calculating a set of x
	var A_x = -0.0193 * turbidity - 0.2592
	var B_x = -0.0665 * turbidity + 0.0008
	var C_x = -0.0004 * turbidity + 0.2125
	var D_x = -0.0641 * turbidity - 0.8989
	var E_x = -0.0033 * turbidity + 0.0452
	
	# calculating a set of y
	var A_y = -0.0167 * turbidity - 0.2608
	var B_y = -0.0950 * turbidity + 0.0092
	var C_y = -0.0079 * turbidity + 0.2102
	var D_y = -0.0441 * turbidity - 1.6537
	var E_y = -0.0109 * turbidity + 0.0529
	
	# send the values to the shader
	sky_material.set_shader_parameter("perez_A", Vector3(A_Y, A_x, A_y))
	sky_material.set_shader_parameter("perez_B", Vector3(B_Y, B_x, B_y))
	sky_material.set_shader_parameter("perez_C", Vector3(C_Y, C_x, C_y))
	sky_material.set_shader_parameter("perez_D", Vector3(D_Y, D_x, D_y))
	sky_material.set_shader_parameter("perez_E", Vector3(E_Y, E_x, E_y))
	
	# calculate theta_s, the angle between the sun and zenith
	var cos_theta_s = clamp(sun_dir.y, 0.001, 1.0)
	var theta_s = acos(cos_theta_s)
	
	sky_material.set_shader_parameter("theta_s", theta_s)
	# calculate Yz, zenith luminance (Kcd/m^2)
	# Yz = (4.0453 * T - 4.9710) * 
	# tan((4/9 - T/120) * (PI - 2 * theta_s)) + 2.4192
	var chi = (4.0 / 9.0 - turbidity / 120.0) * (PI - 2.0 * theta_s)
	var zenith_Y = (4.0453 * turbidity - 4.9710) * tan(chi) + 2.4192
	
	# Avoid minus values
	zenith_Y = max(zenith_Y, 0.05)
	
	# Calculate xz and yz
	var T2 = turbidity * turbidity
	var theta2 = theta_s * theta_s
	var theta3 = theta2 * theta_s
	
	# xz
	var zenith_x = (
		( 0.0017 * theta3 - 0.0037 * theta2 + 0.0021 * theta_s + 0.0) * T2 +
		(-0.0290 * theta3 + 0.0638 * theta2 - 0.0320 * theta_s + 0.0039) * turbidity +
		( 0.1169 * theta3 - 0.2120 * theta2 + 0.0605 * theta_s + 0.2589)
	)

	# yz
	var zenith_y = (
		( 0.0028 * theta3 - 0.0061 * theta2 + 0.0032 * theta_s + 0.0) * T2 +
		(-0.0421 * theta3 + 0.0897 * theta2 - 0.0415 * theta_s + 0.0052) * turbidity +
		( 0.1535 * theta3 - 0.2676 * theta2 + 0.0667 * theta_s + 0.2669)
	)
	
	sky_material.set_shader_parameter("zenith_Yxy", Vector3(zenith_Y, zenith_x, zenith_y))
	
	var sky_exposure = smoothstep(-0.08, 0.0, sun_dir.y)
	sky_material.set_shader_parameter("exposure", sky_exposure)

# sun height slider function
func _on_sun_height_changed(value: float) -> void:
	sun_label.text = "sun height: " + str(snapped(value, 0.01))
	sun_light.rotation_degrees.x = value * 90.0

# turbidity slider
func _on_turbidity_changed(value: float) -> void:
	turbidity_label.text = "turbidity: " + str(snapped(value, 0.1))
	turbidity = value
