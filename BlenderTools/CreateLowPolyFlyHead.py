"""Create a stylized low-poly fly head in Blender 4.x.

Run from Blender's Scripting workspace. The model is created around the world
origin in a collection named ``LowPolyFlyHead``. Re-running replaces only that
collection.

The model faces Blender -Y. The compound-eye color pattern is assigned directly
to the eye mesh's existing triangular faces, so it adds no extra geometry.
Every mesh also receives a POINT-domain color attribute named ``Color`` for
FBX export and Roblox Studio's vertex-color importer.
"""

import bpy
from mathutils import Vector


# ---------------------------------------------------------------------------
# Art direction controls
# ---------------------------------------------------------------------------

MODEL_SCALE = 1.0
ADD_WINGS = True
ADD_ANTENNAE = True

COLLECTION_NAME = "LowPolyFlyHead"


def material(name, color, metallic=0.0, roughness=0.55, transmission=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*color[:3], color[3])
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if "Transmission Weight" in bsdf.inputs:
        bsdf.inputs["Transmission Weight"].default_value = transmission
    elif "Transmission" in bsdf.inputs:
        bsdf.inputs["Transmission"].default_value = transmission
    mat.surface_render_method = "DITHERED" if color[3] < 1.0 else "DITHERED"
    return mat


def link_to_collection(obj, collection):
    for old_collection in list(obj.users_collection):
        old_collection.objects.unlink(obj)
    collection.objects.link(obj)


