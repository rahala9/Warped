import bpy
import sys


def import_rig(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if hasattr(bpy.ops.wm, "fbx_import"):
        bpy.ops.wm.fbx_import(filepath=path)
    else:
        bpy.ops.import_scene.fbx(filepath=path)
    armature = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    meshes = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    return {
        bone.name: bone.matrix_local.copy()
        for bone in armature.data.bones
    }, [(mesh.name, mesh.matrix_local.copy()) for mesh in meshes]


def main(left_path, right_path):
    left, left_meshes = import_rig(left_path)
    right, right_meshes = import_rig(right_path)
    common = sorted(set(left) & set(right))
    left_only = sorted(set(left) - set(right))
    right_only = sorted(set(right) - set(left))
    largest = []
    for name in common:
        matrix_delta = max(
            abs(left[name][row][column] - right[name][row][column])
            for row in range(4)
            for column in range(4)
        )
        largest.append((matrix_delta, name))
    largest.sort(reverse=True)
    print("RIG_COMPARE")
    print("LEFT_BONES", len(left), "RIGHT_BONES", len(right), "COMMON", len(common))
    print("LEFT_ONLY", left_only)
    print("RIGHT_ONLY", right_only)
    print("MAX_BIND_MATRIX_DELTA", largest[0] if largest else None)
    print("TOP_BIND_DELTAS", largest[:10])
    print("LEFT_MESHES", [(name, tuple(round(v, 6) for v in matrix.translation)) for name, matrix in left_meshes])
    print("RIGHT_MESHES", [(name, tuple(round(v, 6) for v in matrix.translation)) for name, matrix in right_meshes])


if __name__ == "__main__":
    main(sys.argv[-2], sys.argv[-1])
