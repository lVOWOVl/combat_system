# gem_runtime.gd
# 宝石运行时状态（独立于Resource）

class_name GemRuntime extends RefCounted

var gem_data: GemResource
var is_active: bool = true


## 初始化
## 参数：
##   data: 宝石配置Resource
func setup(data: GemResource) -> void:
	gem_data = data
	is_active = true


## 获取效果
## 返回: 宝石效果（如果未激活返回空字典）
func get_effects() -> Dictionary:
	if not is_active:
		return {}
	return gem_data.effects.duplicate()
