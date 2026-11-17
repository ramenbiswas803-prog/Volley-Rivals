extends Node3D
# Court scene: poora 3D stadium, players, ball, camera, HUD aur touch controls code se bante hain.
# Court size: 18m (X axis) x 9m (Z axis). Net x=0 par. Tumhari team LEFT (x<0) side hai.

const NET_H := 2.43

var player: Player
var ball: Ball
var cam: Camera3D
var sun: DirectionalLight3D
var ball_shadow: MeshInstance3D
var joystick: VirtualJoystick
var touch_layer: CanvasLayer
var buttons: Array = []
var btn_offsets: Array = []

var score_left: int = 0
var score_right: int = 0
var elapsed: float = 0.0
var cam_z: float = 0.0

var score_label: Label
var time_label: Label
var toast_label: Label
var fps_label: Label
var toast_tween: Tween

func _ready() -> void:
    _build_environment()
    _build_court()
    _build_stands()
    _build_players()
    _build_ball()
    _build_camera()
    _build_hud()
    _build_touch_controls()
    _apply_quality()
    _toast("SERVE dabao aur ball ko receive karo!", 3.5)

# ---------------------------------------------------------------- helpers
func _box(size: Vector3, pos: Vector3, color: Color, outline: bool = false, parent: Node = null) -> MeshInstance3D:
    var m := BoxMesh.new()
    m.size = size
    var mi := Toon.mesh_node(m, color, pos, outline)
    if parent == null:
        add_child(mi)
    else:
        parent.add_child(mi)
    return mi

# ---------------------------------------------------------------- environment
func _build_environment() -> void:
    var env := Environment.new()
    var sky := Sky.new()
    var sm := ProceduralSkyMaterial.new()
    sm.sky_top_color = Color(0.10, 0.15, 0.45)
    sm.sky_horizon_color = Color(0.95, 0.55, 0.65)
    sm.ground_horizon_color = Color(0.95, 0.55, 0.65)
    sm.ground_bottom_color = Color(0.08, 0.08, 0.20)
    sky.sky_material = sm
    env.sky = sky
    env.background_mode = Environment.BG_SKY
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.9
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = GameState.graphics_quality == 2
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)

    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -30, 0)
    sun.light_energy = 1.1
    sun.light_color = Color(1.0, 0.95, 0.85)
    sun.directional_shadow_max_distance = 45.0
    add_child(sun)

    # Stadium spotlights (shadow nahi, sasta)
    for sx in [-8.0, 8.0]:
        for sz in [-6.0, 6.0]:
            var l := OmniLight3D.new()
            l.position = Vector3(sx, 9.0, sz)
            l.light_color = Color(0.85, 0.9, 1.0)
            l.light_energy = 1.2
            l.omni_range = 18.0
            add_child(l)

