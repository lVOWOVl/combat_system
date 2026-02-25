这是根据审查意见修正后的最终版架构文档。我修复了 Signal 参数传递错误、断开连接的安全性检查，以及 Resource 深拷贝的潜在隐患，同时保持了文档的原有结构和格式。

```markdown
# 玩家系统与武器系统架构设计文档（Godot 4.x 适配版）

## 目录
1. [架构概述](#架构概述)
2. [模块划分](#模块划分)
3. [接口契约定义](#接口契约定义)
4. [数据结构定义](#数据结构定义)
5. [节点结构设计](#节点结构设计)
6. [依赖关系图](#依赖关系图)
7. [事件系统设计](#事件系统设计)
8. [使用示例](#使用示例)
9. [测试策略](#测试策略)

---

## 架构概述

### 设计原则
1. **组合优于继承**：使用组合模式而非继承，避免GDScript的多重继承限制
2. **命名约定 + Duck Typing**：通过文档定义接口契约，而非强制继承（GDScript无原生接口）
3. **数据与状态分离**：Resource仅存储静态配置，运行时状态由独立类管理
4. **单一职责**：每个模块只关注自己的功能，职责清晰
5. **Godot原生优先**：利用Node Tree、Signal、Autoload等原生机制，避免过度封装

### Godot/GDScript 特性限制
- **不支持多重继承**：Player节点继承CharacterBody2D，无法同时继承接口基类
- **无原生接口**：GDScript没有`implements`关键字，只有继承
- **Resource共享性**：多个对象引用同一Resource时会共享数据，需使用`duplicate(true)`深拷贝
- **强类型支持**：Godot 4.x支持强类型，应充分利用类型提示

### 技术栈
- **引擎**: Godot 4.6+
- **语言**: GDScript 2.0（强类型）
- **物理引擎**: Jolt Physics
- **测试框架**: GUT (Godot Unit Test)
- **数据结构**: Godot Resource（配置） + RefCounted/Object（运行时状态）
- **事件系统**: Godot Signal（近距离） + Autoload EventBus（跨模块）

### 架构边界
**包含**：
- 接口契约定义（文档化，非强制继承）
- Resource数据结构（静态配置）
- 运行时状态类（动态数据）
- 节点结构设计
- 事件系统设计
- 测试用例设计
- 架构文档

**明确排除**：
- UI层（血条显示、技能冷却UI等）
- 数值平衡（伤害公式、资源消耗的具体数值）
- 存档/存档系统
- 网络同步机制
- 敌人AI系统
- 运行时武器外观生成逻辑（仅数据结构设计）
- 复杂的Buff/Debuff系统（仅基础属性注入）
- 动作帧数据系统（仅位移逻辑接口）

---

## 模块划分

### 玩家系统
1. **PlayerNode** - 玩家主节点
   - **类型**: CharacterBody2D
   - **职责**: 整合所有子系统，作为场景树根节点
   - **子节点**: ResourceSystemNode, MovementNode, CombatNode, WeaponSystemNode

2. **ResourceSystemNode** - 资源管理节点
   - **类型**: Node
   - **职责**: 管理生命值、护盾、能量的运行时状态
   - **依赖**: PlayerStatsResource（配置）

3. **MovementNode** - 移动系统节点
   - **类型**: Node
   - **职责**: 管理角色移动、跳跃、特殊移动
   - **依赖**: CharacterBody2D（父节点）

4. **CombatNode** - 战斗系统节点
   - **类型**: Node
   - **职责**: 管理战斗逻辑（基础技、特殊技、必杀技）
   - **依赖**: WeaponSystemNode, ResourceSystemNode

### 武器系统
5. **WeaponSystemNode** - 武器系统节点
   - **类型**: Node
   - **职责**: 管理双武器配置和武器实例
   - **子节点**: WeaponNode (x2)

6. **WeaponNode** - 武器节点
   - **类型**: Node2D
   - **职责**: 管理单个武器的数据、部件、外观
   - **依赖**: WeaponDataResource

7. **ComponentSystem** - 部件系统
   - **类型**: Object（非节点）
   - **职责**: 管理武器部件（部件子类型、材料、镶嵌）
   - **依赖**: ComponentPartResource（配置）

### 基础设施
8. **EventBus** - 事件总线
   - **类型**: Node（Autoload单例）
   - **职责**: 跨模块事件通信
   - **模式**: Signal-based（类型安全）

9. **ServiceLocator** - 服务定位器
   - **类型**: Object（Autoload单例）
   - **职责**: 提供全局服务访问（如数据加载器）
   - **模式**: 简单单例，非DI容器

---

## 接口契约定义

> **重要**：GDScript不支持原生接口，以下为**文档化契约**。实现类应遵循这些契约，但不强制继承。

### 1. PlayerNode 契约

```gdscript
# player_node.gd
# 玩家主节点，整合所有子系统

