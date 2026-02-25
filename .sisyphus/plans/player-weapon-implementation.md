# 玩家系统与武器系统实现工作计划

## TL;DR

> **Quick Summary**: 基于修正后的架构设计文档，实现玩家系统和武器系统。采用组合模式、Signal-based事件系统、数据与状态分离的设计。
> 
> **Deliverables**:
> - EventBus和ServiceLocator（Autoload）
> - 6个Resource数据结构
> - 2个Runtime状态类
> - 6个节点类
> - 1个非节点系统类
> - 1个场景文件
> - GUT测试用例
> 
> **Estimated Effort**: Large
> **Parallel Execution**: YES - 7 waves
> **Critical Path**: Resource → Runtime → ComponentSystem → Nodes → Scene → Tests

---

## Context

### Original Request
基于修正后的架构设计文档生成工作计划，实现玩家系统和武器系统。

### Interview Summary
**Key Discussions**:
- 用户提供修正后的架构文档（v2.1最终版）
- 修复了Signal参数传递错误（从Dictionary改为两个独立参数）
- 添加了Signal连接的安全检查（is_connected）
- 强调了Resource深拷贝使用duplicate(true)
- 补充了6个实现最佳实践

**Architecture Highlights**:
- 组合优于继承，解决GDScript多重继承限制
- 数据与状态分离，Resource仅存储配置，Runtime类管理动态数据
- Signal-based事件系统，类型安全
- 手动驱动更新循环，由PlayerNode统一调度
- 依赖注入使用节点路径，避免@onready时序问题

---

## Work Objectives

### Core Objective
实现玩家系统和武器系统的完整架构，包括基础设施、数据结构、节点类、场景文件和测试用例。

### Concrete Deliverables
- EventBus（Autoload单例）
- ServiceLocator（Autoload单例）
- 6个Resource类：PlayerStatsResource, WeaponDataResource, ComponentPartResource, MaterialResource, GemResource, CoreResource
- 2个Runtime类：MaterialRuntime, GemRuntime
- 6个节点类：PlayerNode, ResourceSystemNode, MovementNode, CombatNode, WeaponSystemNode, WeaponNode
- 1个非节点系统类：ComponentSystem
- 1个场景文件：player.tscn
- 6个测试文件（单元测试+集成测试）

### Definition of Done
- [ ] 所有Resource类定义完成
- [ ] 所有Runtime类定义完成
- [ ] 所有节点类定义完成
- [ ] EventBus和ServiceLocator创建并配置为Autoload
- [ ] 场景文件创建完成
- [ ] 所有测试用例编写完成并可运行
- [ ] 代码遵循实现最佳实践（深拷贝、节点路径、Signal安全检查）

### Must Have
- 完整的Resource定义
- 完整的节点类实现
- Signal-based EventBus
- GUT测试用例
- 遵循最佳实践（duplicate(true)、is_connected检查等）

### Must NOT Have (Guardrails)
- UI层实现
- 具体数值平衡
- 存档系统
- 网络同步
- 敌人AI系统
- 运行时武器外观生成
- 复杂Buff/Debuff系统

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.
> Acceptance criteria requiring "user manually tests/confirms" are FORBIDDEN.

### Test Decision
- **Infrastructure exists**: YES (GUT framework installed)
- **Automated tests**: YES (Unit tests + Integration tests)
- **Framework**: GUT (Godot Unit Test)
- **Test Coverage**: Runtime classes 100%, Node classes 90%, Integration paths 100%

### QA Policy
Every task MUST include agent-executed QA scenarios. Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Resource定义**: 使用 Bash (grep) — 验证文件存在、包含@export变量、继承Resource
- **Runtime类**: 使用 Bash (gut test) — 运行测试验证逻辑正确性
- **节点类**: 使用 Bash (gut test) — 验证节点可以实例化
- **场景文件**: 使用 Bash (ls) — 验证.tscn文件存在

---

## Execution Strategy

### Parallel Execution Waves

> Maximize throughput by grouping independent tasks into parallel waves.
> Each wave completes before the next begins.
> Target: 5-8 tasks per wave. Fewer than 3 per wave (except final) = under-splitting.