# ---------------------------------------------------------------- court + net
func _build_court() -> void:
    # Physics floor (invisible) - group "floor" se ball landing detect hoti hai
    var floor_body := StaticBody3D.new()
    floor_body.name = "Floor"
    floor_body.add_to_group("floor")
    floor_body.collision_layer = 1
    var fs := CollisionShape3D.new()
    var fb := BoxShape3D.new()
    fb.size = Vector3(40, 1, 30)
    fs.shape = fb
    fs.position = Vector3(0, -0.5, 0)
    floor_body.add_child(fs)
    var fphys := PhysicsMaterial.new()
    fphys.bounce = 0.1
    floor_body.physics_material_override = fphys
    add_child(floor_body)

    # Visual floor
    _box(Vector3(30, 0.2, 18), Vector3(0, -0.1, 0), Color(0.12, 0.18, 0.40))
    _box(Vector3(9, 0.2, 9), Vector3(-4.5, -0.09, 0), Color(0.96, 0.70, 0.40))
    _box(Vector3(9, 0.2, 9), Vector3(4.5, -0.09, 0), Color(0.92, 0.64, 0.35))
    # Attack zones (3m) - anime blue
    _box(Vector3(3, 0.02, 9), Vector3(-1.5, 0.012, 0), Color(0.40, 0.65, 0.95))
    _box(Vector3(3, 0.02, 9), Vector3(1.5, 0.012, 0), Color(0.40, 0.65, 0.95))

    # White lines
    var white := Color(1, 1, 1)
    for sx in [-9.0, 9.0]:
        _box(Vector3(0.06, 0.02, 9.06), Vector3(sx, 0.02, 0), white)
    for sz in [-4.5, 4.5]:
        _box(Vector3(18.06, 0.02, 0.06), Vector3(0, 0.02, sz), white)
    _box(Vector3(0.08, 0.02, 9.0), Vector3(0, 0.02, 0), white)
    for ax in [-3.0, 3.0]:
        _box(Vector3(0.06, 0.02, 9.0), Vector3(ax, 0.02, 0), white)

    # Net posts + net
    for pz in [-4.9, 4.9]:
        var cyl := CylinderMesh.new()
        cyl.top_radius = 0.05
        cyl.bottom_radius = 0.05
        cyl.height = 2.55
        add_child(Toon.mesh_node(cyl, Color(0.85, 0.85, 0.9), Vector3(0, 1.275, pz), true))
    var net := _box(Vector3(0.03, 1.0, 9.8), Vector3(0, 1.93, 0), Color(1, 1, 1))
    var nm := StandardMaterial3D.new()
    nm.albedo_color = Color(1, 1, 1, 0.45)
    nm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    nm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    net.material_override = nm
    _box(Vector3(0.06, 0.09, 9.8), Vector3(0, NET_H - 0.045, 0), Color(1, 1, 1))

    # Net collision
    var net_body := StaticBody3D.new()
    net_body.name = "Net"
    net_body.collision_layer = 1
    var ns := CollisionShape3D.new()
    var nb := BoxShape3D.new()
    nb.size = Vector3(0.06, 1.0, 9.8)
    ns.shape = nb
    ns.position = Vector3(0, 1.93, 0)
    net_body.add_child(ns)
    add_child(net_body)

# ---------------------------------------------------------------- crowd stands
func _build_stands() -> void:
    var shader := Shader.new()
    shader.code = """shader_type spatial;
render_mode unshaded;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
    vec2 g = UV * vec2(70.0, 14.0);
    vec2 id = floor(g);
    vec2 f = fract(g) - 0.5;
    float bob = sin(TIME * 3.0 + h(id) * 6.28) * 0.10;
    float d = length(f - vec2(0.0, bob));
    float m = smoothstep(0.40, 0.30, d);
    vec3 c = vec3(h(id), h(id + 3.1), h(id + 7.7));
    c = mix(c, vec3(1.0), 0.25);
    ALBEDO = mix(vec3(0.04, 0.05, 0.12), c, m);
}"""
    var mat := ShaderMaterial.new()
    mat.shader = shader

    var walls := [
        [Vector2(34, 7), Vector3(0, 3.5, -10), 0.0],
        [Vector2(34, 7), Vector3(0, 3.5, 10), 180.0],
        [Vector2(22, 7), Vector3(16, 3.5, 0), -90.0],
    ]
    for w in walls:
        var q := QuadMesh.new()
        q.size = w[0]
        var mi := MeshInstance3D.new()
        mi.mesh = q
        mi.material_override = mat
        mi.position = w[1]
        mi.rotation_degrees.y = w[2]
        mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(mi)

# ---------------------------------------------------------------- players
func _build_players() -> void:
    var me: Dictionary = GameState.characters[GameState.selected_character]
    var my_jersey: Color = me["jersey"]

    player = Player.new()
    add_child(player)
    player.position = Vector3(-6.5, 0.0, 0.0)
    player.setup(me, true, 1.0)

    var own_pos := [Vector2(-2.5, -3.0), Vector2(-2.5, 0.0), Vector2(-2.5, 3.0), Vector2(-7.5, -3.0), Vector2(-7.5, 3.0)]
    var n := 0
    for p in own_pos:
        var v: Vector2 = p
        var d := Player.new()
        add_child(d)
        d.position = Vector3(v.x, 0.0, v.y)
        var ch: Dictionary = GameState.characters[(GameState.selected_character + 1 + n) % GameState.characters.size()]
        d.setup(ch, false, 1.0, my_jersey)
        n += 1

    var opp_pos := [Vector2(2.5, -3.0), Vector2(2.5, 0.0), Vector2(2.5, 3.0), Vector2(7.5, -3.0), Vector2(7.5, 0.0), Vector2(7.5, 3.0)]
    n = 0
    for p in opp_pos:
        var v: Vector2 = p
        var o := Player.new()
        add_child(o)
        o.position = Vector3(v.x, 0.0, v.y)
        var ch2: Dictionary = GameState.characters[(GameState.selected_character + 4 + n) % GameState.characters.size()]
        o.setup(ch2, false, -1.0, Color(0.92, 0.22, 0.28))
        n += 1

