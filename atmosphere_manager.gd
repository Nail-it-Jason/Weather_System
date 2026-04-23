@tool
extends Node

# --- 显式节点关联 ---
@export_group("Nodes (节点关联)")
@export var sun_light: DirectionalLight3D  # 拖入你的 DirectionalLight3D
@export var world_env: WorldEnvironment    # 拖入你的 WorldEnvironment

@export_group("Sun Control (太阳控制)")
@export_range(-10.0, 90.0, 0.1) var sun_elevation: float = 15.0 :
	set(v):
		sun_elevation = v
		_update_atmosphere()

@export_range(0.0, 360.0, 0.1) var sun_azimuth: float = 0.0 :
	set(v):
		sun_azimuth = v
		_update_atmosphere()

@export_group("Rendering (渲染设置)")
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
	
	# 1. 角度转弧度
	var el = deg_to_rad(sun_elevation)
	var az = deg_to_rad(sun_azimuth)
	
	# 2. 计算 3D 太阳方向向量 (用于 Shader)
	var sun_dir = Vector3(
		cos(el) * sin(az),
		sin(el),
		cos(el) * cos(az)
	).normalized()

	# 3. 更新所有 2D LUT 材质的参数
	_update_shader_param("MultiScatteringViewPort/MultiScatteringRect", "sun_direction", sun_dir)
	_update_shader_param("SkyViewViewPort/SkyViewRect", "sun_direction", sun_dir)
	_update_shader_param("SkyViewViewPort/SkyViewRect", "view_height", view_height)

	# 4. 更新 3D 天空球 (粉色杀手！)
	if world_env and world_env.environment and world_env.environment.sky:
		var sky_mat = world_env.environment.sky.sky_material
		if sky_mat:
			# 💥 直接从 Viewport 抓取纹理，强行注入 Sky 材质！
			var sky_vp = get_node_or_null("SkyViewViewPort")
			if sky_vp:
				sky_mat.set_shader_parameter("sky_view_lut", sky_vp.get_texture())
			
			sky_mat.set_shader_parameter("exposure", exposure)

	# 5. 同步物理灯光 (DirectionalLight3D)
	if sun_light:
		# 设置灯光方向：让它朝向地心旋转
		sun_light.rotation = Vector3(-el, az, 0)
		
		# 当日落时自动调整灯光能量和颜色
		var energy_mult = clamp(sin(el) * 2.0, 0.0, 1.0)
		sun_light.light_energy = 2.0 * energy_mult
		sun_light.light_color = Color(1.0, 0.9, 0.8).lerp(Color(1.0, 0.4, 0.1), 1.0 - energy_mult)

# 辅助函数：根据路径更新 Shader 参数
func _update_shader_param(path, param, value):
	var node = get_node_or_null(path)
	if node and node.material:
		node.material.set_shader_parameter(param, value)
