# test_player_integration.gd
# PlayerNode集成测试

extends GutTest

var player_scene: PackedScene
var player: PlayerNode


func before_each() -> void:
	# 加载玩家场景
	player_scene = load("res://scenes/player.tscn")
	if player_scene == null:
		# 如果场景加载失败，创建一个简单的PlayerNode用于测试
		player = PlayerNode.new()
		add_child_autofree(player)

		# 手动创建子系统
		var resource_system = ResourceSystemNode.new()
		resource_system.name = "ResourceSystem"
		player.add_child(resource_system)

		var movement = MovementNode.new()
		movement.name = "Movement"
		player.add_child(movement)

		var combat = CombatNode.new()
		combat.name = "Combat"
		player.add_child(combat)

		var weapon_system = WeaponSystemNode.new()
		weapon_system.name = "WeaponSystem"
		player.add_child(weapon_system)

		var main_hand = WeaponNode.new()
		main_hand.name = "MainHand"
		weapon_system.add_child(main_hand)

		var off_hand = WeaponNode.new()
		off_hand.name = "OffHand"
		weapon_system.add_child(off_hand)
	else:
		player = player_scene.instantiate()
		add_child_autofree(player)

	# 设置玩家配置
	var player_stats: PlayerStatsResource = PlayerStatsResource.new()
	player_stats.max_health = 100.0
	player_stats.max_shield = 0.0  # 设置无护盾，确保伤害直接影响生命值
	player_stats.max_energy = 100.0
	player_stats.energy_regen_rate = 10.0
	player.setup_player(player_stats)


func test_player_setup() -> void:
	# 测试玩家初始化
	assert_not_null(player)
	assert_not_null(player.resource_system)


func test_player_health_initialization() -> void:
	# 测试生命值初始化
	assert_eq(player.resource_system.current_health, 100.0)


func test_player_take_damage() -> void:
	# 测试玩家受到伤害
	player.take_damage(20.0, "normal")
	assert_eq(player.resource_system.current_health, 80.0)


func test_player_die() -> void:
	# 测试玩家死亡
	watch_signals(EventBus)
	player.take_damage(200.0, "normal")

	assert_signal_emitted(EventBus, "player_died")


func test_player_physics_process() -> void:
	# 测试物理处理（不报错即可）
	# 模拟一帧更新
	player._physics_process(0.016)
	pass_test("Player physics process completed without errors")


func test_player_subsystems_exist() -> void:
	# 测试子系统是否存在
	assert_not_null(player.resource_system)
	assert_not_null(player.movement)
	assert_not_null(player.combat)
	assert_not_null(player.weapon_system)


func after_each() -> void:
	# 清理由GUT自动处理
	pass


func after_all() -> void:
	# 清理
	if player_scene != null:
		player_scene = null
