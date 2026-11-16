# Laser Slice Studio Baker

## Current production template

The runtime now uses `ReplicatedStorage/SharedClientAssets/SlicedCrew` through
`SlicedCrewSliceProvider`. Each direct child named `Part1`, `Part2`, etc. is
treated as one falling assembly, so its body mesh and searing mesh are welded
together at runtime. `FaceTop` and `FaceBottom` receive cropped sections of the
victim's face image. Corpses are removed after `Config.EffectLifetime` seconds.

The older EditableMesh baker workflow below is retained only as prototype
documentation and is not used while `Config.Provider = "SlicedCrew"`.

This plugin converts the dynamic laser-slice result into permanent mesh assets and a reusable template.

1. In Studio, save `LaserSliceBaker.plugin.luau` as a local plugin.
2. Enable **Mesh / Image APIs** in Experience Settings.
3. Select the character model and the laser-door model together.
4. Press **Warped Laser Slices > Bake Selected**.
5. Save/publish the generated model under `ReplicatedStorage/LaserSliceSystem/BakedTemplates`.
6. After the templates are verified, set `Provider = "Baked"` in `ReplicatedStorage/LaserSliceSystem/Config.luau`.
7. The client `DynamicSliceProvider.luau` and `MeshSlicer.luau`, plus this plugin folder, can then be deleted.

## Baking an inspected runtime result

An `.rbxm` export does not preserve body slices backed by temporary
`EditableMesh` content; they reload as boxes. While the generated result is
still visible in Studio:

1. Select the single `*_DynamicLaserSlices` model under `_LaserSliceRuntime`.
2. Press **Warped Laser Slices > Bake Existing**.
3. Wait for each sliced mesh to upload. The plugin creates or replaces
   `ReplicatedStorage/LaserSliceSystem/BakedTemplates/Default`.
4. If baking during Play, right-click the newly created permanent `Default`
   model and **Save to File** before stopping. Changes made in the client test
   DataModel do not persist when Play ends.
5. Stop Play, insert that new `.rbxm`, and place it back under
   `ReplicatedStorage/LaserSliceSystem/BakedTemplates`. Unlike the raw runtime
   export, this file contains asset-backed meshes and should remain visible.
6. Restart the test and verify the template remains visible.
7. Set `Provider = "Baked"` only after that persistence test succeeds.

Set a laser door's `LaserSliceTemplate` attribute when it should use a baked template other than `Default`.

Equipment can override its behavior with a `LaserDeathBehavior` string attribute:

- `Slice`
- `FollowAttachment`
- `Drop`
- `Detach`
- `Hide`
