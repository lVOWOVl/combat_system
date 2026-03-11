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
(To be filled by librarian agent)

## Open Questions
- What states does the state machine need? (idle, move, attack, dead, etc.)
- How do states transition? (input-driven, event-driven?)
- Should other nodes expose state-specific methods or maintain their current interface?
- Do we need to preserve backward compatibility with EventBus signals?
- Should state transitions be handled by PlayerNode or delegated to specific nodes?

## Technical Decisions
(To be made during consultation)
