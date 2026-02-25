# component_system.gd
# 部件系统，管理武器部件

class_name ComponentSystem extends RefCounted

## 部件实例
var components: Array[ComponentPartInstance] = []


## 初始化
## 参数：
##   component_resources: 部件配置Resource数组（已由上层深拷贝）
func setup(component_resources: Array[ComponentPartResource]) -> void:
	for res in component_resources:
		var instance: ComponentPartInstance = ComponentPartInstance.new()
		# 由于上层已进行深拷贝，此处资源已隔离
		instance.setup(res)
		components.append(instance)


## 获取总修正值
## 返回: 所有部件的修正值总和
func get_total_modifiers() -> Dictionary:
	var total_modifiers: Dictionary = {}

	for comp in components:
		var modifiers: Dictionary = comp.get_modifiers()
		for key in modifiers:
			if not total_modifiers.has(key):
				total_modifiers[key] = modifiers[key]
			else:
				total_modifiers[key] += modifiers[key]

	return total_modifiers


## 部件实例类
class ComponentPartInstance extends RefCounted:
	var component_resource: ComponentPartResource
	var material_runtime: MaterialRuntime
	var gem_runtime: GemRuntime

	## 初始化
	## 参数：
	##   res: 部件配置Resource
	func setup(res: ComponentPartResource) -> void:
		component_resource = res

		# 创建运行时材料实例
		if res.has_material_slot and res.material != null:
			material_runtime = MaterialRuntime.new()
			# 再次深拷贝子资源以确保完全独立
			material_runtime.setup(res.material.duplicate(true))

		# 创建运行时宝石实例
		if res.has_gem_slot and res.gem != null:
			gem_runtime = GemRuntime.new()
			gem_runtime.setup(res.gem.duplicate(true))

	## 获取修正值
	## 返回: 修正值字典
	func get_modifiers() -> Dictionary:
		var modifiers: Dictionary = {}

		# 材料修正
		if material_runtime != null:
			modifiers.merge(material_runtime.get_stats())

		# 宝石修正
		if gem_runtime != null:
			modifiers.merge(gem_runtime.get_effects())

		return modifiers
