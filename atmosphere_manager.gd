@tool
extends Node

@export_group("Nodes")
@export var sun_light: DirectionalLight3D
@export var world_env: WorldEnvironment

@export_group("Sun Control")
@export_range(-10.0, 90.0, 0.1) var sun_elevation: float = 15.0 :
	set(v):
		sun_elevation = v
		_update_atmosphere()

@export_range(0.0, 360.0, 0.1) var sun_azimuth: float = 0.0 :
	set(v):
		sun_azimuth = v
		_update_atmosphere()

@export_group("Rendering")
@export_range(0.1, 50.0, 0.1) var exposure: float = 15.0 :
	set(v):
		exposure = v
		_update_atmosphere()

@export var view_height: float = 6360.2 :
	set(v):
		view_height = v
		_update_atmosphere()

func _ready():
	_update_atmosphere()

func _update_atmosphere():
	if not is_inside_tree(): return
	
	# switch from deg to rad
	var el = deg_to_rad(sun_elevation)
	var az = deg_to_rad(sun_azimuth)
	
	# sun direction vector
	var sun_dir = Vector3(
		cos(el) * sin(az),
		sin(el),
		cos(el) * cos(az)
	).normalized()

	# update parameters to shaders
	_update_shader_param("MultiScatteringViewPort/MultiScatteringRect", "sun_direction", sun_dir)
	_update_shader_param("SkyViewViewPort/SkyViewRect", "sun_direction", sun_dir)
	_update_shader_param("SkyViewViewPort/SkyViewRect", "view_height", view_height)

	if world_env and world_env.environment and world_env.environment.sky:
		var sky_mat = world_env.environment.sky.sky_material
		if sky_mat:
			var sky_vp = get_node_or_null("SkyViewViewPort")
			if sky_vp:
				sky_mat.set_shader_parameter("sky_view_lut", sky_vp.get_texture())
			
			sky_mat.set_shader_parameter("exposure", exposure)
			
			sky_mat.set_shader_parameter("sun_direction", sun_dir)
			if sun_light:
				sky_mat.set_shader_parameter("sun_color", sun_light.light_color)

	# DirectionalLight3D
	if sun_light:
		sun_light.rotation = Vector3(-el, az, 0)
		
		var energy_mult = clamp(sin(el) * 4.0, 0.0, 1.0)
		
		sun_light.light_energy = lerp(0.2, 2.0, energy_mult)
		
		var sunset_color = Color(1.0, 0.3, 0.05) # 极深的血橙色
		var day_color = Color(1.0, 0.95, 0.9)    # 日常日光白
		sun_light.light_color = day_color.lerp(sunset_color, 1.0 - energy_mult)

# update parameter to certain path of shader
func _update_shader_param(path, param, value):
	var node = get_node_or_null(path)
	if node and node.material:
		node.material.set_shader_parameter(param, value)
