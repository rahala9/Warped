"""
Warped - offline character laser slicer for Blender 4.x

SETUP
1. Import the character FBX, including its armature.
2. Select ONLY the body mesh objects to slice. Do not select equipment.
   The armature may also be selected; otherwise it is found from modifiers.
3. If you exported the whole laser wall as one OBJ object, rename that object
   LASER_CUT_SOURCE. The script finds its disconnected, thin horizontal beam
   islands automatically and ignores materials whose names contain "collision".
   Alternatively, add objects at the desired horizontal cuts and name them:
      LASER_CUT_01, LASER_CUT_02, ...
   Their world Z positions define the cuts. Alternatively, enter values in
   CUT_HEIGHTS_LOCAL below (relative to the armature origin).
4. Run this script from Blender's Scripting workspace.
5. Export the selected Slice_* and Sear_* objects from SLICED_CHARACTER.

The script does not alter the original body meshes. It evaluates the current
armature pose into static geometry, creates filled horizontal bands, and puts
all output geometry in character-root local coordinates for Roblox assembly.
"""

import bpy
from mathutils import Matrix, Vector


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

CUT_MARKER_PREFIX = "LASER_CUT_"
CUT_SOURCE_OBJECT_NAMES = ("LASER_CUT_SOURCE", "laserwall")

# Combined Roblox OBJ detection. A connected mesh island must be at least this
# many times wider than it is tall to count as a horizontal laser. Candidates
# closer than the merge tolerance are treated as pieces of the same beam.
CUT_SOURCE_MIN_HORIZONTAL_ASPECT = 20.0
CUT_SOURCE_HEIGHT_MERGE_TOLERANCE = 0.05
CUT_SOURCE_IGNORED_MATERIAL_TERMS = ("collision",)

# Used only when no CUT_MARKER_PREFIX Empty objects exist. Values are local Z
# coordinates relative to the armature object's origin.
CUT_HEIGHTS_LOCAL = []

OUTPUT_COLLECTION_NAME = "SLICED_CHARACTER"
POSED_SOURCE_NAME = "_POSED_SOURCE_DO_NOT_EXPORT"
REPLACE_PREVIOUS_OUTPUT = True

# Slightly separate bands for inspection. Set to 0.0 for production export.
INSPECTION_GAP = 0.0

# Each laser cut gets a narrow perimeter band on both adjoining pieces. The
# band is cut from the exterior skin without a filled cross-section, then given
# real radial thickness with Solidify. In Roblox, set Sear_* to Material=Neon.
CREATE_SEAR_WAFERS = True
SEAR_THICKNESS_FRACTION = 0.004
SEAR_RADIAL_THICKNESS_FRACTION = 0.003
SEAR_MATERIAL_NAME = "LaserSear_Glow"
SEAR_COLOR = (1.0, 0.035, 0.005, 1.0)

# A laser band can contain disconnected geometry (for example, the left and
# right hands). Export each disconnected island as its own MeshPart.
SEPARATE_LOOSE_ISLANDS = True

# Lower the arms most of the way from their imported pose toward the downward
# target, retaining a natural outward angle instead of forcing them vertical.
ARM_LOWERING_STRENGTH = 0.75
ARM_OUTWARD_AMOUNT = 0.10

# Bone aliases are normalized before matching, so punctuation and case do not
# matter. Add the exact upper-arm names from your rig if automatic matching
# does not find them.
LEFT_UPPER_ARM_ALIASES = (
    "leftarm",
    "leftupperarm",
    "shoulder_l",
    "upperarmleft",
    "upperarml",
    "lupperarm",
    "mixamorigleftarm",
)
RIGHT_UPPER_ARM_ALIASES = (
    "rightarm",
    "rightupperarm",
    "shoulder_r",
    "upperarmright",
    "upperarmr",
    "rupperarm",
    "mixamorigrightarm",
)

BISECT_EPSILON = 0.00001


# ---------------------------------------------------------------------------
# Scene helpers
# ---------------------------------------------------------------------------

def normalized_name(value):
    return "".join(character for character in value.lower() if character.isalnum())


