# component_part_resource.gd
# 部件配置Resource（仅静态配置）
class_name ComponentPartResource extends Resource

@export var component_type: String = ""     # 部件类型（如：blade、guard、hilt）
@export var sub_type: String = ""            # 子类型（如：straight、curved、serrated）
@export var has_material_slot: bool = true   # 是否有材料插槽
@export var has_gem_slot: bool = false       # 是否有宝石插槽

## 材料和宝石配置（静态引用）
@export var material: MaterialResource = null
@export var gem: GemResource = null

## 注意：运行时状态由ComponentPartInstance管理
