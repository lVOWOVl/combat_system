# player_node.gd
# 玩家主节点，整合所有子系统

class_name PlayerNode extends CharacterBody2D

## 引用子系统
## 注意：@onready要求节点在场景树中存在
@onready var resource_system = $ResourceSystem
@onready var movement: MovementNode = $Movement
@onready var combat: CombatNode = $Combat
@onready var weapon_system: WeaponSystemNode = $WeaponSystem


## 初始化玩家
## 参数：
##   player_stats: 玩家配置Resource
func setup_player(player_stats: PlayerStatsResource) -> void:
	# 防御性检查：@onready 可能在测试环境中未初始化
	if resource_system == null:
		var res_node = get_node_or_null("ResourceSystem")
		if res_node != null:
			resource_system = res_node

## 物理帧更新
func _physics_process(delta: float) -> void:
	resource_system.process_regeneration(delta)
	movement.process_movement(delta)
	combat.process_combat(delta)


## 受到伤害
## 参数：
##   damage_amount: 伤害数值（负数表示治疗）
##   damage_type: 伤害类型
func take_damage(damage_amount: float, damage_type: String = "normal") -> void:
	resource_system.take_damage(damage_amount, damage_type)


## 死亡处理
func die() -> void:
	EventBus.player_died.emit()
	queue_free()