def find_pose_bone(armature, aliases):
    normalized_aliases = tuple(normalized_name(alias) for alias in aliases)
    exact = {}
    for pose_bone in armature.pose.bones:
        exact[normalized_name(pose_bone.name)] = pose_bone

    for alias in normalized_aliases:
        if alias in exact:
            return exact[alias]

    for bone_name, pose_bone in exact.items():
        for alias in normalized_aliases:
            if alias in bone_name:
                return pose_bone
    return None


def find_armature(mesh_objects, selected_objects):
    for obj in selected_objects:
        if obj.type == "ARMATURE":
            return obj

    for mesh_obj in mesh_objects:
        for modifier in mesh_obj.modifiers:
            if modifier.type == "ARMATURE" and modifier.object:
                return modifier.object
        parent = mesh_obj.parent
        while parent:
            if parent.type == "ARMATURE":
                return parent
            parent = parent.parent
    return None


def delete_collection(collection):
    for child in list(collection.children):
        delete_collection(child)
    for obj in list(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(collection)


def create_output_collection():
    existing = bpy.data.collections.get(OUTPUT_COLLECTION_NAME)
    if existing:
        if not REPLACE_PREVIOUS_OUTPUT:
            raise RuntimeError(
                f"Collection {OUTPUT_COLLECTION_NAME!r} already exists. "
                "Delete it or enable REPLACE_PREVIOUS_OUTPUT."
            )
        delete_collection(existing)

    collection = bpy.data.collections.new(OUTPUT_COLLECTION_NAME)
    bpy.context.scene.collection.children.link(collection)
    return collection


def move_object_to_collection(obj, collection):
    for current_collection in list(obj.users_collection):
        current_collection.objects.unlink(obj)
    collection.objects.link(obj)


# ---------------------------------------------------------------------------
# Pose capture
# ---------------------------------------------------------------------------

def point_upper_arm_down(armature, pose_bone, side_sign):
    """Rotate the current upper-arm direction toward world down."""
    bpy.context.view_layer.update()

    current_direction = pose_bone.tail - pose_bone.head
    if current_direction.length < BISECT_EPSILON:
        raise RuntimeError(f"Bone {pose_bone.name!r} has zero length")
    current_direction.normalize()

    # Convert a slightly outward world-down direction to armature object space.
    target_world = Vector((side_sign * ARM_OUTWARD_AMOUNT, 0.0, -1.0)).normalized()
    target_local = armature.matrix_world.to_3x3().inverted() @ target_world
    target_local.normalize()

    desired_direction = current_direction.lerp(
        target_local,
        max(0.0, min(1.0, ARM_LOWERING_STRENGTH)),
    )
    if desired_direction.length < BISECT_EPSILON:
        desired_direction = target_local
    desired_direction.normalize()

    rotation = current_direction.rotation_difference(desired_direction)
    pivot = Matrix.Translation(pose_bone.head)
    pose_bone.matrix = pivot @ rotation.to_matrix().to_4x4() @ pivot.inverted() @ pose_bone.matrix
    bpy.context.view_layer.update()


def lower_arms(armature):
    left_arm = find_pose_bone(armature, LEFT_UPPER_ARM_ALIASES)
    right_arm = find_pose_bone(armature, RIGHT_UPPER_ARM_ALIASES)

    if not left_arm:
        print("[WarpedSlicer] WARNING: left upper-arm bone was not found")
    else:
        point_upper_arm_down(armature, left_arm, -1.0)
        print(f"[WarpedSlicer] Lowered left arm using {left_arm.name}")

    if not right_arm:
        print("[WarpedSlicer] WARNING: right upper-arm bone was not found")
    else:
        point_upper_arm_down(armature, right_arm, 1.0)
        print(f"[WarpedSlicer] Lowered right arm using {right_arm.name}")

    if not left_arm and not right_arm:
        raise RuntimeError(
            "No upper-arm bones were found. Add your rig's bone names to "
            "LEFT_UPPER_ARM_ALIASES and RIGHT_UPPER_ARM_ALIASES."
        )


def evaluated_static_copy(source, root_inverse, depsgraph, collection):
    evaluated = source.evaluated_get(depsgraph)
    mesh = bpy.data.meshes.new_from_object(
        evaluated,
        preserve_all_data_layers=True,
        depsgraph=depsgraph,
    )
    if not mesh:
        raise RuntimeError(f"Could not evaluate mesh {source.name!r}")

    # Store geometry in character-root local space and leave the output object
    # at identity. Every exported band therefore shares the same pivot.
    mesh.transform(root_inverse @ source.matrix_world)
    result = bpy.data.objects.new(source.name + "_Posed", mesh)
    collection.objects.link(result)
    result.matrix_world = Matrix.Identity(4)
    return result


def join_objects(objects, active_name):
    if not objects:
        raise RuntimeError("There are no evaluated body meshes to join")

    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.hide_set(False)
        obj.hide_viewport = False
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = active_name
    joined.data.name = active_name + "_Mesh"
    return joined


# ---------------------------------------------------------------------------
# Cutting
# ---------------------------------------------------------------------------

def connected_vertex_components(mesh):
    adjacency = [set() for _ in mesh.vertices]
    for edge in mesh.edges:
        first, second = edge.vertices
        adjacency[first].add(second)
        adjacency[second].add(first)

    remaining = set(range(len(mesh.vertices)))
    components = []
    while remaining:
        start = remaining.pop()
        component = {start}
        stack = [start]
        while stack:
            current = stack.pop()
            for neighbor in adjacency[current]:
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    component.add(neighbor)
                    stack.append(neighbor)
        components.append(component)
    return components


def vertex_material_names(mesh):
    names = [set() for _ in mesh.vertices]
    for polygon in mesh.polygons:
        if polygon.material_index < len(mesh.materials):
            material = mesh.materials[polygon.material_index]
            material_name = material.name.lower() if material else ""
        else:
            material_name = ""
        for vertex_index in polygon.vertices:
            names[vertex_index].add(material_name)
    return names


def material_set_is_ignored(material_names):
    populated = {name for name in material_names if name}
    return bool(populated) and all(
        any(term in name for term in CUT_SOURCE_IGNORED_MATERIAL_TERMS)
        for name in populated
    )


def merge_nearby_heights(heights, tolerance):
    if not heights:
        return []
    clusters = [[height] for height in sorted(heights)]
    merged = []
    current = clusters[0]
    for cluster in clusters[1:]:
        height = cluster[0]
        if height - current[-1] <= tolerance:
            current.append(height)
        else:
            merged.append(sum(current) / len(current))
            current = [height]
    merged.append(sum(current) / len(current))
    return merged


def combined_source_cut_heights(root_inverse):
    accepted_names = {name.lower() for name in CUT_SOURCE_OBJECT_NAMES}
    source = next(
        (
            obj for obj in bpy.context.scene.objects
            if obj.name.lower() in accepted_names
        ),
        None,
    )
    if not source or source.type != "MESH":
        return []

    mesh = source.data
    materials_by_vertex = vertex_material_names(mesh)
    candidates = []
    for component in connected_vertex_components(mesh):
        component_materials = set()
        local_points = []
        for vertex_index in component:
            component_materials.update(materials_by_vertex[vertex_index])
            world_point = source.matrix_world @ mesh.vertices[vertex_index].co
            local_points.append(root_inverse @ world_point)

        if material_set_is_ignored(component_materials) or not local_points:
            continue

        x_values = [point.x for point in local_points]
        y_values = [point.y for point in local_points]
        z_values = [point.z for point in local_points]
        horizontal_span = max(max(x_values) - min(x_values), max(y_values) - min(y_values))
        vertical_span = max(z_values) - min(z_values)
        aspect = horizontal_span / max(vertical_span, BISECT_EPSILON)
        if horizontal_span > BISECT_EPSILON and aspect >= CUT_SOURCE_MIN_HORIZONTAL_ASPECT:
            candidates.append((min(z_values) + max(z_values)) * 0.5)

    heights = merge_nearby_heights(candidates, CUT_SOURCE_HEIGHT_MERGE_TOLERANCE)
    if heights:
        print(
            f"[WarpedSlicer] Found {len(heights)} horizontal laser height(s) "
            f"inside {source.name!r}: {heights}"
        )
    return heights


def get_cut_heights(root_inverse):
    marker_heights = []
    reserved_source_names = {name.lower() for name in CUT_SOURCE_OBJECT_NAMES}
    for obj in bpy.context.scene.objects:
        # Roblox marker Parts import as meshes; manually created Blender markers
        # are usually Empties. Only the name and object origin matter here.
        if (
            obj.name.startswith(CUT_MARKER_PREFIX)
            and obj.name.lower() not in reserved_source_names
        ):
            local_position = root_inverse @ obj.matrix_world.translation
            marker_heights.append(local_position.z)

    source_heights = combined_source_cut_heights(root_inverse) if not marker_heights else []
    heights = marker_heights or source_heights or list(CUT_HEIGHTS_LOCAL)
    heights = sorted(set(round(float(height), 6) for height in heights))
    if not heights:
        raise RuntimeError(
            f"No cut heights found. Rename the combined wall object "
            f"{CUT_SOURCE_OBJECT_NAMES[0]!r} or 'laserwall', add objects named "
            f"{CUT_MARKER_PREFIX}01, "
            f"{CUT_MARKER_PREFIX}02, etc., or populate CUT_HEIGHTS_LOCAL."
        )
    return heights


def mesh_z_bounds(obj):
    if not obj.data.vertices:
        return None, None
    values = [vertex.co.z for vertex in obj.data.vertices]
    return min(values), max(values)


def bisect_keep_above(obj, height, use_fill=True):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.bisect(
        plane_co=(0.0, 0.0, height),
        plane_no=(0.0, 0.0, 1.0),
        use_fill=use_fill,
        clear_inner=True,
        clear_outer=False,
        threshold=BISECT_EPSILON,
    )
    bpy.ops.object.mode_set(mode="OBJECT")


def bisect_keep_below(obj, height, use_fill=True):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.bisect(
        plane_co=(0.0, 0.0, height),
        plane_no=(0.0, 0.0, 1.0),
        use_fill=use_fill,
        clear_inner=False,
        clear_outer=True,
        threshold=BISECT_EPSILON,
    )
    bpy.ops.object.mode_set(mode="OBJECT")


def duplicate_mesh_object(source, collection, name):
    duplicate = source.copy()
    duplicate.data = source.data.copy()
    collection.objects.link(duplicate)
    duplicate.name = name
    duplicate.data.name = name + "_Mesh"
    duplicate.hide_set(False)
    duplicate.hide_viewport = False
    duplicate.hide_render = False
    return duplicate


def create_sear_material():
    material = bpy.data.materials.get(SEAR_MATERIAL_NAME)
    if not material:
        material = bpy.data.materials.new(SEAR_MATERIAL_NAME)
    material.diffuse_color = SEAR_COLOR
    material.use_nodes = True
    nodes = material.node_tree.nodes
    principled = nodes.get("Principled BSDF")
    if principled:
        if "Base Color" in principled.inputs:
            principled.inputs["Base Color"].default_value = SEAR_COLOR
        if "Emission Color" in principled.inputs:
            principled.inputs["Emission Color"].default_value = SEAR_COLOR
        elif "Emission" in principled.inputs:
            principled.inputs["Emission"].default_value = SEAR_COLOR
        if "Emission Strength" in principled.inputs:
            principled.inputs["Emission Strength"].default_value = 8.0
    return material


def cut_object_to_interval(obj, lower, upper, use_fill=True):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    if lower is not None:
        bisect_keep_above(obj, lower, use_fill=use_fill)
    if upper is not None:
        bisect_keep_below(obj, upper, use_fill=use_fill)


def object_bounds_center(obj):
    if not obj.data.vertices:
        return Vector()
    values = [vertex.co for vertex in obj.data.vertices]
    minimum = Vector((
        min(value.x for value in values),
        min(value.y for value in values),
        min(value.z for value in values),
    ))
    maximum = Vector((
        max(value.x for value in values),
        max(value.y for value in values),
        max(value.z for value in values),
    ))
    return (minimum + maximum) * 0.5


def separate_loose_islands(obj, base_name):
    if not SEPARATE_LOOSE_ISLANDS or not obj.data.polygons:
        obj.name = base_name
        obj.data.name = base_name + "_Mesh"
        return [obj]

    bpy.ops.object.select_all(action="DESELECT")
    obj.hide_set(False)
    obj.hide_viewport = False
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")

    islands = [
        candidate for candidate in bpy.context.selected_objects
        if candidate.type == "MESH" and candidate.data.polygons
    ]
    islands.sort(key=lambda candidate: tuple(object_bounds_center(candidate)))
    if len(islands) == 1:
        islands[0].name = base_name
        islands[0].data.name = base_name + "_Mesh"
    else:
        for index, island in enumerate(islands, start=1):
            island.name = f"{base_name}_Island_{index:02d}"
            island.data.name = island.name + "_Mesh"
    return islands


def solidify_sear_band(obj, radial_thickness):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new(name="LaserSearThickness", type="SOLIDIFY")
    modifier.thickness = radial_thickness
    modifier.offset = 0.0
    modifier.use_rim = True
    modifier.use_rim_only = False
    modifier.use_even_offset = True
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def inspection_offset(band_index, band_count):
    return (band_index - (band_count - 1) * 0.5) * INSPECTION_GAP


def make_sear_wafers(
    posed_source,
    cut_heights,
    thickness,
    radial_thickness,
    band_count,
    collection,
):
    if not CREATE_SEAR_WAFERS:
        return []

    material = create_sear_material()
    sears = []
    for cut_index, height in enumerate(cut_heights, start=1):
        lower_band_index = cut_index - 1
        upper_band_index = cut_index

        lower_sear = duplicate_mesh_object(
            posed_source,
            collection,
            f"Sear_Cut_{cut_index:02d}_Lower_Band_{lower_band_index:02d}",
        )
        cut_object_to_interval(
            lower_sear,
            height - thickness,
            height,
            use_fill=False,
        )
        lower_sear.location.z += inspection_offset(lower_band_index, band_count)
        if lower_sear.data.polygons:
            solidify_sear_band(lower_sear, radial_thickness)
            lower_sear.data.materials.clear()
            lower_sear.data.materials.append(material)
            lower_islands = separate_loose_islands(
                lower_sear,
                f"Sear_Cut_{cut_index:02d}_Lower_Band_{lower_band_index:02d}",
            )
            for island in lower_islands:
                island["WarpedSliceBand"] = lower_band_index
                island["WarpedLaserSear"] = True
            sears.extend(lower_islands)
        else:
            bpy.data.objects.remove(lower_sear, do_unlink=True)

        upper_sear = duplicate_mesh_object(
            posed_source,
            collection,
            f"Sear_Cut_{cut_index:02d}_Upper_Band_{upper_band_index:02d}",
        )
        cut_object_to_interval(
            upper_sear,
            height,
            height + thickness,
            use_fill=False,
        )
        upper_sear.location.z += inspection_offset(upper_band_index, band_count)
        if upper_sear.data.polygons:
            solidify_sear_band(upper_sear, radial_thickness)
            upper_sear.data.materials.clear()
            upper_sear.data.materials.append(material)
            upper_islands = separate_loose_islands(
                upper_sear,
                f"Sear_Cut_{cut_index:02d}_Upper_Band_{upper_band_index:02d}",
            )
            for island in upper_islands:
                island["WarpedSliceBand"] = upper_band_index
                island["WarpedLaserSear"] = True
            sears.extend(upper_islands)
        else:
            bpy.data.objects.remove(upper_sear, do_unlink=True)

    return sears


def make_bands(posed_source, cut_heights, collection):
    source_min, source_max = mesh_z_bounds(posed_source)
    relevant = [
        height
        for height in cut_heights
        if source_min + BISECT_EPSILON < height < source_max - BISECT_EPSILON
    ]
    if not relevant:
        raise RuntimeError(
            f"No cut marker intersects the character (character Z {source_min:.3f} "
            f"to {source_max:.3f}; cuts {cut_heights})"
        )

    boundaries = [None] + relevant + [None]
    bands = []
    band_count = len(boundaries) - 1
    sear_thickness = (source_max - source_min) * SEAR_THICKNESS_FRACTION
    sear_radial_thickness = (
        (source_max - source_min) * SEAR_RADIAL_THICKNESS_FRACTION
    )

    if CREATE_SEAR_WAFERS:
        for lower, upper in zip(relevant, relevant[1:]):
            if upper - lower <= sear_thickness * 2.0:
                raise RuntimeError(
                    "Adjacent laser cuts are too close for the configured "
                    "SEAR_THICKNESS_FRACTION"
                )

    for index in range(band_count):
        lower = boundaries[index]
        upper = boundaries[index + 1]
        if lower is None:
            label = "Bottom"
        elif upper is None:
            label = "Top"
        else:
            label = f"Middle_{index:02d}"

        band = duplicate_mesh_object(
            posed_source,
            collection,
            f"Slice_{index:02d}_{label}",
        )
        bpy.ops.object.select_all(action="DESELECT")
        band.select_set(True)

        body_lower = lower + sear_thickness if lower is not None and CREATE_SEAR_WAFERS else lower
        body_upper = upper - sear_thickness if upper is not None and CREATE_SEAR_WAFERS else upper
        cut_object_to_interval(band, body_lower, body_upper)

        # Remove any empty result caused by a marker exactly outside topology.
        if not band.data.polygons:
            bpy.data.objects.remove(band, do_unlink=True)
            continue

        band.location.z += inspection_offset(index, band_count)
        band_islands = separate_loose_islands(
            band,
            f"Slice_{index:02d}_{label}",
        )
        for island in band_islands:
            island["WarpedSliceBand"] = index
        bands.extend(band_islands)

    sears = make_sear_wafers(
        posed_source,
        relevant,
        sear_thickness,
        sear_radial_thickness,
        band_count,
        collection,
    )
    return bands, sears


def add_export_root(collection):
    root = bpy.data.objects.new("CharacterSliceRoot", None)
    root.empty_display_type = "PLAIN_AXES"
    root.empty_display_size = 0.25
    collection.objects.link(root)
    return root


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if bpy.context.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")

    selected_objects = list(bpy.context.selected_objects)
    mesh_objects = [obj for obj in selected_objects if obj.type == "MESH"]
    if not mesh_objects:
        raise RuntimeError("Select at least one body mesh object before running the script")

    armature = find_armature(mesh_objects, selected_objects)
    if not armature:
        raise RuntimeError("Could not find the character armature from the selected body meshes")

    output_collection = create_output_collection()
    root_inverse = armature.matrix_world.inverted()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    original_pose = {
        pose_bone.name: pose_bone.matrix.copy()
        for pose_bone in armature.pose.bones
    }
    try:
        lower_arms(armature)
        bpy.context.view_layer.update()
        posed_parts = [
            evaluated_static_copy(obj, root_inverse, depsgraph, output_collection)
            for obj in mesh_objects
        ]
    finally:
        for bone_name, matrix in original_pose.items():
            pose_bone = armature.pose.bones.get(bone_name)
            if pose_bone:
                pose_bone.matrix = matrix
        bpy.context.view_layer.update()

    posed_source = join_objects(posed_parts, POSED_SOURCE_NAME)
    move_object_to_collection(posed_source, output_collection)

    cut_heights = get_cut_heights(root_inverse)
    bands, sears = make_bands(posed_source, cut_heights, output_collection)
    posed_source.hide_render = True
    posed_source.hide_viewport = True
    posed_source.hide_set(True)

    add_export_root(output_collection)

    bpy.ops.object.select_all(action="DESELECT")
    for export_object in bands + sears:
        export_object.select_set(True)
    if bands:
        bpy.context.view_layer.objects.active = bands[0]

    print(
        f"[WarpedSlicer] Complete: {len(bands)} body bands and {len(sears)} "
        f"sear wafers created in {OUTPUT_COLLECTION_NAME!r} at cuts {cut_heights}"
    )
    print("[WarpedSlicer] Export the selected Slice_* and Sear_* objects as FBX for Roblox")


if __name__ == "__main__":
    main()