```
Wave 1 (Start Immediately — 基础设施与Resource定义):
├── Task 1: EventBus定义 [quick]
├── Task 2: ServiceLocator定义 [quick]
├── Task 3: PlayerStatsResource [quick]
├── Task 4: WeaponDataResource [quick]
├── Task 5: ComponentPartResource [quick]
├── Task 6: MaterialResource [quick]
├── Task 7: GemResource [quick]
└── Task 8: CoreResource [quick]

Wave 2 (After Wave 1 — Runtime状态类):
├── Task 9: MaterialRuntime [quick]
└── Task 10: GemRuntime [quick]

Wave 3 (After Wave 2 — 系统类):
└── Task 17: ComponentSystem [quick] (依赖Runtime类，需在Node类之前)

Wave 4 (After Wave 3 — 节点类):
├── Task 11: PlayerNode [unspecified-high]
├── Task 12: ResourceSystemNode [quick]
├── Task 13: MovementNode [quick]
├── Task 14: CombatNode [quick]
├── Task 15: WeaponSystemNode [quick]
└── Task 16: WeaponNode [quick]

Wave 5 (After Wave 4 — 场景):
└── Task 18: 玩家场景文件创建 [quick]

Wave 6 (After Wave 5 — 测试用例):
├── Task 19: Runtime类测试 [quick]
├── Task 20: Resource系统测试 [quick]
├── Task 21: 玩家集成测试 [unspecified-high]
└── Task 22: 武器系统测试 [quick]

Wave 7 (After Wave 6 — 最终验证):
├── Task F1: 代码质量检查 [quick]
└── Task F2: 架构一致性验证 [deep]

Critical Path: Task 3 → Task 9 → Task 17 → Task 11 → Task 18 → Task 21 → F1-F2
Parallel Speedup: ~80% faster than sequential
Max Concurrent: 8 (Wave 1)
```

### Dependency Matrix

- **1-2**: — — 11-22
- **3-8**: — — 9-10, 17
- **9-10**: — — 17
- **17**: 9-10, 3-8 — 16
- **11**: 17, 9-10 — 18
- **12**: 11, 3 — —
- **13**: 11 — —
- **14**: 12, 15 — —
- **15**: 16, 11 — —
- **16**: 17, 5-8 — —
- **18**: 11 — — 21
- **19-22**: 11-18 — F1-F2
- **F1-F2**: 11-22 — —

### Agent Dispatch Summary

- **1**: **8** — T1-T8 → `quick`
- **2**: **2** — T9-T10 → `quick`
- **3**: **1** — T17 → `quick`
- **4**: **6** — T11-T16 → T11=`unspecified-high`, T12-T16=`quick`
- **5**: **1** — T18 → `quick`
- **6**: **4** — T19-T22 → `quick`
- **7**: **2** — F1-F2 → F1=`quick`, F2=`deep`

---

## TODOs

> Implementation + Test = ONE Task. Never separate.
> EVERY task MUST have: Recommended Agent Profile + Parallelization info + QA Scenarios.
> **A task WITHOUT QA Scenarios is INCOMPLETE. No exceptions.**

---

**Wave 1: 基础设施与Resource定义（8个任务，并行执行）**

- [x] 1. EventBus定义 - 定义Autoload单例，包含所有Signal定义
- [x] 2. ServiceLocator定义 - 定义Autoload单例，提供全局服务访问
- [x] 3. PlayerStatsResource - 定义玩家配置Resource（max_health, max_shield, max_energy, energy_regen_rate）
- [x] 4. WeaponDataResource - 定义武器配置Resource（weapon_type, base_damage, attack_speed, interrupt_level, components）
- [x] 5. ComponentPartResource - 定义部件Resource（component_type, sub_type, has_material_slot, has_gem_slot, material, gem）
- [x] 6. MaterialResource - 定义材料Resource（material_name, base_stats, visual_properties）
- [x] 7. GemResource - 定义宝石Resource（gem_name, effects, visual_effects）
- [x] 8. CoreResource - 定义核心Resource（core_type, base_stats, ultimate_skill, max_item_slots）

**Wave 2: Runtime状态类（2个任务，并行执行）**

- [x] 9. MaterialRuntime - 定义材料运行时状态（material_data, current_durability）
- [x] 10. GemRuntime - 定义宝石运行时状态（gem_data, is_active）

**Wave 3: 系统类（1个任务，串行执行）**

