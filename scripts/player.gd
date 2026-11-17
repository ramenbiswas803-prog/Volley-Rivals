class_name Player
extends CharacterBody3D
# Ek volleyball player: code se bana anime-style model + movement + jump.

const GRAVITY := 22.0

var speed: float = 6.0
var jump_velocity: float = 7.0
var move_input := Vector2.ZERO   # x = right(+z), y = down-screen (forward = -y)
var controlled: bool = false
var idle_face: float = 1.0       # +1 = +X (opponent side), -1 = -X
var min_x: float = -9.6
var max_x: float = -0.8
var stats: Dictionary = {}

var model: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var blob: MeshInstance3D
var run_time: float = 0.0
var idle_t: float = 0.0

func setup(s: Dictionary, is_controlled: bool, face: float, jersey_override: Color = Color(0, 0, 0, 0)) -> void:
    stats = s
    controlled = is_controlled
    idle_face = face
    speed = 4.5 + float(s["speed"]) * 0.35
    jump_velocity = 5.8 + float(s["jump"]) * 0.18
    collision_layer = 4   # player layer
    collision_mask = 1    # sirf floor

    var jersey: Color = s["jersey"]
    if jersey_override.a > 0.0:
        jersey = jersey_override
    var hair: Color = s["hair"]
    _build_model(jersey, hair)
    model.rotation.y = atan2(-idle_face, 0.0)

    if controlled:
        var cs := CollisionShape3D.new()
        var cap := CapsuleShape3D.new()
        cap.radius = 0.35
        cap.height = 1.8
        cs.shape = cap
        cs.position = Vector3(0, 0.9, 0)
        add_child(cs)
    set_physics_process(controlled)

    blob = MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.45
    cm.bottom_radius = 0.45
    cm.height = 0.01
    blob.mesh = cm
    var bm := StandardMaterial3D.new()
    bm.albedo_color = Color(0, 0, 0, 0.3)
    bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    blob.material_override = bm
    blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    blob.top_level = true
    add_child(blob)

func _limb(pivot: Vector3, r: float, h: float, color: Color) -> Node3D:
    var p := Node3D.new()
    p.position = pivot
    model.add_child(p)
    var m := CapsuleMesh.new()
    m.radius = r
    m.height = h
    p.add_child(Toon.mesh_node(m, color, Vector3(0, -h * 0.5, 0)))
    return p

func _build_model(jersey: Color, hair: Color) -> void:
    model = Node3D.new()
    add_child(model)
    var skin := Color(1.0, 0.82, 0.70)
    var shorts := Color(0.12, 0.12, 0.22)

    left_leg = _limb(Vector3(-0.13, 0.85, 0), 0.10, 0.85, skin)
    right_leg = _limb(Vector3(0.13, 0.85, 0), 0.10, 0.85, skin)
    left_arm = _limb(Vector3(-0.30, 1.45, 0), 0.07, 0.65, skin)
    right_arm = _limb(Vector3(0.30, 1.45, 0), 0.07, 0.65, skin)

    var torso := CapsuleMesh.new()
    torso.radius = 0.22
    torso.height = 0.75
    model.add_child(Toon.mesh_node(torso, jersey, Vector3(0, 1.18, 0)))
    var sh := CapsuleMesh.new()
    sh.radius = 0.21
    sh.height = 0.40
    model.add_child(Toon.mesh_node(sh, shorts, Vector3(0, 0.88, 0)))

    var head := SphereMesh.new()
    head.radius = 0.2
    head.height = 0.4
    model.add_child(Toon.mesh_node(head, skin, Vector3(0, 1.78, 0)))

    var hm := SphereMesh.new()
    hm.radius = 0.22
    hm.height = 0.44
    var hair_node := Toon.mesh_node(hm, hair, Vector3(0, 1.85, 0.03))
    hair_node.scale = Vector3(1.0, 0.85, 1.0)
    model.add_child(hair_node)

    var spikes := [
        [Vector3(-0.1, 2.05, 0.0), 0.5],
        [Vector3(0.1, 2.05, 0.0), -0.5],
        [Vector3(0.0, 2.10, 0.06), 0.0],
    ]
    for sp in spikes:
        var cm := CylinderMesh.new()
        cm.top_radius = 0.0
        cm.bottom_radius = 0.07
        cm.height = 0.28
        var mi := Toon.mesh_node(cm, hair, sp[0])
        mi.rotation.z = sp[1]
        model.add_child(mi)

    # Anime aankhen
    for sx in [-1.0, 1.0]:
        var em := SphereMesh.new()
        em.radius = 0.045
        em.height = 0.09
        var eye := Toon.mesh_node(em, Color(0.05, 0.08, 0.25), Vector3(0.075 * sx, 1.77, -0.185), false)
        eye.scale = Vector3(1.0, 1.5, 0.6)
        model.add_child(eye)

func try_jump() -> void:
    if is_on_floor():
        velocity.y = jump_velocity

func _physics_process(delta: float) -> void:
    velocity.y -= GRAVITY * delta
    if is_on_floor() and velocity.y < 0.0:
        velocity.y = 0.0

    var strength := minf(move_input.length(), 1.0)
    var dir := Vector3(-move_input.y, 0.0, move_input.x)
    if dir.length() > 0.01:
        dir = dir.normalized()
        velocity.x = dir.x * speed * strength
        velocity.z = dir.z * speed * strength
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 10.0 * delta)

    move_and_slide()
    position.x = clampf(position.x, min_x, max_x)
    position.z = clampf(position.z, -6.0, 6.0)

func _process(delta: float) -> void:
    idle_t += delta
    blob.global_position = Vector3(global_position.x, 0.03, global_position.z)
    var hspeed := Vector2(velocity.x, velocity.z).length()
    var grounded := is_on_floor() or not controlled

    if controlled:
        if hspeed > 0.3:
            var target := atan2(-velocity.x, -velocity.z)
            model.rotation.y = lerp_angle(model.rotation.y, target, minf(delta * 12.0, 1.0))
        else:
            model.rotation.y = lerp_angle(model.rotation.y, atan2(-idle_face, 0.0), minf(delta * 6.0, 1.0))

    if grounded:
        run_time += delta * hspeed * 1.8
        var amp := clampf(hspeed / speed, 0.0, 1.0)
        var sw := sin(run_time) * 0.9 * amp
        left_leg.rotation.x = sw
        right_leg.rotation.x = -sw
        left_arm.rotation.x = 0.4 - sw
        right_arm.rotation.x = 0.4 + sw
        model.position.y = sin(idle_t * 2.5) * 0.015
    else:
        # Hawa mein: haath upar (spike/block pose)
        left_arm.rotation.x = lerpf(left_arm.rotation.x, 2.7, minf(delta * 14.0, 1.0))
        right_arm.rotation.x = lerpf(right_arm.rotation.x, 2.7, minf(delta * 14.0, 1.0))
        left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.3, minf(delta * 10.0, 1.0))
        right_leg.rotation.x = lerpf(right_leg.rotation.x, -0.2, minf(delta * 10.0, 1.0))