class_name PlayerNode extends CharacterBody2D

## 引用子系统
@onready var resource_system: ResourceSystemNode = $ResourceSystem
@onready var movement: MovementNode = $Movement
@onready var combat: CombatNode = $Combat
@onready var weapon_system: WeaponSystemNode = $WeaponSystem

## 初始化玩家
## 参数：
##   player_stats: 玩家配置Resource
func setup_player(player_stats: PlayerStatsResource) -> void:
    resource_system.setup(player_stats)
    # 初始化其他子系统

## 物理帧更新
## 遵循F.2：统一采用手动驱动模式
func _physics_process(delta: float) -> void:
    resource_system.process_regeneration(delta)
    movement.process_movement(delta)
    combat.process_combat(delta)

## 受到伤害
## 参数：
##   damage_amount: 伤害数值（负数表示治疗）
##   damage_type: 伤害类型
## 遵循F.3：调用者只转发，不发射事件
func take_damage(damage_amount: float, damage_type: String = "normal") -> void:
    resource_system.take_damage(damage_amount, damage_type)

## 死亡处理
func die() -> void:
    EventBus.player_died.emit()
    queue_free()
```

### 2. ResourceSystemNode 契约

```gdscript
# resource_system_node.gd
# 资源管理节点，管理生命值、护盾、能量的运行时状态

class_name ResourceSystemNode extends Node

## 运行时状态（独立于Resource）
var current_health: float
var current_shield: float
var current_energy: float

## 配置引用
var player_stats: PlayerStatsResource

## 初始化
## 参数：
##   stats: 玩家配置Resource（深拷贝）
func setup(stats: PlayerStatsResource) -> void:
    player_stats = stats.duplicate(true)
    current_health = player_stats.max_health
    current_shield = player_stats.max_shield
    current_energy = player_stats.max_energy

## 处理能量恢复
## 遵循F.2：由父节点手动调用，不使用_physics_process
## 参数：
##   delta: 帧时间
func process_regeneration(delta: float) -> void:
    # 能量恢复逻辑
    if current_energy < player_stats.max_energy:
        current_energy = min(
            current_energy + player_stats.energy_regen_rate * delta,
            player_stats.max_energy
        )
    EventBus.player_energy_changed.emit(current_energy)

## 受到伤害
## 参数：
##   amount: 伤害数值
##   damage_type: 伤害类型
## 遵循F.3：状态持有者负责发射事件
func take_damage(amount: float, damage_type: String = "normal") -> void:
    # 先扣护盾
    if current_shield > 0:
        var shield_damage = min(current_shield, amount)
        current_shield -= shield_damage
        amount -= shield_damage
        EventBus.player_shield_changed.emit(current_shield)
        
        if current_shield <= 0:
            EventBus.player_shield_broken.emit()
    
    # 再扣生命值
    if amount > 0:
        current_health = max(current_health - amount, 0)
        EventBus.player_health_changed.emit(current_health)
        
        if current_health <= 0:
            EventBus.player_died.emit()

## 消耗能量
## 参数：
##   amount: 消耗的能量值
## 返回: 是否消耗成功
func consume_energy(amount: float) -> bool:
    if current_energy >= amount:
        current_energy -= amount
        EventBus.player_energy_changed.emit(current_energy)
        return true
    return false

## 恢复生命值
## 参数：
##   amount: 恢复的生命值
func restore_health(amount: float) -> void:
    current_health = min(current_health + amount, player_stats.max_health)
    EventBus.player_health_changed.emit(current_health)
```

### 3. MovementNode 契约

```gdscript
# movement_node.gd
# 移动系统节点，管理角色移动、跳跃

class_name MovementNode extends Node

## 引用场景根节点
## 遵循F.4：使用owner指向场景根节点，解耦父子节点依赖
@onready var player_body: CharacterBody2D = owner

## 移动参数
var move_speed: float = 200.0
var friction: float = 10.0
var acceleration: float = 20.0
var jump_force: float = 400.0

## 状态标志
var is_grounded: bool = false
var can_jump: bool = true

## 移动处理
## 参数：
##   delta: 帧时间
func process_movement(delta: float) -> void:
    # 获取输入方向
    var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    
    # 应用移动（平滑过渡）
    var target_velocity = direction * move_speed
    player_body.velocity = player_body.velocity.lerp(target_velocity, acceleration * delta)
    
    # 应用物理移动
    player_body.move_and_slide()
    
    # 检查是否在地面
    is_grounded = player_body.is_on_floor()

