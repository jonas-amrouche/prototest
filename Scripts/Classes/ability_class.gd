## Ability — pure data resource. No execution logic lives here.
##
## Execution is handled by AbilityHandler nodes (one per ability type).
## This means new abilities are new resource files, not new scripts.
## The handler reads these fields and knows what to do with them.
##
## ability_type determines which AbilityHandler processes this ability.
## See Basics.AbilityType for the full list of supported types.

class_name Ability
extends Resource

# ── Identity ──────────────────────────────────────────────────────────────────

@export var id          : String
@export var display_name: String
@export_multiline var description : String
@export var icon        : Texture2D

# ── Execution type ────────────────────────────────────────────────────────────
## Determines which AbilityHandler node processes this ability.
## TARGETED    — fires at entity.selected_target
## SKILLSHOT   — fires toward cursor at cast time
## AREA        — affects all enemies in a radius around caster
## TOGGLE      — on/off state, ticked each frame while active
## PASSIVE     — never cast, applied automatically (listed for completeness)

@export var ability_type : Basics.AbilityType = Basics.AbilityType.TARGETED

# ── Timing ────────────────────────────────────────────────────────────────────

## Time between press and the effect firing. Drives the channeling bar.
@export var action_time  : float = 0.0
## True if the channeling bar should be shown during action_time.
@export var channeling   : bool  = false
## How long the ability scene lives after firing (0 = instant cleanup).
@export var life_time    : float = 0.0
## Cooldown starts after the effect fires.
@export var cooldown     : float = 1.0
## If > 0, this ability uses charges instead of a single cooldown.
@export var charges      : int   = 0

# ── Targeting ─────────────────────────────────────────────────────────────────

## Maximum cast range. 0 = unlimited.
@export var spell_range  : float = 0.0
## If true, requires a valid target before the ability can fire.
@export var targeted     : bool  = false

# ── Damage ────────────────────────────────────────────────────────────────────

@export var damage_type  : Basics.DamageType = Basics.DamageType.PHYSIC
## Multiplier applied to the caster's relevant damage stat.
## 1.0 = full damage, 0.5 = half damage, 1.5 = 150% damage.
@export var damage_scale : float = 1.0
## Hard cap on damage this ability can deal. 0 = no cap.
@export var damage_cap   : int   = 0

# ── Area parameters (used by AREA and SKILLSHOT types) ────────────────────────

## Radius of the effect area. 0 = single target only.
@export var area_radius  : float = 0.0
## For skillshots: how fast the projectile travels. 0 = instant.
@export var projectile_speed : float = 0.0

# ── Effects applied on hit ────────────────────────────────────────────────────
## These are applied to every entity hit by this ability.

@export var on_hit_effects : Array[Effect] = []

# ── Slot assignment (set at runtime by inventory system) ──────────────────────
## -1 = not assigned. 10 = auto-attack slot. 0–9 = player hotbar slots.

var slot_id : int = -1
