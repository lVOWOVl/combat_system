extends Node2D

@export var drone: Node3D               # 无人机节点（SubViewport 内）
@export var sprite: Sprite2D            # 显示无人机的 Sprite2D

@export var yaw_range: float = 90.0     # 偏航范围（度），鼠标从左到右对应 ±yaw_range/2
@export var pitch_range: float = 30.0   # 俯仰范围（度），鼠标从上到下对应 ±pitch_range/2

func _process(_delta):
	if not drone or not sprite:
		return

	# 获取鼠标在精灵上的局部坐标
	var local_mouse = sprite.get_local_mouse_position()
	var tex_size = sprite.texture.get_size()
	if tex_size == Vector2.ZERO:
		return

	# 归一化到 [-1, 1]
	var offset_x = (local_mouse.x / tex_size.x) * 2.0 - 1.0
	var offset_y = (local_mouse.y / tex_size.y) * 2.0 - 1.0
	offset_x = clamp(offset_x, -1.0, 1.0)
	offset_y = clamp(offset_y, -1.0, 1.0)

	# 映射到角度（度）
	var target_yaw = offset_x * yaw_range * 0.5
	var target_pitch = offset_y * pitch_range * -0.5

	# 直接设置旋转（初始旋转为 0）
	drone.rotation.y = deg_to_rad(target_yaw)
	drone.rotation.x = deg_to_rad(target_pitch)
	drone.rotation.z = 0  # 保持滚转为 0
