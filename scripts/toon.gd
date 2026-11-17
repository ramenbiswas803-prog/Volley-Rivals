class_name Toon
extends RefCounted
# Anime/cel-shaded look ke liye helper: toon lighting + black outline (inverted hull).

static var _outline: ShaderMaterial

static func outline_material() -> ShaderMaterial:
    if _outline == null:
        var sh := Shader.new()
        sh.code = """shader_type spatial;
render_mode cull_front, unshaded;
uniform float thickness = 0.025;
void vertex() { VERTEX += NORMAL * thickness; }
void fragment() { ALBEDO = vec3(0.04, 0.04, 0.10); }"""
        _outline = ShaderMaterial.new()
        _outline.shader = sh
    return _outline

static func make(color: Color, outline: bool = true) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    m.specular_mode = BaseMaterial3D.SPECULAR_TOON
    m.roughness = 0.7
    if outline:
        m.next_pass = outline_material()
    return m

static func mesh_node(mesh: Mesh, color: Color, pos: Vector3 = Vector3.ZERO, outline: bool = true) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = make(color, outline)
    mi.position = pos
    return mi