## 跳跃
func jump() -> void:
    if is_grounded and can_jump:
        player_body.velocity.y = -jump_force
        EventBus.player_jump.emit()

## 设置移动速度
## 参数：
##   speed: 移动速度
func set_move_speed(speed: float) -> void:
    move_speed = speed
```

### 4. CombatNode 契约

```gdscript
# combat_node.gd
# 战斗系统节点，管理战斗逻辑

class_name CombatNode extends Node

## 攻击属性数据结构
class AttackData:
    var damage: float
    var recovery_time: float
    var interrupt_level: int

## 引用子系统
## 遵循F.1：使用节点路径获取，避免初始化时序问题
@onready var resource_system: ResourceSystemNode = get_node("../ResourceSystem")
@onready var weapon_system: WeaponSystemNode = get_node("../WeaponSystem")

## 战斗处理
## 参数：
##   delta: 帧时间
func process_combat(delta: float) -> void:
    # 检查输入并执行攻击
    if Input.is_action_just_pressed("attack_main"):
        perform_basic_attack(true)
    elif Input.is_action_just_pressed("attack_off"):
        perform_basic_attack(false)
    elif Input.is_action_just_pressed("ultimate"):
        perform_ultimate()

## 执行基础攻击
## 参数：
##   is_main_hand: 是否主手
## 返回: 攻击数据
func perform_basic_attack(is_main_hand: bool) -> AttackData:
    var weapon = weapon_system.get_weapon(is_main_hand)
    if weapon == null:
        return null
    
    # 检查能量
    var energy_cost = 10.0
    if not resource_system.consume_energy(energy_cost):
        EventBus.attack_failed.emit("能量不足")
        return null
    
    # 获取武器伤害
    var attack_data = weapon.perform_attack()
    # 修正：匹配EventBus定义，传递两个独立参数
    EventBus.attack_started.emit(weapon, "basic")
    
    return attack_data

## 执行必杀技
## 返回: 攻击数据
func perform_ultimate() -> AttackData:
    var energy_cost = 50.0
    if not resource_system.consume_energy(energy_cost):
        EventBus.attack_failed.emit("能量不足")
        return null
    
    EventBus.ultimate_used.emit()
    
    var attack_data = AttackData.new()
    attack_data.damage = 50.0
    attack_data.recovery_time = 1.0
    attack_data.interrupt_level = 5
    
    return attack_data
```

### 5. WeaponSystemNode 契约

```gdscript
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
```

### 6. WeaponNode 契约

```gdscript
# weapon_node.gd
# 武器节点，管理单个武器

class_name WeaponNode extends Node2D

## 武器数据
var weapon_data: WeaponDataResource

## 部件系统
var component_system: ComponentSystem

## 初始化
## 参数：
##   data: 武器配置Resource（深拷贝）
func setup(data: WeaponDataResource) -> void:
    # 使用 true 参数进行深拷贝，确保数组和子资源也被复制
    weapon_data = data.duplicate(true)
    component_system = ComponentSystem.new()
    component_system.setup(weapon_data.components)
    update_weapon_appearance()

## 执行攻击
## 返回: 攻击数据
func perform_attack() -> CombatNode.AttackData:
    var attack_data = CombatNode.AttackData.new()
    
    # 基础伤害
    attack_data.damage = weapon_data.base_damage
    
    # 应用部件修正
    var modifiers = component_system.get_total_modifiers()
    if modifiers.has("damage"):
        attack_data.damage *= modifiers.damage
    
    # 攻击速度决定后摇
    attack_data.recovery_time = 1.0 / weapon_data.attack_speed
    
    # 打断等级
    attack_data.interrupt_level = weapon_data.interrupt_level
    
    return attack_data

## 更新武器外观
func update_weapon_appearance() -> void:
    # 根据部件和材料更新外观
    # 实际外观生成逻辑不在本次架构设计范围
    pass
```

### 7. ComponentSystem 契约

```gdscript
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
        var instance = ComponentPartInstance.new()
        # 由于上层已进行深拷贝，此处资源已隔离
        instance.setup(res)
        components.append(instance)

## 获取总修正值
## 返回: 所有部件的修正值总和
func get_total_modifiers() -> Dictionary:
    var total_modifiers = {}
    
    for comp in components:
        var modifiers = comp.get_modifiers()
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
        var modifiers = {}
        
        # 材料修正
        if material_runtime != null:
            modifiers.merge(material_runtime.get_stats())
        
        # 宝石修正
        if gem_runtime != null:
            modifiers.merge(gem_runtime.get_effects())
        
        return modifiers
