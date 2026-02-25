# resource_system_node.gd
# 资源管理节点，管理生命值、护盾、能量的运行时状态

class_name ResourceSystemNode extends Node

## 运行时状态（独立于Resource）
var current_health: float
var current_shield: float
var current_energy: float

## 配置引用
var player_stats: PlayerStatsResource


## 初始化
## 参数：
##   stats: 玩家配置Resource（深拷贝）
func setup(stats: PlayerStatsResource) -> void:
	player_stats = stats.duplicate(true)
	current_health = player_stats.max_health
	current_shield = player_stats.max_shield
	current_energy = player_stats.max_energy


## 处理能量恢复
## 遵循F.2：由父节点手动调用，不使用_physics_process
## 参数：
##   delta: 帧时间
func process_regeneration(delta: float) -> void:
	# 能量恢复逻辑
	if current_energy < player_stats.max_energy:
		current_energy = min(
			current_energy + player_stats.energy_regen_rate * delta,
			player_stats.max_energy
		)
	EventBus.player_energy_changed.emit(current_energy)


## 受到伤害
## 参数：
##   amount: 伤害数值
##   damage_type: 伤害类型
## 遵循F.3：状态持有者负责发射事件
func take_damage(amount: float, _damage_type: String = "normal") -> void:
	# 先扣护盾
	if current_shield > 0:
		var shield_damage: float = min(current_shield, amount)
		current_shield -= shield_damage
		amount -= shield_damage
		EventBus.player_shield_changed.emit(current_shield)

		if current_shield <= 0:
			EventBus.player_shield_broken.emit()

	# 再扣生命值
	if amount > 0:
		current_health = max(current_health - amount, 0)
		EventBus.player_health_changed.emit(current_health)

		if current_health <= 0:
			EventBus.player_died.emit()


## 消耗能量
## 参数：
##   amount: 消耗的能量值
## 返回: 是否消耗成功
func consume_energy(amount: float) -> bool:
	if current_energy >= amount:
		current_energy -= amount
		EventBus.player_energy_changed.emit(current_energy)
		return true
	return false


## 恢复生命值
## 参数：
##   amount: 恢复的生命值
func restore_health(amount: float) -> void:
	current_health = min(current_health + amount, player_stats.max_health)
	EventBus.player_health_changed.emit(current_health)
