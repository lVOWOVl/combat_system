extends Node3D

# 悬停参数
@export var hover_amplitude: float = 0.15       # 起伏幅度（米）
@export var hover_frequency: float = 1.0         # 起伏频率（Hz）

# 机身自旋/倾斜参数（度数）
@export var tilt_amplitude: float = 3.0          # 倾斜幅度（度）
@export var tilt_frequency: float = 0.6          # 倾斜频率（Hz）


# 记录初始位置和旋转
var initial_position: Vector3
var initial_rotation: Vector3

func _ready():
	initial_position = position
	initial_rotation = rotation_degrees

func _process(delta):
	var time = Time.get_ticks_msec() / 1000.0   # 秒为单位的时间

	# 1. 悬停起伏（Y轴上下）
	var hover_offset = sin(time * hover_frequency * TAU) * hover_amplitude
	position.y = initial_position.y + hover_offset

	# 2. 机身自旋/倾斜（绕Z轴轻微摆动，也可改为绕X或Y）
	var tilt_offset = sin(time * tilt_frequency * TAU) * tilt_amplitude
	rotation_degrees.z = initial_rotation.z + tilt_offset
