# movement_node.gd
# 移动系统节点，管理角色移动、跳跃

class_name MovementNode extends Node

## 引用场景根节点
## 遵循F.4：使用owner指向场景根节点，解耦父子节点依赖
@onready var player_body: CharacterBody2D = owner

## 移动常量
const DEFAULT_MOVE_SPEED: float = 200.0
const DEFAULT_FRICTION: float = 10.0
const DEFAULT_ACCELERATION: float = 20.0
const DEFAULT_JUMP_FORCE: float = 400.0

## 移动参数
var move_speed: float = DEFAULT_MOVE_SPEED
var friction: float = DEFAULT_FRICTION
var acceleration: float = DEFAULT_ACCELERATION
var jump_force: float = DEFAULT_JUMP_FORCE

## 状态标志
var is_grounded: bool = false
var can_jump: bool = true


## 移动处理
## 参数：
##   delta: 帧时间
func process_movement(delta: float) -> void:
	# 获取输入方向
	var direction: Vector2 = Vector2.ZERO
	
	# 检查 InputMap 是否存在输入操作
	if InputMap.has_action("move_left"):
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# 应用移动（平滑过渡）
	var target_velocity: Vector2 = direction * move_speed
	player_body.velocity = player_body.velocity.lerp(target_velocity, acceleration * delta)

	# 应用物理移动
	player_body.move_and_slide()

	# 检查是否在地面
	is_grounded = player_body.is_on_floor()

## 跳跃
func jump() -> void:
	if is_grounded and can_jump:
		player_body.velocity.y = -jump_force
		EventBus.player_jump.emit()


## 设置移动速度
## 参数：
##   speed: 移动速度
func set_move_speed(speed: float) -> void:
	move_speed = speed
