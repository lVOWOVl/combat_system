# weapon_data_resource.gd
# 武器配置Resource（仅静态配置）
class_name WeaponDataResource extends Resource

@export var weapon_type: String = "sword"         # 武器类型
@export var base_damage: float = 10.0            # 基础伤害
@export var attack_speed: float = 1.0            # 攻击速度（次/秒）
@export var interrupt_level: int = 1             # 打断等级（1-10）
@export var components: Array[ComponentPartResource] = []  # 部件配置

# 注意：运行时状态由WeaponNode和ComponentSystem管理
