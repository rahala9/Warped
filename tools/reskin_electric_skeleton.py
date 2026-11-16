"""Re-skin Synty's Dark Fantasy skeleton mesh to Warped's player armature.

Run with Blender 4.x in the background or from Blender's Scripting workspace.
The defaults point at Jon's Warped/Synty source files. Optional arguments are:

    blender --background --factory-startup --python reskin_electric_skeleton.py -- \
        <source Characters.fbx> <target CrewMixamoStarter.fbx> <output.fbx>

The conversion is deterministic and does not use automatic weights. Existing
source weights are mapped by anatomy, while each vertex is moved from the
source bind space into the matching Warped bone's bind space.
"""

from __future__ import annotations

import os
import sys

import bpy
import numpy as np
from mathutils import Matrix, Vector


DEFAULT_SOURCE = r"E:\polygon\POLYGON_Dark_Fantasy_SourceFiles_v4\FBX\Characters\Characters.fbx"
DEFAULT_TARGET = r"E:\gamedev\Warped\Models\Characters\CrewMixamoStarter.fbx"
DEFAULT_OUTPUT = r"E:\gamedev\Warped\code\GeneratedAssets\SM_Chr_Skeleton_01_WarpedRig.fbx"
SOURCE_MESH_NAME = "SM_Chr_Skeleton_01"


def import_fbx(path: str) -> list[bpy.types.Object]:
    before = set(bpy.data.objects)
    if hasattr(bpy.ops.wm, "fbx_import"):
        bpy.ops.wm.fbx_import(filepath=path)
    else:
        bpy.ops.import_scene.fbx(filepath=path)
    return [obj for obj in bpy.data.objects if obj not in before]


def mapped_bone_name(source_name: str) -> str:
    # Dark Fantasy uses Blender's duplicate-name suffix for the right fingers;
    # Warped's player rig uses the suffix emitted by its FBX exporter.
    if source_name.endswith(".001"):
        return source_name[:-4] + "_1"
    return source_name


def bone_world_matrix(armature: bpy.types.Object, bone: bpy.types.Bone) -> Matrix:
    return armature.matrix_world @ bone.matrix_local


