# test_resource_system.gd
# ResourceSystemNode单元测试

extends gut_test

## 测试常量
const DEFAULT_MAX_HEALTH: float = 100.0
const DEFAULT_MAX_SHIELD: float = 50.0
const DEFAULT_MAX_ENERGY: float = 100.0
const DEFAULT_ENERGY_REGEN_RATE: float = 10.0

var resource_system: ResourceSystemNode

var resource_system: ResourceSystemNode
var test_stats: PlayerStatsResource


func before_each() -> void:
	# 创建测试数据
	test_stats = PlayerStatsResource.new()
	test_stats.max_health = DEFAULT_MAX_HEALTH
	test_stats.max_shield = DEFAULT_MAX_SHIELD
	test_stats.max_energy = DEFAULT_MAX_ENERGY
	test_stats.energy_regen_rate = DEFAULT_ENERGY_REGEN_RATE
	# 创建测试数据
	test_stats = PlayerStatsResource.new()
	test_stats.max_health = 100.0
	test_stats.max_shield = 50.0
	test_stats.max_energy = 100.0
	test_stats.energy_regen_rate = 10.0

	# 创建ResourceSystem实例
	resource_system = ResourceSystemNode.new()
	add_child_autofree(resource_system)


func test_setup() -> void:
	# 测试初始化
	resource_system.setup(test_stats)

	assert_eq(resource_system.current_health, DEFAULT_MAX_HEALTH)
	assert_eq(resource_system.current_shield, DEFAULT_MAX_SHIELD)
	assert_eq(resource_system.current_energy, DEFAULT_MAX_ENERGY)
	assert_eq(resource_system.current_shield, 50.0)
	assert_eq(resource_system.current_energy, 100.0)


func test_take_damage_health_only() -> void:
	# 测试纯伤害（无护盾）
	resource_system.setup(test_stats)
	resource_system.take_damage(30.0, "normal")

	assert_eq(resource_system.current_health, 70.0)
	assert_eq(resource_system.current_shield, 50.0)


func test_take_damage_shield_absorbed() -> void:
	# 测试护盾吸收伤害
	resource_system.setup(test_stats)
	resource_system.take_damage(30.0, "normal")

	assert_eq(resource_system.current_shield, 20.0)
	assert_eq(resource_system.current_health, 100.0)  # 生命值未受影响


func test_take_damage_both_shield_and_health() -> void:
	# 测试伤害超过护盾
	resource_system.setup(test_stats)
	resource_system.take_damage(70.0, "normal")

	assert_eq(resource_system.current_shield, 0.0)
	assert_eq(resource_system.current_health, 80.0)  # 100 - (70 - 50)


func test_take_damage_lethal() -> void:
	# 测试致命伤害
	resource_system.setup(test_stats)
	# 模拟Signal连接
	watch_signals(EventBus)
	resource_system.take_damage(200.0, "normal")

	assert_eq(resource_system.current_health, 0.0)
	assert_signal_emitted(EventBus, "player_died")


func test_consume_energy_success() -> void:
	# 测试能量消耗成功
	resource_system.setup(test_stats)
	var result: bool = resource_system.consume_energy(30.0)

	assert_true(result)
	assert_eq(resource_system.current_energy, 70.0)


func test_consume_energy_insufficient() -> void:
	# 测试能量不足
	resource_system.setup(test_stats)
	var result: bool = resource_system.consume_energy(150.0)

	assert_false(result)
	assert_eq(resource_system.current_energy, DEFAULT_MAX_ENERGY)  # 能量未变


func test_restore_health() -> void:
	# 测试恢复生命值
	resource_system.setup(test_stats)
	resource_system.take_damage(30.0, "normal")
	resource_system.restore_health(20.0)

	assert_eq(resource_system.current_health, 90.0)


func test_restore_health_overflow() -> void:
	# 测试恢复超过最大值
	resource_system.setup(test_stats)
	resource_system.take_damage(30.0, "normal")
	resource_system.restore_health(100.0)

	assert_eq(resource_system.current_health, DEFAULT_MAX_HEALTH)  # 不超过最大值


func test_energy_regen() -> void:
	# 测试能量恢复
	resource_system.setup(test_stats)
	resource_system.consume_energy(50.0)
	resource_system.process_regeneration(1.0)

	assert_eq(resource_system.current_energy, 60.0)  # 50 + 10.0 * 1.0


func test_energy_regen_max_limit() -> void:
	# 测试能量恢复上限
	resource_system.setup(test_stats)
	resource_system.consume_energy(5.0)
	resource_system.process_regeneration(1.0)

	assert_eq(resource_system.current_energy, DEFAULT_MAX_ENERGY)  # 不超过最大值


func after_each() -> void:
	# 清理
	if is_instance_valid(test_stats):
		test_stats.free()
