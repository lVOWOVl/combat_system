# core_resource.gd
# 核心配置Resource（仅静态配置）

class_name CoreResource extends Resource

@export var core_type: String = ""          # 核心型号
@export var base_stats: Dictionary = {}      # 基础属性（如：{"max_health": 20.0, "energy_regen": 2.0}）
@export var ultimate_skill: Dictionary = {}  # 必杀技（如：{"name": "", "energy_cost": 50.0}）
@export var max_item_slots: int = 3         # 最大道具栏位
