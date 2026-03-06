# test_weapon_system.gd
# WeaponSystem和WeaponNode测试

extends GutTest

var weapon_system: WeaponSystemNode
var main_hand: WeaponNode
var off_hand: WeaponNode

## 创建测试数据（每次调用创建新实例）
func create_test_data() -> WeaponDataResource:
	var weapon_data: WeaponDataResource = WeaponDataResource.new()
	weapon_data.weapon_type = "sword"
	weapon_data.base_damage = 10.0
	weapon_data.attack_speed = 1.0
	weapon_data.interrupt_level = 1

	var component_data: ComponentPartResource = ComponentPartResource.new()
	component_data.component_type = "blade"
	component_data.has_material_slot = true

	var material_data: MaterialResource = MaterialResource.new()
	material_data.material_name = "Iron"
	material_data.base_stats = {"damage": 5.0}

	component_data.material = material_data
	weapon_data.components = [component_data]

	return weapon_data


## 设置武器系统
func setup_weapon_system() -> void:
	weapon_system = WeaponSystemNode.new()
	add_child_autofree(weapon_system)

	var weapon_data: WeaponDataResource = create_test_data()

	main_hand = WeaponNode.new()
	main_hand.name = "MainHand"  # 匹配 @onready 的节点名
	weapon_system.add_child(main_hand)
	main_hand.setup(weapon_data)

	off_hand = WeaponNode.new()
	off_hand.name = "OffHand"  # 匹配 @onready 的节点名
	weapon_system.add_child(off_hand)
	off_hand.setup(weapon_data)


func before_each() -> void:
	setup_weapon_system()


func test_weapon_setup() -> void:
	# 测试武器初始化
	assert_not_null(main_hand.weapon_data)
	assert_eq(main_hand.weapon_data.weapon_type, "sword")


func test_weapon_perform_attack() -> void:
	# 测试武器攻击（创建新数据确保隔离）
	var weapon_data: WeaponDataResource = create_test_data()
	weapon_data.components = []  # 无部件，纯基础伤害

	main_hand.setup(weapon_data)
	var attack_data: AttackData = main_hand.perform_attack()

	assert_not_null(attack_data)
	assert_eq(attack_data.damage, 10.0)  # 基础伤害
	assert_eq(attack_data.recovery_time, 1.0)  # 1.0 / 1.0
	assert_eq(attack_data.interrupt_level, 1)


func test_weapon_with_components() -> void:
	# 测试带部件的武器
	var attack_data: AttackData = main_hand.perform_attack()

	# 材料修正: 10.0 + 5.0 = 15.0
	assert_eq(attack_data.damage, 15.0)


func test_weapon_attack_speed() -> void:
	# 测试攻击速度
	var weapon_data: WeaponDataResource = create_test_data()
	weapon_data.attack_speed = 2.0
	weapon_data.components = []  # 无部件

	main_hand.setup(weapon_data)
	var attack_data: AttackData = main_hand.perform_attack()

	assert_eq(attack_data.recovery_time, 0.5)  # 1.0 / 2.0


func test_weapon_system_get_main_hand() -> void:
	# 测试获取主手武器
	var weapon: WeaponNode = weapon_system.get_weapon(true)
	assert_eq(weapon, main_hand)


func test_weapon_system_get_off_hand() -> void:
	# 测试获取副手武器
	var weapon: WeaponNode = weapon_system.get_weapon(false)
	assert_eq(weapon, off_hand)


func test_weapon_system_switch_weapon() -> void:
	# 测试切换武器
	weapon_system.switch_weapon(false)
	assert_eq(weapon_system.current_weapon_index, 1)

	var current: WeaponNode = weapon_system.get_current_weapon()
	assert_eq(current, off_hand)


func test_weapon_system_switch_back() -> void:
	# 测试切换回主手
	weapon_system.switch_weapon(false)
	weapon_system.switch_weapon(true)
	assert_eq(weapon_system.current_weapon_index, 0)

	var current: WeaponNode = weapon_system.get_current_weapon()
	assert_eq(current, main_hand)


func test_weapon_deep_copy() -> void:
	# 测试武器深拷贝
	var weapon_data1: WeaponDataResource = create_test_data()
	var weapon_data2: WeaponDataResource = weapon_data1.duplicate(true)

	var weapon1: WeaponNode = WeaponNode.new()
	add_child_autofree(weapon1)  # 避免孤儿节点
	weapon1.setup(weapon_data1)

	var weapon2: WeaponNode = WeaponNode.new()
	add_child_autofree(weapon2)  # 避免孤儿节点
	weapon2.setup(weapon_data2)

	# 修改第一个武器的数据
	weapon1.weapon_data.base_damage = 999.0

	# 第二个武器的数据应该不变
	assert_ne(weapon2.weapon_data.base_damage, 999.0)

func test_component_system_modifiers() -> void:
	# 测试部件系统修正值
	var modifiers: Dictionary = main_hand.component_system.get_total_modifiers()

	assert_true(modifiers.has("damage"))
	assert_eq(modifiers.damage, 5.0)


#func after_each() -> void:
	## 清理由GUT自动处理
	#pass
#
#
#func after_all() -> void:
	## 清理
	#if is_instance_valid(weapon_data):
		#weapon_data.free()
	#if is_instance_valid(component_data):
		#component_data.free()
	#if is_instance_valid(material_data):
		#material_data.free()
