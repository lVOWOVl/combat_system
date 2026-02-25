# attack_data.gd
# 攻击数据结构

class_name AttackData extends RefCounted

## 伤害值
var damage: float = 0.0
## 恢复时间（秒）
var recovery_time: float = 0.0
## 打断等级（1-10）
var interrupt_level: int = 0
