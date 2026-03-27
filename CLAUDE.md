# Forest Dungeon — Claude Code Context

## Project

Godot 4 — GDScript only. 5v5 strategic MOBA. Active prototype in refactor.  
GDD reference: v0.4. Design has diverged significantly from earlier implementation.  
Expect dead code, legacy `.tres` files, and structural systems not aligned with current design.

---

## GDScript Conventions

- No inline comments unless the *why* is genuinely non-obvious. Names explain the what.
- snake_case for everything except class names (PascalCase) and constants (SCREAMING_SNAKE_CASE).
- Type hints on every variable and return type on every function — no exceptions.
- `@onready` over `get_node()`. Always.
- Signals: past tense, snake_case — `player_died`, `item_evolved`, `soul_granted`.
- One script per scene. Logic lives in the owning node, not in a manager that reaches into it.
- No autoloads unless strictly necessary and explicitly agreed on. Prefer signals and dependency injection.
- Prefer early returns over nested conditionals.
- No magic numbers. Named constants or exported variables only.

---

## On Dead and Legacy Code

The prototype predates several design changes in GDD v0.4. When touching any file:

- Flag any variable, method, or signal with no callers or that maps to a removed concept.
- Flag `.tres` resource files still using the old embedded-Entity or split-stats format.
- Do not work around dead code. Propose removal or a migration path.
- If a file's structure no longer maps to current GDD concepts, say so before writing anything.

---

## When Proposing Implementation

If a structural issue is obvious — wrong coupling, wrong abstraction level, doesn't match GDD intent — raise it *before* writing code. Propose an alternative and state the tradeoff clearly. Do not silently implement a flawed structure because it was asked for.

If a current system has a clear successor pattern that fits the design better, propose the rewrite path alongside the immediate fix.

---

## Key Design Constraints (GDD v0.4)

These are non-negotiable — any implementation that violates them is wrong regardless of whether it compiles.

- **No character abilities or skill trees.** Items give everything — stats, passives, actives.
- **Stats are global on the character sheet.** Items contribute additively. No per-item damage application.
- **Damage types:** Physical, Tension, Withering. Each has a direct armor counterpart. No universal armor, no penetration stat.
- **Rythic** is the universal scaling stat. Scales active abilities via `action_time × rate_constant`. Instant abilities and passive triggers do not scale with Rythic.
- **Evolution is forward-only.** Items combine forward. No revert, no drop, no trash. A bad combination must be merged away to clear the slot.
- **Inventory:** 16 slots fixed, 4×4 grid. **Ability bar:** 12 slots, single row. Active items move from inventory to bar on bind — they leave inventory entirely. Unbound, they return.
- **Fog of war:** three states — black (never seen), grey (discovered, no entities), active vision.
- **No recall, no pings, no voice, no emotes.** Text chat only. Coordinate grid for callouts.
- **No floating damage numbers, no XP popups.** World-native feedback only.

---

## Item System — Structural Decisions

### Stats and evolution caps

**Do not use two separate `Dictionary` exports for `stats` and `stat_caps`.**  
A stat without a cap is not a valid concept on an evolvable item — they are one entry, not two fields.  
Splitting them creates sync bugs and makes the data unreadable in the editor.

Use a typed array of a `StatEntry` resource:

```gdscript
# stat_entry.gd
class_name StatEntry
extends Resource

@export var id: StringName
@export var value: float
@export var cap: float
```

```gdscript
# item_class.gd
@export var stats: Array[StatEntry] = []
```

Each entry is self-contained. The editor shows them as an inspectable list. No sync required.  
Evolution check: iterate `stats`, compare `entry.value >= entry.cap` per entry.

---

### Item identity

**Do not use `item_id: int` with numeric block conventions.**  
Block ranges (1000s = basic, 2000s = evolved) imply a flat two-tier hierarchy.  
The GDD describes deep evolution chains — items that are evolutions of evolutions of evolutions.  
A numeric block scheme breaks the moment a chain exceeds the assumed depth, and it communicates nothing.

Use `StringName` identifiers instead:

```gdscript
@export var id: StringName  # e.g. &"embershard", &"twin_fang", &"pale_crown"
```

- Fast to compare (`==` is pointer equality on StringName).
- Dictionary-safe.
- Self-documenting in save data and logs.
- No block assignment. No reserved ranges.

Evolution relationships are encoded in the item data, not the ID:

```gdscript
@export var evolved_from: Array[StringName] = []
```

This is the list of item IDs that can combine into this item. The craft system queries `evolved_from` across all registered items to find valid combinations — the ID itself carries no structural meaning.

A basic item has `evolved_from = []`. A deep evolution has two or more IDs in `evolved_from`, regardless of how many tiers deep it sits. The graph is flat data, not an ID convention.

---

### Stat identifiers

Never use raw string literals for stat IDs in logic. Define them as `StringName` constants in one place:

```gdscript
# In Entity or a dedicated Stats class
const S_PHYSICAL        := &"physical"
const S_TENSION         := &"tension"
const S_WITHERING       := &"withering"
const S_RYTHIC          := &"rythic"
const S_MAX_HEALTH      := &"max_health"
const S_MOVEMENT_SPEED  := &"movement_speed"
const S_VEIL            := &"veil"
# ... etc.
```

All stat lookups use these constants. No bare strings in combat, item, or UI logic.

---

## Active Refactor Priorities (GDD §12)

In current order:

1. Migrate `.tres` Entity resource files → `base_stats` dictionary format (`player.tres`, `monster.tres`, `outer_wall.tres`)
2. Migrate `.tres` Item resource files → `item_class.gd` format using `Array[StatEntry]` and `StringName` id
3. Implement ability bar as item container — bind moves item out of inventory into bar slot, unbind returns it
4. Implement dual icon system per item — active/ready art and cooldown/unavailable art
5. Implement 3D item model socket system on player rig — 6–8 attachment points, defined fallback order
6. Map generation — implement full 5-layer system with terrain classification
7. Rythic rate constant and level scaling curve — tune in prototype before item design finalises
8. Ward stone visual language — soul advantage communicated through physical appearance, not numbers
9. Prototype 2–3 monster types with individual mechanics (one per terrain type)