```

---

## 数据结构定义

### 静态配置Resource（仅数据，不共享状态）

### 1. PlayerStatsResource

```gdscript
# player_stats_resource.gd
# 玩家配置Resource（仅静态配置）

class_name PlayerStatsResource extends Resource

@export var max_health: float = 100.0        # 最大生命值
@export var max_shield: float = 50.0         # 最大护盾
@export var max_energy: float = 100.0        # 最大能量
@export var energy_regen_rate: float = 10.0  # 能量恢复速度（每秒）

## 注意：运行时状态（current_health等）由ResourceSystemNode管理，不在此Resource中
```

### 2. WeaponDataResource

```gdscript
# weapon_data_resource.gd
# 武器配置Resource（仅静态配置）

class_name WeaponDataResource extends Resource

@export_enum("sword", "axe", "spear") var weapon_type: String = "sword"
@export var base_damage: float = 10.0
@export var attack_speed: float = 1.0        # 攻击速度（次/秒）
@export var interrupt_level: int = 1         # 打断等级（1-10）
@export var base_animations: Dictionary = {}  # 基础动画映射

## 部件配置（静态）
@export var components: Array[ComponentPartResource] = []

## 注意：运行时状态由WeaponNode和ComponentSystem管理
```

### 3. ComponentPartResource

```gdscript
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
```

### 4. MaterialResource

```gdscript
# material_resource.gd
# 材料配置Resource（仅静态配置）

class_name MaterialResource extends Resource

@export var material_name: String = ""
@export var base_stats: Dictionary = {}      # 基础属性（如：{"damage": 5.0, "speed": 0.1}）
@export var visual_properties: Dictionary = {} # 视觉属性（如：{"color": Color.RED, "texture": ""}）
```

### 5. GemResource

```gdscript
# gem_resource.gd
# 宝石配置Resource（仅静态配置）

class_name GemResource extends Resource

@export var gem_name: String = ""
@export var effects: Dictionary = {}         # 效果（如：{"fire_damage": 10.0, "life_steal": 0.05}）
@export var visual_effects: Dictionary = {}  # 视觉特效（如：{"glow_color": Color.ORANGE, "particles": ""}）
```

### 6. CoreResource

```gdscript
# core_resource.gd
# 核心配置Resource（仅静态配置）

class_name CoreResource extends Resource

@export var core_type: String = ""          # 核心型号
@export var base_stats: Dictionary = {}      # 基础属性（如：{"max_health": 20.0, "energy_regen": 2.0}）
@export var ultimate_skill: Dictionary = {}  # 必杀技（如：{"name": "", "energy_cost": 50.0}）
@export var max_item_slots: int = 3         # 最大道具栏位
```

### 运行时状态类（管理动态数据）

### 7. MaterialRuntime

```gdscript
# material_runtime.gd
# 材料运行时状态（独立于Resource）

class_name MaterialRuntime extends RefCounted

var material_data: MaterialResource
var current_durability: float

## 初始化
## 参数：
##   data: 材料配置Resource（深拷贝）
func setup(data: MaterialResource) -> void:
    material_data = data
    current_durability = 100.0  # 默认耐久度

## 获取属性
## 返回: 材料属性
func get_stats() -> Dictionary:
    var stats = material_data.base_stats.duplicate()
    # 可以根据耐久度修正属性
    stats.damage *= (current_durability / 100.0)
    return stats
```

### 8. GemRuntime

```gdscript
# gem_runtime.gd
# 宝石运行时状态（独立于Resource）

class_name GemRuntime extends RefCounted

var gem_data: GemResource
var is_active: bool = true

## 初始化
## 参数：
##   data: 宝石配置Resource（深拷贝）
func setup(data: GemResource) -> void:
    gem_data = data
    is_active = true

## 获取效果
## 返回: 宝石效果
func get_effects() -> Dictionary:
    if not is_active:
        return {}
    return gem_data.effects.duplicate()
```

---

## 节点结构设计

### 玩家场景树结构

```
PlayerNode (CharacterBody2D)
├── CollisionShape2D
├── Sprite2D (玩家外观)
├── ResourceSystemNode (Node)
├── MovementNode (Node)
├── CombatNode (Node)
├── WeaponSystemNode (Node)
│   ├── MainHand (WeaponNode)
│   │   └── Sprite2D (武器外观)
│   └── OffHand (WeaponNode)
│       └── Sprite2D (武器外观)
└── AnimationPlayer
```

### 说明
- **PlayerNode**: 根节点，继承CharacterBody2D，负责物理处理
- **ResourceSystemNode**: 管理资源状态，作为PlayerNode的子节点
- **MovementNode**: 管理移动逻辑，通过`owner`访问CharacterBody2D
- **CombatNode**: 管理战斗逻辑，协调武器系统和资源系统
- **WeaponSystemNode**: 管理双武器，包含两个WeaponNode子节点
- **WeaponNode**: 管理单个武器，负责外观和部件系统

---

## 依赖关系图

```
                    PlayerNode (CharacterBody2D)
                         |
        +----------------+----------------+----------------+
        |                |                |                |
