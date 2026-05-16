extends Node3D

@export var speed: float = 15.0 # 鸟的飞行速度
@export var max_distance: float = 1000.0 # 飞出多远后销毁

var fly_direction: Vector3 = Vector3.FORWARD

@onready var anim_player: AnimationPlayer = $AnimationPlayer 

func _ready():
	if anim_player:
		var anim_list = anim_player.get_animation_list()
		
		for anim_name in anim_list:
			if anim_name != "RESET":
				# 1. 获取这个动画的数据
				var anim = anim_player.get_animation(anim_name)
				# 2. 【关键修复】强制把这个动画改成“无限循环”模式！
				anim.loop_mode = Animation.LOOP_LINEAR
				# 3. 播放它！
				anim_player.play(anim_name)
				
				
				break # 找到并播放后就退出循环

func _process(delta):
	# 按照方向和速度往前飞
	global_translate(fly_direction * speed * delta)
	
	# 飞太远就自我销毁
	if global_position.length() > max_distance:
		queue_free()
