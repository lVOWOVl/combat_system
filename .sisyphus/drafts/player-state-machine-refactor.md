# Draft: Player State Machine Refactoring

## Requirements (confirmed)
- **Goal**: Refactor PlayerNode to become a state machine controller
- **Constraints**: Keep existing functionality and node structure intact
- **Architecture**: PlayerNode = state machine, other nodes = state implementers

## Current Architecture Analysis

### Node Structure (from player.tscn)
```
Player (CharacterBody2D) - src/nodes/player_node.gd
├── Body (Sprite2D)
├── Eyes (Sprite2D)
├── CollisionShape2D
├── ResourceSystem (Node) - src/nodes/resource_system_node.gd
├── Movement (Node) - src/nodes/movement_node.gd
├── Combat (Node) - src/nodes/combat_node.gd
└── WeaponSystem (Node) - src/nodes/weapon_system_node.gd
    ├── MainHand (Node2D) - src/nodes/weapon_node.gd
    └── OffHand (Node2D) - src/nodes/weapon_node.gd
```

### Current Call Pattern (from player_node.gd)
```gdscript
func _physics_process(delta: float) -> void:
    resource_system.process_regeneration(delta)
    movement.process_movement(delta)
    combat.process_combat(delta)
```

### Identified State-Like Behaviors
- MovementNode: has `is_grounded`, `can_jump` flags
- CombatNode: checks input and calls attack methods
- ResourceSystemNode: manages resource state

### Method Signatures
- **MovementNode**: `process_movement(delta)`, `jump()`, `set_move_speed(speed)`
- **CombatNode**: `process_combat(delta)`, `perform_basic_attack(is_main_hand)`, `perform_ultimate()`
- **WeaponSystemNode**: `get_weapon(is_main_hand)`, `get_current_weapon()`, `switch_weapon(is_main_hand)`
- **ResourceSystemNode**: `process_regeneration(delta)`, `take_damage(amount, type)`, `consume_energy(amount)`, `restore_health(amount)`

## Research Findings
- **Recommended Pattern**: Node-based State pattern with StateMachine controller and State children
- **Key Principles**:
  - StateMachine as child Node managing transitions via `finished` signals
  - State scripts with `enter()`/`exit()`/`physics_update()` hooks
  - Dependency injection (not hardcoded paths)
  - Signal-based transitions with cleanup in `exit()`
- **Libraries to Reference**:
  - limbonaut/limboai (704★) - Comprehensive HSM for complex AI
  - imjp94/gd-YAFSM (495★) - Visual FSM editor
  - dragonforge-dev/dragonforge-state-machine - Production-ready FSM
- **Common Pitfalls**:
  - Tight coupling via hardcoded paths (use dependency injection)
  - Memory leaks from signal connections (disconnect in exit())
  - State machine inside PlayerNode (use child node instead)
  - Boolean spaghetti (use enum or state reference)
  - Over-engineering simple characters

---

## User Requirements (confirmed)

### State Design
- **主状态机** (PlayerNode的StateMachine子节点):
  - Idle（空闲）
  - Move（移动）
  - Jump（跳跃）
  - Dash（冲刺）
  - AttackBase（攻击总控状态）← 切换到此状态时，信号传递到CombatNode
  - Hurt（受击）
  - Dead（死亡）

- **嵌套状态机** (CombatNode的AttackStateMachine):
  - AttackLight（轻击）
  - AttackHeavy（重击）
  - Ultimate（必杀技）
  - **连招系统**: 在特定攻击窗口内输入可连击

### Attack Flow
1. 主状态机切换到AttackBase状态
2. AttackBase通过信号通知CombatNode激活AttackStateMachine
3. CombatNode的AttackStateMachine管理具体的攻击招式和连招
4. 攻击完成后，AttackBase切换回Idle/Move等其他状态

### Transition Mechanism
- **混合驱动**: 
  - 输入触发状态切换（如按攻击键→AttackBase状态）
  - 动画/动作完成自动切换（如攻击动画结束后→Idle）

### Node Interface
- **状态专属方法**: 每个状态调用对应的节点方法

### Animation Integration
- **VisualController节点**: 新建节点来同步状态并控制每个状态中的动画

### Other Parameters
- **Dash冷却/持续时间**: 自定义（用户需提供具体数值）
- **Dead状态**: 手动重生

### State Design
- **基础状态**: Idle、Move、Jump、Dash、Hurt、Dead
  - ~~Block~~: 用户明确不需要
- **攻击状态**: 在CombatNode内部实现独立的嵌套状态机
  - AttackLight（轻击）
  - AttackHeavy（重击）
  - Ultimate（必杀技）
  - **连招系统**: 在特定攻击窗口内输入特定攻击或必杀技可连击

### Transition Mechanism
- **混合驱动**: 
  - 输入触发状态切换（如按攻击键→Attack状态）
  - 动画/动作完成自动切换（如攻击动画结束后→Idle）

### Node Interface
- **状态专属方法**: 每个状态调用对应的节点方法

### Animation Integration
- **VisualController节点**: 新建节点来同步状态并控制每个状态中的动画

### Other Parameters
- **Dash冷却/持续时间**: 自定义（用户需提供具体数值）
- **Dead状态**: 手动重生

### State Design
- **基础状态**: Idle、Move、Jump、Dash、Hurt、Block、Dead
- **攻击状态**: 在CombatNode内部实现独立的嵌套状态机
  - AttackLight（轻击）
  - AttackHeavy（重击）
  - Ultimate（必杀技）

### Transition Mechanism
- **混合驱动**: 
  - 输入触发状态切换（如按攻击键→Attack状态）
  - 动画/动作完成自动切换（如攻击动画结束后→Idle）

### Node Interface
- **状态专属方法**: 每个状态调用对应的节点方法

### Animation Integration
- **VisualController节点**: 新建节点来同步状态并控制每个状态中的动画
(To be filled by librarian agent)

## Open Questions
- ~~Hurt/Block触发条件~~: 已解决（不需要Block，Hurt被动触发）
- ~~Dash参数~~: 已解决（自定义）
- ~~连招系统~~: 已解决（支持）
- ~~Dead重生~~: 已解决（手动）
- **需要用户提供的数值**:
  - Dash冷却时间（秒）
  - Dash持续时间（秒）
  - 各攻击状态的持续时间/窗口时间
  - 连招时间窗口（秒）
- Hurt状态和Block状态的触发条件？（被动触发？主动防御？）
- Dash状态的冷却时间和持续时间？
- 攻击状态机是否支持连招（combo）？
- Dead状态后的重生逻辑？
- What states does the state machine need? (idle, move, attack, dead, etc.)
- How do states transition? (input-driven, event-driven?)
- Should other nodes expose state-specific methods or maintain their current interface?
- Do we need to preserve backward compatibility with EventBus signals?
- Should state transitions be handled by PlayerNode or delegated to specific nodes?

## Technical Decisions
(To be made during consultation)