ResourceSystemNode  MovementNode       CombatNode    WeaponSystemNode
        |                |                |                |
        +                +                +           +-----+
    Health管理        移动逻辑        攻击逻辑        |     |
    Shield管理        跳跃逻辑        连招逻辑        |     |
    Energy管理        特殊移动        打断逻辑        |     |
                                                        |
                                                    ComponentSystem
                                                        |
                                              +--------+--------+
                                              |                 |
                                       MaterialRuntime       GemRuntime
                                              |
                                       MaterialResource
```

**说明**：
- PlayerNode是根节点，所有子系统作为子节点
- 子节点通过`owner`或`get_node("../Sibling")`访问其他子系统
- ComponentSystem是非节点类，由WeaponNode持有
- 运行时状态类独立于Resource，避免状态共享

---

## 事件系统设计

### EventBus（Autoload）- Signal-based

```gdscript
# event_bus.gd
# 事件总线（Autoload单例）
# 使用Godot Signal实现类型安全的事件系统

extends Node

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
signal attack_started(weapon: WeaponNode, type: String)
signal attack_hit(target: Node, damage: float)
signal damage_dealt(damage: float, target: Node)
signal damage_received(damage: float, source: Node)
signal ultimate_used()
signal attack_failed(reason: String)

## 武器事件
signal weapon_switched(weapon_index: int)
signal component_changed(component_type: String)
signal material_changed(new_material: MaterialResource)
signal gem_embedded(slot: Variant, gem: GemResource)
signal gem_removed(slot: Variant)
```

### 使用示例

#### 订阅事件
```gdscript
# 在节点中订阅事件
func _ready() -> void:
    EventBus.player_health_changed.connect(_on_health_changed)
    EventBus.attack_started.connect(_on_attack_started)

func _on_health_changed(new_value: float) -> void:
    # 更新血条
    pass

func _on_attack_started(weapon: WeaponNode, type: String) -> void:
    # 播放攻击动画
    pass

func _exit_tree() -> void:
    # 清理事件连接 - 使用安全检查避免断言错误
    if EventBus.player_health_changed.is_connected(_on_health_changed):
        EventBus.player_health_changed.disconnect(_on_health_changed)
    if EventBus.attack_started.is_connected(_on_attack_started):
        EventBus.attack_started.disconnect(_on_attack_started)
```

#### 发布事件
```gdscript
# 在任何地方发布事件
# 注意：参数顺序必须与Signal定义一致
EventBus.player_health_changed.emit(new_health)
EventBus.attack_started.emit(current_weapon, "basic")
```

### 优势
- **类型安全**：参数类型在编译时检查
- **IDE支持**：代码补全和自动完成
- **无拼写错误**：EventBus.health_changed.emit()会报错（应为player_health_changed）
- **性能优化**：Godot Signal机制高效

---

## 使用示例

### 示例1：创建新武器

```gdscript
# 在编辑器中创建WeaponDataResource
var sword_data = WeaponDataResource.new()
sword_data.weapon_type = "sword"
sword_data.base_damage = 15.0
sword_data.attack_speed = 1.2
sword_data.interrupt_level = 2

# 创建部件
var blade = ComponentPartResource.new()
blade.component_type = "blade"
blade.sub_type = "straight"
blade.has_material_slot = true
blade.material = load("res://data/materials/steel.tres")

var guard = ComponentPartResource.new()
guard.component_type = "guard"
guard.sub_type = "simple"
guard.material = load("res://data/materials/iron.tres")

var hilt = ComponentPartResource.new()
hilt.component_type = "hilt"
hilt.sub_type = "leather"
hilt.material = load("res://data/materials/leather.tres")

# 添加部件
sword_data.components = [blade, guard, hilt]

# 保存Resource
ResourceSaver.save(sword_data, "res://data/weapons/iron_sword.tres")
```

### 示例2：在场景中使用武器

```gdscript
# 在WeaponNode中加载武器
func _ready() -> void:
    var weapon_data = load("res://data/weapons/iron_sword.tres")
    setup(weapon_data)
