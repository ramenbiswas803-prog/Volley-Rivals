class_name Ball
extends RigidBody3D
# Volleyball physics: RigidBody3D, bounce, spin aur landing detection.

signal landed(pos: Vector3)

const RADIUS := 0.21
var rally_live: bool = false

func _ready() -> void:
    mass = 0.27
    linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
    linear_damp = 0.0
    angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
    angular_damp = 0.4
    continuous_cd = true
    contact_monitor = true
    max_contacts_reported = 4
    collision_layer = 2   # ball layer
    collision_mask = 1    # sirf world (floor/net) se takrayega

    var pm := PhysicsMaterial.new()
    pm.bounce = 0.5
    pm.friction = 0.6
    physics_material_override = pm

    var cs := CollisionShape3D.new()
    var sh := SphereShape3D.new()
    sh.radius = RADIUS
    cs.shape = sh
    add_child(cs)

    var sm := SphereMesh.new()
    sm.radius = RADIUS
    sm.height = RADIUS * 2.0
    sm.radial_segments = 24
    sm.rings = 12
    var mi := MeshInstance3D.new()
    mi.mesh = sm
    var shader := Shader.new()
    shader.code = """shader_type spatial;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
    float band = sin(lp.x * 38.0 + lp.y * 14.0) + sin(lp.z * 38.0 - lp.y * 10.0);
    vec3 c = vec3(1.0, 0.93, 0.78);
    if (band > 0.9) { c = vec3(0.10, 0.45, 0.95); }
    else if (band < -0.9) { c = vec3(1.0, 0.80, 0.10); }
    ALBEDO = c;
    ROUGHNESS = 0.45;
}"""
    var mat := ShaderMaterial.new()
    mat.shader = shader
    mi.material_override = mat
    add_child(mi)

    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if rally_live and body.is_in_group("floor"):
        rally_live = false
        landed.emit(global_position)

# Ball ko hawa mein rok do (serve se pehle).
func hold(pos: Vector3) -> void:
    freeze = true
    linear_velocity = Vector3.ZERO
    angular_velocity = Vector3.ZERO
    global_position = pos
    rally_live = false

# Projectile maths: from se to tak t seconds mein pahunchne ki velocity.
func calc_velocity(from: Vector3, to: Vector3, t: float) -> Vector3:
    var g: float = ProjectSettings.get_setting("physics/3d/default_gravity")
    return (to - from - Vector3(0.0, -0.5 * g * t * t, 0.0)) / t

func place_and_launch(pos: Vector3, vel: Vector3) -> void:
    freeze = true
    linear_velocity = Vector3.ZERO
    global_position = pos
    await get_tree().physics_frame
    freeze = false
    linear_velocity = vel
    angular_velocity = Vector3(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
    rally_live = true

func hit(vel: Vector3) -> void:
    linear_velocity = vel
    angular_velocity = Vector3(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
    rally_live = true