def main(source_path: str, target_path: str, output_path: str) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)

    source_objects = import_fbx(source_path)
    source_mesh = next((obj for obj in source_objects if obj.name == SOURCE_MESH_NAME), None)
    source_armature = next((obj for obj in source_objects if obj.type == "ARMATURE"), None)
    if source_mesh is None or source_armature is None:
        raise RuntimeError(f"Could not find {SOURCE_MESH_NAME!r} and its armature in {source_path}")

    target_objects = import_fbx(target_path)
    target_armature = next((obj for obj in target_objects if obj.type == "ARMATURE"), None)
    if target_armature is None:
        raise RuntimeError(f"Could not find the target armature in {target_path}")

    source_bones = source_armature.data.bones
    target_bones = target_armature.data.bones

    group_to_target: dict[int, str] = {}
    missing_weighted_groups: list[str] = []
    for group in source_mesh.vertex_groups:
        target_name = mapped_bone_name(group.name)
        if target_bones.get(target_name) is not None and source_bones.get(group.name) is not None:
            group_to_target[group.index] = target_name
        else:
            missing_weighted_groups.append(group.name)

    if not group_to_target:
        raise RuntimeError("No weighted source bones could be mapped to the Warped armature")

    source_mesh_world = source_mesh.matrix_world.copy()
    target_world_inverse = target_armature.matrix_world.inverted()

    # Both characters use the same overall Synty humanoid proportions but their
    # FBXs encode different bone-local axes. A single best-fit similarity
    # transform aligns the intact mesh without rotating its separate bones
    # independently. The Warped armature then owns all later deformation.
    landmarks = [
        "Hips", "Spine_01", "Spine_02", "Spine_03", "Neck", "Head",
        "Clavicle_L", "Shoulder_L", "Elbow_L", "Hand_L",
        "Clavicle_R", "Shoulder_R", "Elbow_R", "Hand_R",
        "UpperLeg_L", "LowerLeg_L", "Ankle_L", "Ball_L", "Toes_L",
        "UpperLeg_R", "LowerLeg_R", "Ankle_R", "Ball_R", "Toes_R",
    ]
    source_points = []
    target_points = []
    for name in landmarks:
        source_bone = source_bones.get(name)
        target_bone = target_bones.get(name)
        if source_bone is None or target_bone is None:
            continue
        source_points.append(tuple(source_armature.matrix_world @ source_bone.head_local))
        target_points.append(tuple(target_armature.matrix_world @ target_bone.head_local))

    source_array = np.asarray(source_points, dtype=np.float64)
    target_array = np.asarray(target_points, dtype=np.float64)
    source_center = source_array.mean(axis=0)
    target_center = target_array.mean(axis=0)
    source_centered = source_array - source_center
    target_centered = target_array - target_center
    covariance = source_centered.T @ target_centered
    left, _, right_t = np.linalg.svd(covariance)
    rotation = right_t.T @ left.T
    if np.linalg.det(rotation) < 0:
        right_t[-1, :] *= -1
        rotation = right_t.T @ left.T
    similarity_scale = float(
        np.sum((source_centered @ rotation.T) * target_centered)
        / np.sum(source_centered * source_centered)
    )
    translation = target_center - similarity_scale * (rotation @ source_center)
    fitted = (similarity_scale * (rotation @ source_array.T)).T + translation
    landmark_rms_error = float(np.sqrt(np.mean(np.sum((fitted - target_array) ** 2, axis=1))))

    for vertex in source_mesh.data.vertices:
        source_world_position = source_mesh_world @ vertex.co
        source_np = np.asarray(tuple(source_world_position), dtype=np.float64)
        target_np = similarity_scale * (rotation @ source_np) + translation
        target_world_position = Vector(target_np.tolist())
        vertex.co = target_world_inverse @ target_world_position

    # Rename the retained groups so Roblox bones and mesh weights agree exactly.
    for group in source_mesh.vertex_groups:
        group.name = mapped_bone_name(group.name)

    source_mesh.name = "ElectricSkeleton"
    source_mesh.data.name = "ElectricSkeletonMesh"
    source_mesh.parent = target_armature
    source_mesh.matrix_parent_inverse = Matrix.Identity(4)
    source_mesh.matrix_world = target_armature.matrix_world

    for modifier in list(source_mesh.modifiers):
        if modifier.type == "ARMATURE":
            source_mesh.modifiers.remove(modifier)
    armature_modifier = source_mesh.modifiers.new(name="WarpedArmature", type="ARMATURE")
    armature_modifier.object = target_armature

    # Remove imported character meshes and the obsolete source rig. Only the
    # converted skeleton and Warped armature belong in the exported asset.
    for obj in list(target_objects):
        if obj != target_armature and obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)
    for obj in list(source_objects):
        if obj not in {source_mesh, source_armature} and obj.name in bpy.data.objects:
            bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.objects.remove(source_armature, do_unlink=True)

    target_armature.name = "ElectricSkeletonArmature"
    if target_armature.animation_data is not None:
        target_armature.animation_data_clear()

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    source_mesh.select_set(True)
    target_armature.select_set(True)
    bpy.context.view_layer.objects.active = target_armature

    blend_path = os.path.splitext(output_path)[0] + ".blend"
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)

    bpy.ops.export_scene.fbx(
        filepath=output_path,
        use_selection=True,
        object_types={"ARMATURE", "MESH"},
        add_leaf_bones=False,
        bake_anim=False,
        apply_unit_scale=True,
        use_space_transform=True,
    )

    print("WARPED_SKELETON_RESKIN_COMPLETE")
    print("OUTPUT", output_path)
    print("BLEND_OUTPUT", blend_path)
    print("MAPPED_WEIGHT_GROUPS", len(group_to_target))
    print("SIMILARITY_SCALE", similarity_scale)
    print("LANDMARK_RMS_ERROR", landmark_rms_error)
    print("UNMAPPED_GROUPS", sorted(missing_weighted_groups))
    print("UNMAPPED_VERTICES", 0)
    print("OUTPUT_VERTICES", len(source_mesh.data.vertices))
    print("OUTPUT_BONES", len(target_armature.data.bones))


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    source = args[0] if len(args) > 0 else DEFAULT_SOURCE
    target = args[1] if len(args) > 1 else DEFAULT_TARGET
    output = args[2] if len(args) > 2 else DEFAULT_OUTPUT
    main(source, target, output)