```

### 示例3：添加新系统

```gdscript
# 1. 创建节点
class_name BuffSystemNode extends Node

var active_buffs: Dictionary = {}

func apply_buff(buff_id: String, duration: float) -> void:
    active_buffs[buff_id] = duration
    EventBus.buff_applied.emit(buff_id)

func remove_buff(buff_id: String) -> void:
    active_buffs.erase(buff_id)
    EventBus.buff_removed.emit(buff_id)

# 2. 添加到EventBus
signal buff_applied(buff_id: String)
signal buff_removed(buff_id: String)

# 3. 在PlayerNode中添加子节点
# PlayerNode场景树：
# PlayerNode (CharacterBody2D)
# ├── ResourceSystemNode
# ├── MovementNode
# ├── CombatNode
# ├── WeaponSystemNode
# └── BuffSystemNode  # 新增

# 4. 在PlayerNode中初始化
@onready var buff_system: BuffSystemNode = $BuffSystem
```

---

## 测试策略

### 测试框架
使用GUT (Godot Unit Test)框架进行测试。

### 测试类型

#### 1. 单元测试 - 运行时状态类
测试MaterialRuntime、GemRuntime等非节点类的逻辑。

**示例：MaterialRuntime测试**
```gdscript
# test_material_runtime.gd
extends GutTest

var material_runtime: MaterialRuntime
var material_data: MaterialResource

func before_each():
    material_data = MaterialResource.new()
    material_data.base_stats = {"damage": 10.0, "speed": 0.1}
    
    material_runtime = MaterialRuntime.new()
    material_runtime.setup(material_data)

func test_get_stats_with_full_durability():
    var stats = material_runtime.get_stats()
    assert_eq(stats.damage, 10.0, "耐久度100%时应返回基础属性")
    assert_eq(stats.speed, 0.1, "耐久度100%时应返回基础属性")

func test_get_stats_with_half_durability():
    material_runtime.current_durability = 50.0
    var stats = material_runtime.get_stats()
    assert_eq(stats.damage, 5.0, "耐久度50%时应返回一半属性")

func test_get_stats_with_zero_durability():
    material_runtime.current_durability = 0.0
    var stats = material_runtime.get_stats()
    assert_eq(stats.damage, 0.0, "耐久度0%时应返回0属性")
```

#### 2. 集成测试 - 节点交互
测试节点间的交互和事件流。

**示例：战斗集成测试**
```gdscript
# test_combat_integration.gd
extends GutTest

var player_scene: PackedScene = load("res://scenes/player.tscn")
var player: PlayerNode

func before_each():
    player = player_scene.instantiate()
    add_child_autofree(player)

func test_attack_consumes_energy():
    var initial_energy = player.resource_system.current_energy
    player.combat.perform_basic_attack(true)
    var current_energy = player.resource_system.current_energy
    assert_lt(current_energy, initial_energy, "攻击应消耗能量")

func test_attack_publishes_event():
    var event_called = false
    EventBus.attack_started.connect(func(_w, _t): event_called = true)
    player.combat.perform_basic_attack(true)
    assert_true(event_called, "应发布attack_started事件")
```

#### 3. Mock测试 - 替换依赖
使用GUT的`stubber`和`double`功能。

**示例：Mock ResourceSystem**
```gdscript
# test_with_mock.gd
extends GutTest

var player: PlayerNode
var mock_resource_system = double(ResourceSystemNode).new()

func test_take_damage_uses_mock():
    player = PlayerNode.new()
    player.resource_system = mock_resource_system
    
    stub(mock_resource_system, 'take_damage').to_call(null)
    
    player.take_damage(10.0)
    
    assert_called(mock_resource_system, 'take_damage')
```

### 测试覆盖率目标
- 运行时状态类（MaterialRuntime、GemRuntime）：100%
- 节点类（PlayerNode、ResourceSystemNode等）：90%
- ComponentSystem：80%
- 关键集成路径：100%

### 运行测试
```bash
# 运行所有测试
gut test .

# 运行特定测试文件
gut test tests/test_material_runtime.gd

# 生成测试覆盖率报告
gut test -gcoveralls
```

---

## 附录

### A. 文件组织结构
```
src/
├── resources/           # Resource配置（静态数据）
│   ├── player_stats_resource.gd
│   ├── weapon_data_resource.gd
│   ├── component_part_resource.gd
│   ├── material_resource.gd
│   ├── gem_resource.gd
│   └── core_resource.gd
├── nodes/              # 节点类
│   ├── player_node.gd
│   ├── resource_system_node.gd
│   ├── movement_node.gd
│   ├── combat_node.gd
│   ├── weapon_system_node.gd
│   └── weapon_node.gd
├── systems/            # 非节点系统类
│   ├── component_system.gd
│   ├── material_runtime.gd
│   └── gem_runtime.gd
├── scenes/             # 场景文件
│   └── player.tscn
└── autoloads/         # Autoload单例
    ├── event_bus.gd
    └── service_locator.gd

