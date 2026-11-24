"""Deterministically retarget the Synty locomotion rig in Retarget.blend.

Designed for the two armatures currently in the file:
  Source: Armature.001 (Synty Base Locomotion animation rig)
  Target: Armature     (the smaller Synty character rig)

Run from Blender's Scripting workspace. The script uses the installed
Auto-Rig Pro remap engine, but replaces its generic name guesses with an
audited, one-to-one map for these exact skeletons.

For automated testing, Blender can pass an optional output path:
  blender --background Retarget.blend --python this_script.py -- --output result.blend
"""

from __future__ import annotations

import argparse
import math
import sys

import bpy
from mathutils import Matrix


SOURCE_ARMATURE = "Armature.001"
TARGET_ARMATURE = "Armature"
SOURCE_ACTION = "Armature.001|A_Walk_F_Masc|BaseLayer"

# A source target may appear only once. The important Synty terminology
# difference is Shoulder -> upperarm and Elbow -> lowerarm.
BONE_MAP = {
    "Root": "root",
    "Hips": "pelvis",
    "Spine_01": "spine_01",
    "Spine_02": "spine_02",
    "Spine_03": "spine_03",
    "Neck": "neck_01",
    "Head": "head",
    "Eyes": "eyes",
    "Eyebrows": "eyebrows",
    "Clavicle_L": "clavicle_l",
    "Shoulder_L": "upperarm_l",
    "Elbow_L": "lowerarm_l",
    "Hand_L": "hand_l",
    "Clavicle_R": "clavicle_r",
    "Shoulder_R": "upperarm_r",
    "Elbow_R": "lowerarm_r",
    "Hand_R": "hand_r",
    "UpperLeg_L": "thigh_l",
    "LowerLeg_L": "calf_l",
    "Ankle_L": "foot_l",
    "Ball_L": "ball_l",
    "Toes_L": "toes_l",
    "UpperLeg_R": "thigh_r",
    "LowerLeg_R": "calf_r",
    "Ankle_R": "foot_r",
    "Ball_R": "ball_r",
    "Toes_R": "toes_r",
    "Thumb_01": "thumb_01_l",
    "Thumb_02": "thumb_02_l",
    "Thumb_03": "thumb_03_l",
    "Thumb_01_1": "thumb_01_r",
    "Thumb_02_1": "thumb_02_r",
    "Thumb_03_1": "thumb_03_r",
    # The target has a compact two-bone combined finger chain.
    "Finger_01": "middle_01_l",
    "Finger_02": "middle_02_l",
    "Finger_01_1": "middle_01_r",
    "Finger_02_1": "middle_02_r",
}

ROOT_SOURCE_BONE = "Root"

# These pairs describe anatomical limb segments using joint positions. This is
# intentionally separate from bone-tail direction: the mini rig's imported
# bones are disconnected and their displayed tails do not point down the mesh.
ARM_SEGMENTS = (
    (("Shoulder_L", "Elbow_L"), ("upperarm_l", "lowerarm_l")),
    (("Elbow_L", "Hand_L"), ("lowerarm_l", "hand_l")),
    (("Shoulder_R", "Elbow_R"), ("upperarm_r", "lowerarm_r")),
    (("Elbow_R", "Hand_R"), ("lowerarm_r", "hand_r")),
)


def parse_arguments() -> argparse.Namespace:
    arguments = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--output")
    return parser.parse_args(arguments)


def require_armature(name: str) -> bpy.types.Object:
    obj = bpy.data.objects.get(name)
    if obj is None:
        raise RuntimeError(f"Armature object not found: {name}")
    if obj.type != "ARMATURE":
        raise RuntimeError(f"{name} is {obj.type}, not an armature")
    return obj


def validate_map(source: bpy.types.Object, target: bpy.types.Object) -> None:
    missing_source = [name for name in BONE_MAP if name not in source.data.bones]
    missing_target = [name for name in BONE_MAP.values() if name not in target.data.bones]
    duplicate_targets = sorted(
        name for name in set(BONE_MAP.values()) if list(BONE_MAP.values()).count(name) > 1
    )

    problems = []
    if missing_source:
        problems.append(f"Missing source bones: {missing_source}")
    if missing_target:
        problems.append(f"Missing target bones: {missing_target}")
    if duplicate_targets:
        problems.append(f"Duplicate target bones: {duplicate_targets}")
    if problems:
        raise RuntimeError("\n".join(problems))


def clear_mapping(scene: bpy.types.Scene) -> None:
    while len(scene.bones_map_v2):
        scene.bones_map_v2.remove(len(scene.bones_map_v2) - 1)


def configure_arp(
    scene: bpy.types.Scene,
    source: bpy.types.Object,
    target: bpy.types.Object,
    action: bpy.types.Action,
) -> None:
    source.animation_data_create()
    source.animation_data.action = action

    # ARP bakes the scene's active frame range, not necessarily the complete
    # source action. Never inherit a shortened preview range from the .blend.
    scene.frame_start = math.floor(action.frame_range[0])
    scene.frame_end = math.ceil(action.frame_range[1])

    # Force ARP's property callbacks to refresh its saved source action.
    scene.source_rig = ""
    scene.target_rig = ""
    scene.target_rig = target.name
    scene.source_rig = source.name
    scene.arp_retarget_in_place = False

    clear_mapping(scene)
    for source_bone, target_bone in BONE_MAP.items():
        item = scene.bones_map_v2.add()
        item.source_bone = source_bone
        item.name = target_bone
        item.set_as_root = source_bone == ROOT_SOURCE_BONE
        item.location = False
        item.ik = False


