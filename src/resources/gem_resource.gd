# gem_resource.gd
# 宝石配置Resource（仅静态配置）

class_name GemResource extends Resource

@export var gem_name: String = ""
@export var effects: Dictionary = {}         # 效果（如：{"fire_damage": 10.0, "life_steal": 0.05}）
@export var visual_effects: Dictionary = {}  # 视觉特效（如：{"glow_color": Color.ORANGE, "particles": ""}）