def create_ico(name, location, scale, subdivisions, mat, collection):
    bpy.ops.mesh.primitive_ico_sphere_add(
        subdivisions=subdivisions,
        radius=1.0,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    link_to_collection(obj, collection)
    return obj


def create_cylinder_between(name, start, end, radius, vertices, mat, collection):
    start = Vector(start)
    end = Vector(end)
    delta = end - start
    midpoint = (start + end) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=delta.length,
        location=midpoint,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
    obj.data.materials.append(mat)
    link_to_collection(obj, collection)
    return obj


def create_wing(name, side, mat, collection):
    # A deliberately angular four-vertex wing with a shallow center ridge.
    sx = float(side)
    vertices = [
        (0.35 * sx, 0.10, 0.40),
        (1.35 * sx, 0.14, 0.66),
        (1.75 * sx, 0.18, 0.42),
        (1.20 * sx, 0.05, 0.17),
        (0.74 * sx, -0.01, 0.24),
    ]
    faces = [(0, 1, 2, 3, 4)]
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.data.materials.append(mat)

    solidify = obj.modifiers.new("ThinWing", "SOLIDIFY")
    solidify.thickness = 0.018
    solidify.offset = 0.0
    return obj


def add_roblox_vertex_colors(obj):
    """Bake material-slot colors to a Roblox-compatible vertex attribute.

    Blender materials are retained for viewport preview, but Roblox does not
    treat those material Base Colors as vertex colors. A POINT/FLOAT_COLOR
    attribute exports through FBX as actual per-vertex RGB data.

    Vertices shared by differently colored polygons receive the average of the
    adjacent face colors. This keeps the mesh topology unchanged and avoids the
    large vertex increase caused by splitting every colored face corner.
    """
    if obj.type != "MESH":
        return False

    mesh = obj.data
    existing = mesh.color_attributes.get("Color")
    if existing:
        mesh.color_attributes.remove(existing)

    color_attribute = mesh.color_attributes.new(
        name="Color",
        type="FLOAT_COLOR",
        domain="POINT",
    )

    sums = [[0.0, 0.0, 0.0, 0.0] for _ in mesh.vertices]
    counts = [0 for _ in mesh.vertices]

    for polygon in mesh.polygons:
        if len(mesh.materials) > 0:
            material_index = min(polygon.material_index, len(mesh.materials) - 1)
            face_color = mesh.materials[material_index].diffuse_color
        else:
            face_color = (1.0, 1.0, 1.0, 1.0)

        for vertex_index in polygon.vertices:
            sums[vertex_index][0] += face_color[0]
            sums[vertex_index][1] += face_color[1]
            sums[vertex_index][2] += face_color[2]
            sums[vertex_index][3] += face_color[3]
            counts[vertex_index] += 1

    for vertex_index, color_data in enumerate(color_attribute.data):
        count = max(1, counts[vertex_index])
        if counts[vertex_index] == 0:
            color_data.color = (1.0, 1.0, 1.0, 1.0)
        else:
            color_data.color = tuple(channel / count for channel in sums[vertex_index])

    # FBX uses the active/render color layer. These properties vary slightly
    # between Blender releases, so only set them when the API exposes them.
    color_index = len(mesh.color_attributes) - 1
    if hasattr(mesh.color_attributes, "active_color_index"):
        mesh.color_attributes.active_color_index = color_index
    if hasattr(mesh.color_attributes, "render_color_index"):
        mesh.color_attributes.render_color_index = color_index

    return True


def create_compound_eye(side, rim_mat, eye_mat, lens_materials, collection):
    sx = float(side)
    center = Vector((0.38 * sx, -0.40, 0.08))
    radii = Vector((0.35, 0.27, 0.44))
    create_ico(
        "LeftEyeRim" if side < 0 else "RightEyeRim",
        center + Vector((0.0, 0.035, 0.0)),
        radii * 1.13,
        2,
        rim_mat,
        collection,
    )
    eye = create_ico(
        "LeftCompoundEye" if side < 0 else "RightCompoundEye",
        center,
        radii,
        2,
        eye_mat,
        collection,
    )

    # Reuse the Icosphere's low-poly triangles as ommatidia. Multiple materials
    # create a compound-eye mosaic without adding even one vertex.
    for lens_material in lens_materials:
        eye.data.materials.append(lens_material)
    for polygon in eye.data.polygons:
        center_local = polygon.center
        if center_local.y < -0.58 and abs(center_local.x) < 0.26 and abs(center_local.z) < 0.26:
            polygon.material_index = len(lens_materials)  # Dark central cluster.
        elif center_local.y < 0.34:
            polygon.material_index = 1 + (polygon.index % (len(lens_materials) - 1))
        else:
            polygon.material_index = 0

    return eye


def main():
    old_collection = bpy.data.collections.get(COLLECTION_NAME)
    if old_collection:
        for obj in list(old_collection.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(old_collection)

    collection = bpy.data.collections.new(COLLECTION_NAME)
    bpy.context.scene.collection.children.link(collection)

    head_mat = material("FlyHead_Blue", (0.045, 0.16, 0.31, 1.0), metallic=0.15, roughness=0.38)
    rim_mat = material("FlyEyeRim_Teal", (0.055, 0.30, 0.27, 1.0), metallic=0.05, roughness=0.48)
    eye_mat = material("FlyEye_DeepRed", (0.19, 0.003, 0.006, 1.0), metallic=0.15, roughness=0.28)
    lens_materials = [
        material("FlyLens_Ruby", (0.72, 0.006, 0.012, 1.0), metallic=0.2, roughness=0.20),
        material("FlyLens_Crimson", (0.38, 0.001, 0.006, 1.0), metallic=0.35, roughness=0.23),
        material("FlyLens_Amber", (0.90, 0.055, 0.008, 1.0), metallic=0.15, roughness=0.24),
        material("FlyLens_Dark", (0.07, 0.002, 0.006, 1.0), metallic=0.3, roughness=0.18),
    ]
    mouth_mat = material("FlyMouth_Black", (0.008, 0.006, 0.012, 1.0), metallic=0.05, roughness=0.5)
    wing_mat = material("FlyWing_Translucent", (0.52, 0.84, 1.0, 0.42), metallic=0.0, roughness=0.22, transmission=0.25)

    create_ico("FlyHead", (0.0, 0.0, 0.05), (0.72, 0.58, 0.72), 2, head_mat, collection)
    create_compound_eye(-1, rim_mat, eye_mat, lens_materials, collection)
    create_compound_eye(1, rim_mat, eye_mat, lens_materials, collection)

    # Long, slightly downward proboscis matching the reference silhouette.
    create_ico("Muzzle", (0.0, -0.61, -0.18), (0.24, 0.24, 0.19), 1, mouth_mat, collection)
    create_cylinder_between(
        "Proboscis",
        (0.0, -0.73, -0.21),
        (0.0, -1.38, -0.40),
        0.075,
        7,
        mouth_mat,
        collection,
    )

    if ADD_ANTENNAE:
        for side in (-1, 1):
            create_cylinder_between(
                "LeftAntenna" if side < 0 else "RightAntenna",
                (0.16 * side, -0.53, 0.42),
                (0.34 * side, -0.77, 0.67),
                0.026,
                6,
                mouth_mat,
                collection,
            )
            create_ico(
                "LeftAntennaTip" if side < 0 else "RightAntennaTip",
                (0.34 * side, -0.77, 0.67),
                (0.065, 0.065, 0.065),
                1,
                mouth_mat,
                collection,
            )

    if ADD_WINGS:
        create_wing("LeftWing", -1, wing_mat, collection)
        create_wing("RightWing", 1, wing_mat, collection)

    colored_mesh_count = 0
    for obj in collection.objects:
        if add_roblox_vertex_colors(obj):
            colored_mesh_count += 1

    root = bpy.data.objects.new("FlyHead_EXPORT_ROOT", None)
    collection.objects.link(root)
    root.empty_display_type = "PLAIN_AXES"
    root.scale = (MODEL_SCALE, MODEL_SCALE, MODEL_SCALE)
    for obj in collection.objects:
        if obj != root and obj.parent is None:
            obj.parent = root

    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    print(
        f"[Warped] Created {COLLECTION_NAME}: "
        f"low-geometry compound eyes and Roblox vertex colors on {colored_mesh_count} meshes, "
        "facing Blender -Y"
    )


if __name__ == "__main__":
    main()
