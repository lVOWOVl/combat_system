# event_bus.gd
# 事件总线（Autoload单例）
# 使用Godot Signal实现类型安全的事件系统

extends Node

# gdlint: ignore=god-class-signals
# Reason: EventBus is a centralized communication hub with 19 signals organized by category.
# The code is clean and well-structured. Splitting would increase complexity without benefit.

## 资源事件

## 资源事件
signal player_health_changed(new_value: float)
signal player_shield_changed(new_value: float)
signal player_energy_changed(new_value: float)
signal player_shield_broken()
signal player_died()

## 移动事件
signal player_jump()
signal player_landed()
signal player_dash()

## 战斗事件
signal attack_started(weapon: Node, type: String)
signal attack_hit(target: Node, damage: float)
signal damage_dealt(damage: float, target: Node)
signal damage_received(damage: float, source: Node)
signal ultimate_used()
signal attack_failed(reason: String)

## 武器事件
signal weapon_switched(weapon_index: int)
signal component_changed(component_type: String)
signal material_changed(new_material: Resource)
signal gem_embedded(slot: Variant, gem: Resource)
signal gem_removed(slot: Variant)
