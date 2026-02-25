# weapon_node.gd
# 武器节点，管理单个武器

class_name WeaponNode extends Node2D

## 武器数据
var weapon_data: WeaponDataResource

## 部件系统
var component_system: ComponentSystem


## 初始化
## 参数：
##   data: 武器配置Resource（深拷贝）
func setup(data: WeaponDataResource) -> void:
	# 使用 true 参数进行深拷贝，确保数组和子资源也被复制
	weapon_data = data.duplicate(true)
	component_system = ComponentSystem.new()
	component_system.setup(weapon_data.components)
	update_weapon_appearance()


## 执行攻击
## 返回: 攻击数据
func perform_attack() -> CombatNode.AttackData:
	var attack_data: AttackData = CombatNode.AttackData.new()

	# 基础伤害
	attack_data.damage = weapon_data.base_damage

	# 应用部件修正
	var modifiers: Dictionary = component_system.get_total_modifiers()
	if modifiers.has("damage"):
		attack_data.damage *= modifiers.damage

	# 攻击速度决定后摇
	attack_data.recovery_time = 1.0 / weapon_data.attack_speed

	# 打断等级
	attack_data.interrupt_level = weapon_data.interrupt_level

	return attack_data


## 更新武器外观
func update_weapon_appearance() -> void:
	# 根据部件和材料更新外观
	# 实际外观生成逻辑不在本次架构设计范围
	pass
