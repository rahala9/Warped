# EffectSystem

Effect definitions in `ReplicatedStorage.SharedModules.Effects` may include a
`Behaviors` array. Each entry is dispatched to a module with the same name in
`EffectSystem/Behaviors`.

Behavior modules may implement:

- `OnApply(context, behavior)` and return private runtime state.
- `OnTick(context, behavior, state)` for periodic work.
- `OnRemove(context, behavior, state)` for cleanup.

The context includes `Player`, `EffectName`, `RuntimeEffect`, `SourceLevel`,
`Definition`, and `BehaviorIndex`. `OnTick` also receives `DeltaTime`.

Legacy `Effect.Type` and `Effect.Action` definitions remain supported while
effects are migrated. `Stink` is the first composed definition: it owns a
`CharacterVFX` behavior for flies and a `MeterRate` behavior for Biohazard.

New definitions may put `Duration`, `TickInterval`, `Stacking`, and
`Presentation` at the top level. `DefinitionAdapter` supplies legacy values
until each old definition is migrated. Supported stacking modes are `Ignore`,
`Refresh`, `Stack`, and `Replace`.

`EffectRuntimeService` is the single server scheduler for player effects. Each
runtime carries server-time `StartedAt` and `ExpiresAt` values, which lets the
client display an authoritative countdown without maintaining its own timer.
Runtime source claims allow overlapping zones and systems to share an effect;
source-specific removal releases only the caller's claim.

Behavior handlers must undo persistent work in `OnRemove`. Effect removal on
expiry, zone exit, teleport, death, and explicit calls all follow that cleanup
path.

## Queries and restrictions

`EffectQueryService` is the server-authoritative read API for consumers:

- `HasEffect(player, effectName)`
- `HasBehavior(player, behaviorType, optionalAction)`
- `CanPerform(player, actionName)`

Passive `Restriction` behaviors declare blocked actions and their player-facing
message. NPC dialogue and inventory purchase paths consult `CanPerform`, so an
effect definition controls policy without those systems knowing effect names.
Opening the shop UI is server-authorized through `RequestShopAccess`; a blocked
request opens the same NPC-style restriction dialog instead of the shop.
Dialog definitions may also use `HasEffect`, `DoesNotHaveEffect`, `CanPerform`,
and `CannotPerform` conditions for effect-specific alternatives.

`ElectricShock` is the first fully composed damage effect. Its
`DamageOverTime`, `CharacterVFX`, and `ClientVisual` behaviors replace the old
hard-coded electric DOT/VFX branches. `Stink` composes flies, Biohazard meter
exposure, and NPC/purchase restrictions.

Player-side Poison, SmallBleed, Bleed, Hemorrhage, and OnFire now use the same
`DamageOverTime` behavior. Their legacy DOT payloads remain only because enemy
effects still consume them; the player tick path deliberately skips legacy
logic whenever a definition declares `Behaviors`.

`DefinitionValidator` runs when `DataEffectsFunctions` loads and fails startup
with one consolidated report for invalid timing, stacking, legacy Type/Action
pairs, or behavior handlers. This prevents malformed effects from failing only
when a player encounters them.

## Movement modifiers

Player movement effects use `MovementModifier` behaviors backed by one
source-aware `MovementModifierService`. The service captures the character's
real baseline speed, combines every active modifier independent of application
order, and restores the captured baseline only after the final modifier leaves.
Supported operations are `Add`, `Multiply`, `ClampMin`, `ClampMax`, `Override`,
and `Immobilize`. Immobilization is reference-counted through the modifier set,
so removing one trap cannot release a player who is still held by another.

Slow, Speed, SwimSpeed, Trapped, WebTrapped, and SlimeWebTrapped have migrated.
Their legacy movement payload remains for the enemy-effect path, while player
legacy ticking and cleanup are skipped for every composed definition.
