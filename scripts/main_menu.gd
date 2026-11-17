extends Control
# Main menu: animated shader background, floating bubbles, title bounce, styled buttons.

var fx: Control
var bubbles: Array = []
var title: Label
var toast: Label
var quality_btn: Button
var char_btn: Button
var fade: ColorRect
var toast_tween: Tween

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_background()
    _build_title()
    _build_buttons()
    _build_footer()
    _build_fade()
    _bounce_title()

func _process(delta: float) -> void:
    for b in bubbles:
        b["y"] = float(b["y"]) - float(b["s"]) * delta
        if float(b["y"]) < -0.15:
            b["y"] = 1.15
            b["x"] = randf()
    fx.queue_redraw()

# ---------------------------------------------------------------- background
func _build_background() -> void:
    var bg := ColorRect.new()
    bg.color = Color.WHITE
    var mat := ShaderMaterial.new()
    mat.shader = load("res://shaders/menu_bg.gdshader")
    bg.material = mat
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    for i in 14:
        bubbles.append({"x": randf(), "y": randf(), "r": randf_range(20.0, 70.0), "s": randf_range(0.03, 0.09)})
    fx = Control.new()
    fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(fx)
    fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fx.draw.connect(_on_fx_draw)

func _on_fx_draw() -> void:
    var sz := fx.size
    for b in bubbles:
        var c := Vector2(float(b["x"]) * sz.x, float(b["y"]) * sz.y)
        var r := float(b["r"])
        fx.draw_circle(c, r, Color(1, 1, 1, 0.10))
        fx.draw_arc(c, r, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 3.0, true)

# ---------------------------------------------------------------- title
func _label(text: String, size: int) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color.WHITE)
    l.add_theme_color_override("font_outline_color", Color(0.90, 0.20, 0.50))
    l.add_theme_constant_override("outline_size", 18)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l

func _build_title() -> void:
    title = _label("VOLLEY RIVALS", 140)
    add_child(title)
    title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    title.offset_top = 50.0

    var sub := _label("3D ANIME VOLLEYBALL", 38)
    sub.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
    sub.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.35))
    sub.add_theme_constant_override("outline_size", 10)
    add_child(sub)
    sub.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    sub.offset_top = 230.0

    toast = _label("", 40)
    toast.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.35))
    toast.add_theme_constant_override("outline_size", 10)
    toast.modulate.a = 0.0
    add_child(toast)
    toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    toast.offset_top = -190.0
    toast.offset_bottom = -130.0

func _bounce_title() -> void:
    await get_tree().process_frame
    title.pivot_offset = title.size * 0.5
    var tw := create_tween().set_loops()
    tw.tween_property(title, "scale", Vector2(1.04, 1.04), 0.9).set_trans(Tween.TRANS_SINE)
    tw.tween_property(title, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE)

# ---------------------------------------------------------------- buttons
func _sb(c: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = c
    s.set_corner_radius_all(26)
    s.set_border_width_all(4)
    s.border_color = Color(1, 1, 1, 0.9)
    s.shadow_size = 10
    s.shadow_color = Color(0, 0, 0, 0.4)
    return s

func _style_button(b: Button, col: Color, font_size: int) -> void:
    b.add_theme_stylebox_override("normal", _sb(col))
    b.add_theme_stylebox_override("hover", _sb(col.lightened(0.15)))
    b.add_theme_stylebox_override("pressed", _sb(col.darkened(0.2)))
    b.add_theme_stylebox_override("focus", _sb(col))
    b.add_theme_font_size_override("font_size", font_size)
    b.add_theme_color_override("font_color", Color.WHITE)
    b.add_theme_color_override("font_hover_color", Color.WHITE)
    b.add_theme_color_override("font_pressed_color", Color.WHITE)

func _add_menu_button(parent: Container, text: String, col: Color, cb: Callable) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(560, 90)
    _style_button(b, col, 42)
    b.pressed.connect(cb)
    parent.add_child(b)
    return b

func _build_buttons() -> void:
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 14)
    add_child(vb)
    vb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
    vb.grow_vertical = Control.GROW_DIRECTION_BOTH
    vb.offset_top = 70.0
    vb.offset_bottom = 70.0

    _add_menu_button(vb, "STORY MODE", Color(0.55, 0.30, 0.90), func(): _soft("Story Mode agle stage mein aayega!"))
    _add_menu_button(vb, "QUICK MATCH", Color(0.95, 0.35, 0.40), func(): _start("quick"))
    _add_menu_button(vb, "TRAINING", Color(0.20, 0.70, 0.45), func(): _start("training"))
    _add_menu_button(vb, "TOURNAMENT", Color(0.95, 0.65, 0.15), func(): _soft("Tournament agle stage mein aayega!"))
    quality_btn = _add_menu_button(vb, "", Color(0.25, 0.45, 0.85), _cycle_quality)
    _refresh_quality()

func _build_footer() -> void:
    char_btn = Button.new()
    _style_button(char_btn, Color(0.10, 0.15, 0.40), 30)
    add_child(char_btn)
    char_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    char_btn.offset_left = 40.0
    char_btn.offset_top = -120.0
    char_btn.offset_right = 740.0
    char_btn.offset_bottom = -40.0
    char_btn.pressed.connect(_cycle_character)
    _refresh_character()

func _build_fade() -> void:
    fade = ColorRect.new()
    fade.color = Color.BLACK
    fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(fade)
    fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    create_tween().tween_property(fade, "modulate:a", 0.0, 0.6)

# ---------------------------------------------------------------- actions
func _soft(msg: String) -> void:
    toast.text = msg
    toast.modulate.a = 1.0
    if toast_tween:
        toast_tween.kill()
    toast_tween = create_tween()
    toast_tween.tween_interval(1.5)
    toast_tween.tween_property(toast, "modulate:a", 0.0, 0.4)

func _start(mode: String) -> void:
    GameState.game_mode = mode
    GameState.save_game()
    fade.modulate.a = 0.0
    var tw := create_tween()
    tw.tween_property(fade, "modulate:a", 1.0, 0.35)
    tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/court.tscn"))

func _cycle_quality() -> void:
    GameState.set_quality((GameState.graphics_quality + 1) % 3)
    _refresh_quality()

func _refresh_quality() -> void:
    quality_btn.text = "GRAPHICS: " + str(GameState.QUALITY_NAMES[GameState.graphics_quality])

func _cycle_character() -> void:
    GameState.selected_character = (GameState.selected_character + 1) % GameState.characters.size()
    GameState.save_game()
    _refresh_character()

func _refresh_character() -> void:
    var c: Dictionary = GameState.characters[GameState.selected_character]
    char_btn.text = "PLAYER: %s (%s)" % [c["name"], c["role"]]
