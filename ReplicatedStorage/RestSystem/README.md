# RestSystem

RestSystem provides server-authoritative, data-driven sitting, relaxing, and
sleeping interactions. It is event driven: stations do not run loops and only
occupied stations allocate session state.

## Station setup

Tag a model or part `RestStation` and give it the attribute:

```text
RestDefinition = "Chair"
```

The tagged instance must contain:

```text
RestPoint (Attachment)
  RestPrompt (ProximityPrompt)
ExitPoint (Attachment)
```

`RestPoint.WorldCFrame` is the exact HumanoidRootPart transform while resting.
`ExitPoint.WorldCFrame` is the transform used when leaving. A bench with several
places uses one tagged child station per place.

Definitions live in `ReplicatedStorage.RestSystem.Config`. Add a shared
definition for a new pose; do not add config entries for individual chairs.

Select a model and run `StudioTools/ConfigureSelectedRestStation.luau` to create
or repair this structure. Move and rotate the generated attachments afterward.

## Runtime attributes

The server owns these attributes:

- `RestOccupantUserId` on an occupied station
- `Resting` and `RestDefinition` on the player and character

Other gameplay systems may use `Resting == true` as a cheap action guard.
