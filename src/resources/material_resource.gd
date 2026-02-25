# material_resource.gd
# 材料配置Resource（仅静态配置）

class_name MaterialResource extends Resource

@export var material_name: String = ""
@export var base_stats: Dictionary = {}      # 基础属性（如：{"damage": 5.0, "speed": 0.1}）
@export var visual_properties: Dictionary = {} # 视觉属性（如：{"color": Color.RED, "texture": ""}）
