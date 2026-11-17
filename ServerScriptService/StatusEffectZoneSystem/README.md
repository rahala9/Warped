# StatusEffectZoneSystem

Status-effect zones use the existing `ZoneLoader` and the `ZoneFolder` tag.
The folder name is descriptive; `ZoneKey` must be unique across the place.

Example Stink zone:

- Folder name: `StinkZone_TrashPile01`
- Tag: `ZoneFolder`
- `ZoneKey` (string): `StatusEffect:Stink:TrashPile01`
- `ZoneType` (string): `StatusEffect`
- `EffectName` (string): `Stink`
- `SourceLevel` (number): `1`
- `RemoveOnExit` (boolean): `false`
- `DetectionMode` (string): `Center` or `Ground`
- `Enabled` (boolean): `true`

The folder must contain at least one `BasePart` defining its bounds. With
`RemoveOnExit = false`, Stink continues for its configured duration after the
player exits. With `RemoveOnExit = true`, the zone removes an effect it owns
when the player leaves the last overlapping zone for that effect.

`StudioTools/ConfigureSelectedStatusEffectZone.luau` configures selected zone
folders without moving or resizing their bounds parts.