- [x] 17. ComponentSystem - 定义部件系统，管理武器部件，使用duplicate(true)深拷贝（依赖Task 9, 10）

**Wave 4: 节点类（6个任务，并行执行）**

- [x] 11. PlayerNode - 定义玩家主节点（CharacterBody2D），整合所有子系统，手动驱动更新循环
- [x] 12. ResourceSystemNode - 定义资源管理节点，管理生命、护盾、能量运行时状态
- [x] 13. MovementNode - 定义移动系统节点，管理角色移动、跳跃，使用owner访问父节点
- [x] 14. CombatNode - 定义战斗系统节点，管理战斗逻辑，使用节点路径获取依赖
- [x] 15. WeaponSystemNode - 定义双武器系统节点，管理双武器配置
- [x] 16. WeaponNode - 定义武器节点，管理单个武器数据、部件、外观（依赖Task 17）

**Wave 5: 场景（1个任务）**

- [x] 18. 玩家场景文件创建 - 创建player.tscn，包含正确的节点树结构

**Wave 6: 测试用例（4个任务，并行执行）**

- [x] 19. Runtime类测试 - 为MaterialRuntime和GemRuntime编写单元测试
- [x] 20. Resource系统测试 - 为ResourceSystemNode编写单元测试
- [x] 21. 玩家集成测试 - 为PlayerNode编写集成测试
- [x] 22. 武器系统测试 - 为WeaponSystem和WeaponNode编写测试

**Wave 7 (After Wave 6 — 最终验证):**

- [x] F1. 代码质量检查
- [x] F2. 架构一致性验证

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 2 review agents run in PARALLEL. ALL must APPROVE. Rejection → fix → re-run.

- [ ] F1. **代码质量检查** — `unspecified-high`
  检查所有代码文件：使用`duplicate(true)`深拷贝、使用节点路径获取依赖、Signal连接使用`is_connected`安全检查、不使用`_physics_process`（由父节点手动调用）、遵循最佳实践F.1-F.6。
  Output: `深拷贝检查 [PASS/FAIL] | 节点路径检查 [PASS/FAIL] | Signal安全检查 [PASS/FAIL] | 手动驱动检查 [PASS/FAIL] | VERDICT`

- [ ] F2. **架构一致性验证** — `deep`
  验证实现与架构设计文档的一致性：所有类定义、方法签名、Signal定义、依赖关系是否与文档匹配。检查场景树结构是否正确。
  Output: `类定义 [N/N] | 方法签名 [N/N] | Signal定义 [N/N] | 场景树 [PASS/FAIL] | VERDICT`

---

## Commit Strategy

- **1**: `feat(infra): EventBus和ServiceLocator` — autoloads/event_bus.gd, autoloads/service_locator.gd
- **2**: `feat(resource): Resource定义` — src/resources/*.gd
- **3**: `feat(runtime): Runtime状态类` — src/systems/*.gd
- **4**: `feat(nodes): 节点类实现` — src/nodes/*.gd
- **5**: `feat(component): ComponentSystem` — src/systems/component_system.gd
- **6**: `feat(scene): 玩家场景文件` — scenes/player.tscn
- **7**: `test(architecture): 测试用例` — tests/*.gd

---

## Success Criteria

### Verification Commands
```bash
# 验证Resource文件存在且继承Resource
find src/resources -name "*.gd" -exec grep -l "extends Resource" {} \;

# 验证节点文件存在
find src/nodes -name "*.gd" -exec grep -l "extends Node" {} \;

# 验证使用duplicate(true)深拷贝
grep -r "duplicate(true)" src/nodes/ src/systems/

# 验证Signal使用is_connected检查
grep -r "is_connected" src/nodes/

# 运行所有测试
gut test .
```

### Final Checklist
- [ ] 所有Resource类使用@export导出变量
- [ ] 所有Resource深拷贝使用duplicate(true)
- [ ] 所有节点类使用节点路径获取依赖
- [ ] 所有Signal连接使用is_connected安全检查
- [ ] 所有子系统不定义_physics_process（由PlayerNode手动驱动）
- [ ] EventBus配置为Autoload
- [ ] 场景文件包含正确的节点树结构
- [ ] 所有测试用例通过
- [ ] 代码注释使用中文
