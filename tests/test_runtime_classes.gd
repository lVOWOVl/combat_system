# test_runtime_classes.gd
# Runtime类单元测试

extends gut_test

var material_runtime: MaterialRuntime
var gem_runtime: GemRuntime
var test_material_data: MaterialResource
var test_gem_data: GemResource


func before_each() -> void:
	# 创建测试数据
	test_material_data = MaterialResource.new()
	test_material_data.material_name = "Iron"
	test_material_data.base_stats = {"damage": 10.0, "speed": 0.2}

	test_gem_data = GemResource.new()
	test_gem_data.gem_name = "Fire Gem"
	test_gem_data.effects = {"fire_damage": 5.0, "life_steal": 0.05}

	# 创建Runtime实例
	material_runtime = MaterialRuntime.new()
	gem_runtime = GemRuntime.new()


func test_material_runtime_setup() -> void:
	# 测试MaterialRuntime初始化
	material_runtime.setup(test_material_data)

	assert_eq(material_runtime.material_data.material_name, "Iron")
	assert_eq(material_runtime.current_durability, 100.0)


func test_material_runtime_get_stats_full_durability() -> void:
	# 测试满耐久度时的属性
	material_runtime.setup(test_material_data)
	var stats: Dictionary = material_runtime.get_stats()

	assert_eq(stats.damage, 10.0)


func test_material_runtime_get_stats_half_durability() -> void:
	# 测试半耐久度时的属性
	material_runtime.setup(test_material_data)
	material_runtime.current_durability = 50.0
	var stats: Dictionary = material_runtime.get_stats()

	assert_eq(stats.damage, 5.0)  # 10.0 * 50.0/100.0


func test_gem_runtime_setup() -> void:
	# 测试GemRuntime初始化
	gem_runtime.setup(test_gem_data)

	assert_eq(gem_runtime.gem_data.gem_name, "Fire Gem")
	assert_true(gem_runtime.is_active)


func test_gem_runtime_get_effects_active() -> void:
	# 测试激活状态下的效果
	gem_runtime.setup(test_gem_data)
	var effects: Dictionary = gem_runtime.get_effects()

	assert_eq(effects.fire_damage, 5.0)
	assert_eq(effects.life_steal, 0.05)


func test_gem_runtime_get_effects_inactive() -> void:
	# 测试未激活状态下的效果
	gem_runtime.setup(test_gem_data)
	gem_runtime.is_active = false
	var effects: Dictionary = gem_runtime.get_effects()

	assert_eq(effects.size(), 0)  # 应该返回空字典


func after_each() -> void:
	# 清理
	if is_instance_valid(material_runtime):
		material_runtime.free()
	if is_instance_valid(gem_runtime):
		gem_runtime.free()
	if is_instance_valid(test_material_data):
		test_material_data.free()
	if is_instance_valid(test_gem_data):
		test_gem_data.free()