def activate(obj: bpy.types.Object) -> None:
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    obj.hide_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def pose_joint_direction(
    rig: bpy.types.Object, parent_name: str, child_name: str
):
    parent = rig.pose.bones[parent_name]
    child = rig.pose.bones[child_name]
    return child.head - parent.head


def match_arm_bind_pose(
    scene: bpy.types.Scene,
    source: bpy.types.Object,
    target: bpy.types.Object,
    action: bpy.types.Action,
) -> None:
    """Match anatomical arm directions instead of incompatible bone tails.

    The source character is bound with its arms hanging down. The mini target
    is bound in a T-pose. ARP transfers relative animation correctly but cannot
    infer that model-space bind-pose difference. For every baked frame, rotate
    each target limb segment in armature space until its joint-to-joint vector
    matches the corresponding animated source segment.
    """

    source_to_target = (
        target.matrix_world.inverted().to_3x3()
        @ source.matrix_world.to_3x3()
    )
    start = math.floor(action.frame_range[0])
    end = math.ceil(action.frame_range[1])

    for frame in range(start, end + 1):
        scene.frame_set(frame)

        # Parent segments must be corrected before their child segments.
        for source_segment, target_segment in ARM_SEGMENTS:
            source_direction = pose_joint_direction(source, *source_segment)
            desired_direction = source_to_target @ source_direction
            current_direction = pose_joint_direction(target, *target_segment)
            if desired_direction.length < 1e-8 or current_direction.length < 1e-8:
                continue

            correction = current_direction.normalized().rotation_difference(
                desired_direction.normalized()
            )
            pose_bone = target.pose.bones[target_segment[0]]
            pivot = pose_bone.head.copy()
            pose_bone.matrix = (
                Matrix.Translation(pivot)
                @ correction.to_matrix().to_4x4()
                @ Matrix.Translation(-pivot)
                @ pose_bone.matrix
            )
            bpy.context.view_layer.update()

            # ARP has already baked a key at every frame. These calls replace
            # the affected channels rather than adding a second animation.
            pose_bone.keyframe_insert("location", frame=frame, group=pose_bone.name)
            pose_bone.keyframe_insert(
                "rotation_quaternion", frame=frame, group=pose_bone.name
            )
            pose_bone.keyframe_insert("scale", frame=frame, group=pose_bone.name)

    scene.frame_set(start)


def curve_range(action: bpy.types.Action, bone_name: str) -> float:
    values = []
    prefix = f'pose.bones["{bone_name}"].rotation_quaternion'
    try:
        for curve in action.fcurves:
            if curve.data_path == prefix:
                values.extend(float(point.co[1]) for point in curve.keyframe_points)
    except Exception:
        return 0.0
    return max(values) - min(values) if values else 0.0


def audit_result(target: bpy.types.Object, action: bpy.types.Action) -> None:
    print("WARPED_RETARGET_AUDIT_BEGIN")
    print(f"Source: {SOURCE_ARMATURE} / {SOURCE_ACTION}")
    print(f"Target: {target.name} / {action.name}")
    print(f"Frame range: {tuple(round(value, 3) for value in action.frame_range)}")
    print(f"Mapped bones: {len(BONE_MAP)}; unique targets: {len(set(BONE_MAP.values()))}")

    for bone_name in (
        "clavicle_l",
        "upperarm_l",
        "lowerarm_l",
        "clavicle_r",
        "upperarm_r",
        "lowerarm_r",
        "thigh_l",
        "calf_l",
        "thigh_r",
        "calf_r",
    ):
        print(f"Quaternion channel range {bone_name}: {curve_range(action, bone_name):.6f}")

    print("WARPED_RETARGET_AUDIT_END")


def main() -> None:
    args = parse_arguments()
    scene = bpy.context.scene
    source = require_armature(SOURCE_ARMATURE)
    target = require_armature(TARGET_ARMATURE)
    action = bpy.data.actions.get(SOURCE_ACTION)
    if action is None:
        raise RuntimeError(f"Source action not found: {SOURCE_ACTION}")

    validate_map(source, target)
    configure_arp(scene, source, target, action)
    activate(target)

    # ARP's operator owns a separate frame range and otherwise defaults to
    # 0-10, regardless of the scene preview or the action's actual range.
    result = bpy.ops.arp.retarget(
        frame_start=math.floor(action.frame_range[0]),
        frame_end=math.ceil(action.frame_range[1]),
    )
    if "FINISHED" not in result:
        raise RuntimeError(f"Auto-Rig Pro retarget failed: {result}")
    if not target.animation_data or not target.animation_data.action:
        raise RuntimeError("Retarget completed without assigning an action to the target")

    result_action = target.animation_data.action
    result_action.name = "Warped_SyntyMini_Walk_F_Masc"
    result_action.use_fake_user = True
    match_arm_bind_pose(scene, source, target, result_action)
    audit_result(target, result_action)

    if args.output:
        bpy.ops.wm.save_as_mainfile(filepath=args.output)
        print(f"Saved retargeted test file: {args.output}")
    else:
        print("Retarget complete in memory. Review the animation, then save the .blend manually.")


main()