# ---------------------------------------------------------------- ball
func _build_ball() -> void:
    ball = Ball.new()
    add_child(ball)
    ball.landed.connect(_on_ball_landed)
    _hold_ball()

    ball_shadow = MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.3
    cm.bottom_radius = 0.3
    cm.height = 0.005
    ball_shadow.mesh = cm
    var bm := StandardMaterial3D.new()
    bm.albedo_color = Color(0, 0, 0, 0.45)
    bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ball_shadow.material_override = bm
    ball_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(ball_shadow)

func _hold_ball() -> void:
    ball.hold(Vector3(-8.6, 1.8, 0.0))

# ---------------------------------------------------------------- camera
func _build_camera() -> void:
    cam = Camera3D.new()
    cam.fov = 55.0
    add_child(cam)
    cam.current = true
    _update_camera(0.0, true)

func _update_camera(delta: float, snap: bool = false) -> void:
    var target_z: float = player.position.z * 0.35
    if snap:
        cam_z = target_z
    else:
        cam_z = lerpf(cam_z, target_z, minf(delta * 4.0, 1.0))
    cam.look_at_from_position(Vector3(-16.0, 9.0, cam_z), Vector3(1.0, 0.5, cam_z * 0.5), Vector3.UP)

# ---------------------------------------------------------------- HUD
func _make_label(text: String, size: int) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color.WHITE)
    l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.2))
    l.add_theme_constant_override("outline_size", 10)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 5
    add_child(layer)

    score_label = _make_label("0 : 0", 80)
    layer.add_child(score_label)
    score_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    score_label.offset_top = 8.0

    time_label = _make_label("00:00", 40)
    layer.add_child(time_label)
    time_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    time_label.offset_top = 105.0

    toast_label = _make_label("", 48)
    layer.add_child(toast_label)
    toast_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    toast_label.offset_top = 190.0

    fps_label = _make_label("FPS", 28)
    fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    layer.add_child(fps_label)
    fps_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    fps_label.offset_left = -240.0
    fps_label.offset_right = -20.0
    fps_label.offset_top = 15.0

    var back := Button.new()
    back.text = "< MENU"
    back.add_theme_font_size_override("font_size", 32)
    back.position = Vector2(20, 20)
    back.size = Vector2(190, 76)
    back.pressed.connect(_go_menu)
    layer.add_child(back)

func _toast(msg: String, secs: float = 1.6) -> void:
    toast_label.text = msg
    toast_label.modulate.a = 1.0
    if toast_tween:
        toast_tween.kill()
    toast_tween = create_tween()
    toast_tween.tween_interval(secs)
    toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.4)

func _go_menu() -> void:
    GameState.save_game()
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ---------------------------------------------------------------- touch controls
func _build_touch_controls() -> void:
    touch_layer = CanvasLayer.new()
    touch_layer.layer = 10
    add_child(touch_layer)

    joystick = VirtualJoystick.new()
    touch_layer.add_child(joystick)

    # [label, color, radius, offset-from-right, offset-from-bottom]
    var defs := [
        ["JUMP", Color(0.2, 0.75, 0.4), 100.0, 180.0, 220.0],
        ["SPIKE", Color(0.9, 0.25, 0.3), 85.0, 390.0, 180.0],
        ["RECEIVE", Color(0.25, 0.5, 0.95), 80.0, 440.0, 360.0],
        ["SET", Color(0.95, 0.75, 0.15), 80.0, 240.0, 440.0],
        ["SERVE", Color(0.65, 0.35, 0.9), 70.0, 130.0, 650.0],
    ]
    for d in defs:
        var b := TouchBtn.new()
        b.label = d[0]
        b.base_color = d[1]
        b.radius = d[2]
        touch_layer.add_child(b)
        buttons.append(b)
        btn_offsets.append(Vector2(d[3], d[4]))

    (buttons[0] as TouchBtn).pressed.connect(_on_jump)
    (buttons[1] as TouchBtn).pressed.connect(_on_spike)
    (buttons[2] as TouchBtn).pressed.connect(_on_receive)
    (buttons[3] as TouchBtn).pressed.connect(_on_set)
    (buttons[4] as TouchBtn).pressed.connect(_on_serve)

    get_viewport().size_changed.connect(_layout_controls)
    _layout_controls()

