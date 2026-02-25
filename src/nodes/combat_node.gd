# combat_node.gd
# 战斗系统节点，管理战斗逻辑

class_name CombatNode extends Node

## 战斗常量
const BASIC_ATTACK_ENERGY_COST: float = 10.0
const ULTIMATE_ENERGY_COST: float = 50.0
const ULTIMATE_BASE_DAMAGE: float = 50.0
const ULTIMATE_INTERRUPT_LEVEL: int = 5

## 引用子系统
## 遵循F.1：使用节点路径获取，避免初始化时序问题
@onready var resource_system: ResourceSystemNode = get_node("../ResourceSystem")
@onready var weapon_system: WeaponSystemNode = get_node("../WeaponSystem")


## 战斗处理
## 参数：
##   delta: 帧时间
func process_combat(_delta: float) -> void:
	# 检查输入并执行攻击
	if InputMap.has_action("attack_main") and Input.is_action_just_pressed("attack_main"):
		perform_basic_attack(true)
	elif InputMap.has_action("attack_off") and Input.is_action_just_pressed("attack_off"):
		perform_basic_attack(false)
	elif InputMap.has_action("ultimate") and Input.is_action_just_pressed("ultimate"):
		perform_ultimate()

## 执行基础攻击
## 参数：
##   is_main_hand: 是否主手
## 返回: 攻击数据
func perform_basic_attack(is_main_hand: bool) -> AttackData:
	var weapon: WeaponNode = weapon_system.get_weapon(is_main_hand)
	if weapon == null:
		return null

	var energy_cost: float = BASIC_ATTACK_ENERGY_COST
	if not resource_system.consume_energy(energy_cost):
		EventBus.attack_failed.emit("能量不足")
		return null

	# 获取武器伤害
	var attack_data: AttackData = weapon.perform_attack()
	EventBus.attack_started.emit(weapon, "basic")

	return attack_data


## 执行必杀技
## 返回: 攻击数据
func perform_ultimate() -> AttackData:
	var energy_cost: float = ULTIMATE_ENERGY_COST
	if not resource_system.consume_energy(energy_cost):
		EventBus.attack_failed.emit("能量不足")
		return null

	EventBus.ultimate_used.emit()

	var attack_data: AttackData = AttackData.new()
	attack_data.damage = ULTIMATE_BASE_DAMAGE
	attack_data.recovery_time = 1.0
	attack_data.interrupt_level = ULTIMATE_INTERRUPT_LEVEL

	return attack_data