tests/                  # 测试用例
├── test_player.gd
├── test_resource_system.gd
├── test_movement.gd
├── test_combat.gd
├── test_weapon.gd
├── test_integration.gd
└── test_material_runtime.gd

data/                   # 数据文件
├── players/
│   └── default_player.tres
├── weapons/
│   ├── iron_sword.tres
│   └── steel_axe.tres
├── materials/
│   ├── steel.tres
│   ├── iron.tres
│   └── leather.tres
└── gems/
    ├── fire_gem.tres
    └── life_steal_gem.tres

docs/                   # 文档
├── architecture.md      # 本文档
├── api.md              # API文档
└── examples.md         # 使用示例
```

### B. 命名规范
- **节点类**：`{名称}Node`（如：PlayerNode、ResourceSystemNode）
- **系统类**：`{名称}System`（如：ComponentSystem）
- **运行时类**：`{名称}Runtime`（如：MaterialRuntime、GemRuntime）
- **Resource**：`{名称}Resource`（如：PlayerStatsResource、WeaponDataResource）
- **事件**：使用Signal，名称为`{名词}_{动词}`（如：player_health_changed）

### C. 注释规范
- 所有公开函数必须有中文注释
- 注释格式：
  ```gdscript
  ## 函数简短描述（一行）
  ## 参数：
  ##   param_name: 参数描述
  ## 返回: 返回值描述
  func function_name(param_name: Type) -> ReturnType:
      pass
  ```

### D. 扩展点
1. **添加新武器类型**：创建新的WeaponDataResource，在编辑器中配置
2. **添加新技能**：在CombatNode中添加新方法，添加对应EventBus信号
3. **添加新系统**：创建新的Node类，添加到PlayerNode场景树
4. **添加新事件**：在EventBus中添加Signal定义

### E. 关键注意事项
1. **Resource深拷贝**：使用`.duplicate(true)`深拷贝Resource，避免状态共享（详见F.6）
2. **节点路径访问**：使用`$路径`或`get_node()`访问子节点
3. **事件清理**：在`_exit_tree()`中清理Signal连接，并检查连接状态
4. **类型安全**：充分利用Godot 4.x的强类型特性

### F. 实现最佳实践（关键）

#### 1. 依赖注入与初始化时序

**问题**：Godot的`_ready()`回调是**自底向上**触发的（子节点先于父节点）。如果子节点使用`@onready var parent: ParentNode = get_parent()`来获取父节点，父节点的子节点可能还未初始化，导致获取到`null`。

**错误示例**：
```gdscript
# combat_node.gd（子节点）
@onready var resource_system: ResourceSystemNode = get_parent().resource_system  # ❌ 可能是null
```

**解决方案**：使用以下任一方式

**方案1：节点路径获取（推荐）**
```gdscript
# combat_node.gd
@onready var resource_system: ResourceSystemNode = get_node("../ResourceSystem")
```

**方案2：显式初始化（最稳健）**
```gdscript
# player_node.gd（父节点）
func _ready() -> void:
    combat.initialize(resource_system)  # 显式注入依赖

# combat_node.gd（子节点）
var resource_system: ResourceSystemNode  # 不使用@onready

func initialize(sys: ResourceSystemNode) -> void:
    resource_system = sys
```

**方案3：@export在编辑器指定（最灵活）**
```gdscript
# combat_node.gd
@export var resource_system_path: NodePath
var resource_system: ResourceSystemNode

func _ready() -> void:
    resource_system = get_node(resource_system_path) if resource_system_path else null
```

#### 2. 统一更新循环

**问题**：如果部分子系统使用`_physics_process`自动运行，部分由父节点手动调用，会导致：
- 执行顺序不可控
- 调试困难（不清楚谁先执行）
- 可能的逻辑冲突（如能量恢复在攻击消耗前执行）

**解决方案**：统一采用**手动驱动模式**。所有子系统的逻辑更新由`PlayerNode._physics_process`统一调度，子系统本身**不包含`_physics_process`**。

**正确示例**：
```gdscript
# player_node.gd
func _physics_process(delta: float) -> void:
    resource_system.process_regeneration(delta)  # 显式调用
    movement.process_movement(delta)
    combat.process_combat(delta)