func _layout_controls() -> void:
    var vs := get_viewport().get_visible_rect().size
    joystick.position = Vector2(260.0, vs.y - 260.0)
    for i in buttons.size():
        var off: Vector2 = btn_offsets[i]
        (buttons[i] as TouchBtn).position = Vector2(vs.x - off.x, vs.y - off.y)

# ---------------------------------------------------------------- actions
func _on_jump() -> void:
    player.try_jump()

func _on_spike() -> void:
    _toast("SPIKE Stage 2 mein aayega!")

func _on_set() -> void:
    _toast("SET Stage 2 mein aayega!")

func _on_serve() -> void:
    var from := Vector3(-9.2, 2.6, randf_range(-1.0, 1.0))
    var to := Vector3(randf_range(3.0, 8.0), 0.2, randf_range(-3.5, 3.5))
    var vel := ball.calc_velocity(from, to, 1.5)
    ball.place_and_launch(from, vel)
    _toast("SERVE!", 0.8)

func _on_receive() -> void:
    if not ball.rally_live:
        _toast("Ball live nahi hai - pehle SERVE karo")
        return
    var d := ball.global_position - player.global_position
    d.y = 0.0
    if ball.global_position.x > 0.5:
        _toast("Ball opponent side mein hai")
    elif d.length() > 2.4 or ball.global_position.y > 2.8:
        _toast("Ball door hai - paas jao!")
    else:
        var target := Vector3(-1.8, 2.8, clampf(player.position.z * 0.3, -2.0, 2.0))
        ball.hit(ball.calc_velocity(ball.global_position, target, 1.1))
        _toast("RECEIVE!", 0.8)

func _on_ball_landed(pos: Vector3) -> void:
    var inside := absf(pos.x) <= 9.0 and absf(pos.z) <= 4.5
    if not inside:
        _toast("OUT!", 1.5)
    elif pos.x < 0.0:
        score_right += 1
        _toast("IN! Point opponent ko", 1.5)
    else:
        score_left += 1
        _toast("IN! Point tumhe!", 1.5)
    score_label.text = "%d : %d" % [score_left, score_right]

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var k := event as InputEventKey
        if k.pressed and not k.echo:
            match k.keycode:
                KEY_SPACE: _on_jump()
                KEY_E: _on_receive()
                KEY_Q: _on_set()
                KEY_R: _on_spike()
                KEY_F: _on_serve()
                KEY_ESCAPE: _go_menu()

func _apply_quality() -> void:
    var q := GameState.graphics_quality
    sun.shadow_enabled = q > 0
    var sz := 1024
    if q == 1:
        sz = 2048
    elif q == 2:
        sz = 4096
    RenderingServer.directional_shadow_atlas_set_size(sz, true)

# ---------------------------------------------------------------- loop
func _process(delta: float) -> void:
    elapsed += delta
    time_label.text = "%02d:%02d" % [floori(elapsed / 60.0), int(elapsed) % 60]
    fps_label.text = "FPS %d" % int(Engine.get_frames_per_second())

    # PC testing ke liye keyboard (WASD/arrows)
    var kv := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        kv.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        kv.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        kv.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        kv.y += 1.0
    player.move_input = (joystick.output + kv).limit_length(1.0)

    var bp := ball.global_position
    ball_shadow.global_position = Vector3(bp.x, 0.03, bp.z)
    var s := clampf(1.3 - bp.y * 0.12, 0.4, 1.3)
    ball_shadow.scale = Vector3(s, 1.0, s)
    if bp.y < -3.0:
        _hold_ball()

    _update_camera(delta)
