extends Node3D

@export var bird_scene: PackedScene
@export var spawn_interval_min: float = 10.0
@export var spawn_interval_max: float = 20.0
@export var spawn_height: float = 50.0
@export var spawn_radius: float = 200.0

var timer: Timer

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# initial 3 birds
	if bird_scene:
		for i in range(3):
			_spawn_bird()
	
	_start_random_timer()

func _start_random_timer():
	var wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	timer.start(wait_time)

func _on_timer_timeout():
	_spawn_bird()
	_start_random_timer() # 鸟生成后，重新开始下一轮倒计时

func _spawn_bird():
		
	var bird = bird_scene.instantiate()
	
	# 【关键修复】：必须先把它加到场景树里，引擎才允许我们修改它的全局坐标系！
	add_child(bird)
	
	# 1. 计算随机出生点
	var random_angle = randf() * TAU 
	var random_dist = randf_range(50.0, spawn_radius)
	
	var spawn_pos = global_position
	spawn_pos.x += cos(random_angle) * random_dist
	spawn_pos.z += sin(random_angle) * random_dist
	spawn_pos.y += randf_range(spawn_height * 0.8, spawn_height * 1.2) 
	
	bird.global_position = spawn_pos
	
	# 2. 计算飞行目标点
	var target_pos = global_position
	target_pos.x += randf_range(-100, 100)
	target_pos.z += randf_range(-100, 100)
	target_pos.y = spawn_pos.y 
	
	# 让鸟看向目标点
	bird.look_at(target_pos, Vector3.UP)
	
	# 3. 如果底层脚本正确挂载，给它推一个往前的速度向量
	if "fly_direction" in bird:
		bird.fly_direction = -bird.global_transform.basis.z.normalized()
	else:
		push_error("错误: 鸟的根节点上没有找到 bird.gd 脚本！")