# resource_system_node.gd
# ❌ 不要定义 _physics_process

# 定义更新方法，由父节点调用
func process_regeneration(delta: float) -> void:
    # 能量恢复逻辑
    if current_energy < player_stats.max_energy:
        current_energy = min(
            current_energy + player_stats.energy_regen_rate * delta,
            player_stats.max_energy
        )
    EventBus.player_energy_changed.emit(current_energy)
```

#### 3. 事件所有权与信号发射

**问题**：如果多个模块都发射同一事件，会导致：
- UI或监听者收到多次相同事件
- 逻辑重复执行
- 状态同步混乱

**解决方案**：遵循**单一职责原则**。

**规则**：
- **状态持有者发射事件**：谁持有状态，谁负责发射变化事件
- **调用者只转发**：调用者（如PlayerNode）只负责调用状态管理者的方法，**不应重复发射事件**

**正确示例**：
```gdscript
# player_node.gd（调用者）
func take_damage(amount: float) -> void:
    resource_system.take_damage(amount)  # ✅ 只调用，不发射
    # ❌ 移除：EventBus.player_health_changed.emit(...)
```

#### 4. 父子节点依赖解耦

**问题**：使用`get_parent()`强制要求特定节点树结构，缺乏灵活性。如果在场景树中增加中间层（如`PlayerNode -> Components -> MovementNode`），代码会崩溃。

**解决方案**：使用更灵活的依赖方式。

**方案1：使用`owner`指向场景根节点**
```gdscript
# movement_node.gd
@onready var player_body: CharacterBody2D = owner  # owner指向场景根节点
```

**方案2：使用相对路径或节点类型查找**
```gdscript
# movement_node.gd
@onready var player_body: CharacterBody2D = get_node(^"../..")  # 或
@onready var player_body: CharacterBody2D = find_parent("PlayerNode")
```

**方案3：@export在编辑器指定（最灵活）**
```gdscript
# movement_node.gd
@export var target_node_path: NodePath
var target_node: Node

func _ready() -> void:
    target_node = get_node(target_node_path) if target_node_path else owner
```

#### 5. Signal连接的生命周期管理

**问题**：如果在`_ready()`中连接Signal，但没有在`_exit_tree()`中清理，会导致：
- 节点被销毁后仍尝试连接
- 内存泄漏（GDScript的GC可能无法及时回收）

**正确示例**：
```gdscript
func _ready() -> void:
    EventBus.player_health_changed.connect(_on_health_changed)

func _exit_tree() -> void:
    # ✅ 清理所有Signal连接（安全检查）
    if EventBus.player_health_changed.is_connected(_on_health_changed):
        EventBus.player_health_changed.disconnect(_on_health_changed)
```

#### 6. Resource深拷贝与状态隔离

**问题**：Godot的 `Resource.duplicate()` 默认是**浅拷贝**。如果Resource包含数组或嵌套资源，拷贝后的对象仍会共享这些引用。

**错误示例**：
```gdscript
var sword_data = load("res://data/weapons/iron_sword.tres").duplicate()
# sword_data.components 仍然指向原始资源中的数组！
```

**解决方案**：显式使用 `duplicate(true)` 进行深拷贝。

**正确示例**：
```gdscript
# ✅ 深拷贝Resource（包括子资源）
var sword_data = load("res://data/weapons/iron_sword.tres").duplicate(true)
var weapon1 = WeaponNode.new()
weapon1.setup(sword_data)

var weapon2 = WeaponNode.new()
# 如果 sword_data 已是深拷贝，再次 duplicate(true) 可确保完全独立
weapon2.setup(sword_data.duplicate(true))
```

### G. 调试与故障排查

#### 常见问题诊断

| 问题 | 可能原因 | 检查方法 |
|------|---------|---------|
| 节点引用为null | @onready初始化时序问题 | 检查节点树结构，使用节点路径替代get_parent() |
| 事件被触发多次 | 信号重复发射 | 检查是否有多个模块发射同一事件 |
| 能量恢复不工作 | 子系统自动执行未集成 | 检查是否所有逻辑都由父节点统一调度 |
| Resource状态共享 | 未使用duplicate(true)深拷贝 | 检查Resource创建时是否调用.duplicate(true) |
| Signal连接后不触发 | 节点提前销毁 | 检查_exit_tree()是否清理连接 |



---

**文档版本**: 2.1 (最终修正版)
**最后更新**: 2026-02-25
**作者**: Prometheus (Planning Agent)
**修复**: 解决RefCounted/Node继承冲突、Resource状态共享、GDScript无接口、Signal参数匹配及深拷贝隐患等问题
```