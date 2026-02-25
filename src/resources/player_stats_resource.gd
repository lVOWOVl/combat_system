# player_stats_resource.gd
# 玩家配置Resource（仅静态配置）
class_name PlayerStatsResource extends Resource

@export var max_health: float = 100.0        # 最大生命值
@export var max_shield: float = 50.0         # 最大护盾
@export var max_energy: float = 100.0        # 最大能量
@export var energy_regen_rate: float = 10.0  # 能量恢复速度（每秒）

## 注意：运行时状态（current_health等）由ResourceSystemNode管理，不在此Resource中
