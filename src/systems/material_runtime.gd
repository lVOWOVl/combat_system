# material_runtime.gd
# 材料运行时状态（独立于Resource）
class_name MaterialRuntime extends RefCounted

## 材料常量
const DEFAULT_DURABILITY: float = 100.0
const DURABILITY_MULTIPLIER: float = 100.0

## 材料配置Resource引用
var material_data: MaterialResource
## 当前耐久度（0-100）
var current_durability: float


## 初始化
## 参数：
##   data: 材料配置Resource
func setup(data: MaterialResource) -> void:
	material_data = data
	current_durability = DEFAULT_DURABILITY  # 默认耐久度


## 获取属性
## 返回: 材料属性（根据耐久度修正）
func get_stats() -> Dictionary:
	var stats: Dictionary = material_data.base_stats.duplicate()
	# 根据耐久度修正属性
	stats.damage *= (current_durability / DURABILITY_MULTIPLIER)
	return stats
