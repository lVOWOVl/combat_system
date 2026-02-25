# weapon_system_node.gd
# 武器系统节点，管理双武器配置

class_name WeaponSystemNode extends Node

## 武器引用
@onready var main_hand: WeaponNode = $MainHand
@onready var off_hand: WeaponNode = $OffHand

## 当前武器
var current_weapon_index: int = 0  # 0=主手, 1=副手


## 获取武器
## 参数：
##   is_main_hand: 是否主手
## 返回: 武器节点
func get_weapon(is_main_hand: bool) -> WeaponNode:
	return main_hand if is_main_hand else off_hand


## 获取当前武器
## 返回: 当前武器节点
func get_current_weapon() -> WeaponNode:
	return main_hand if current_weapon_index == 0 else off_hand


## 切换武器
## 参数：
##   is_main_hand: 是否切换到主手
func switch_weapon(is_main_hand: bool) -> void:
	current_weapon_index = 0 if is_main_hand else 1
	EventBus.weapon_switched.emit(current_weapon_index)
