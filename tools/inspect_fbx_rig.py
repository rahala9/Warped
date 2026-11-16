import bpy
import sys


def main(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if hasattr(bpy.ops.wm, "fbx_import"):
        bpy.ops.wm.fbx_import(filepath=path)
    else:
        bpy.ops.import_scene.fbx(filepath=path)

    print("FBX_RIG_REPORT", path)
    for obj in sorted(bpy.data.objects, key=lambda value: value.name):
        print(
            "OBJECT",
            obj.name,
            "type=", obj.type,
            "parent=", obj.parent.name if obj.parent else "nil",
            "parent_type=", obj.parent_type,
            "location=", tuple(round(value, 6) for value in obj.location),
            "rotation=", tuple(round(value, 6) for value in obj.rotation_euler),
            "scale=", tuple(round(value, 6) for value in obj.scale),
        )
        if obj.type == "MESH":
            print("  VERTICES", len(obj.data.vertices), "POLYGONS", len(obj.data.polygons))
            print("  VERTEX_GROUPS", len(obj.vertex_groups), [group.name for group in obj.vertex_groups[:12]])
            for modifier in obj.modifiers:
                print(
                    "  MODIFIER",
                    modifier.name,
                    modifier.type,
                    getattr(modifier, "object", None).name if getattr(modifier, "object", None) else "nil",
                )
        elif obj.type == "ARMATURE":
            print("  BONES", len(obj.data.bones))
            for bone in obj.data.bones:
                print(
                    "  BONE",
                    bone.name,
                    "parent=", bone.parent.name if bone.parent else "nil",
                    "head=", tuple(round(value, 6) for value in bone.head_local),
                    "tail=", tuple(round(value, 6) for value in bone.tail_local),
                    "roll=", round(bone.matrix_local.to_euler().z, 6),
                )

    print("ACTIONS", len(bpy.data.actions), [action.name for action in bpy.data.actions])


if __name__ == "__main__":
    main(sys.argv[-1])
