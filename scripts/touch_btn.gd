class_name TouchBtn
extends Node2D
# Round touch button (multi-touch support). pressed signal tap par fire hota hai.

signal pressed
signal released

var radius: float = 90.0
var label: String = "BTN"
var base_color := Color(0.3, 0.6, 1.0)
var finger: int = -1
var held: bool = false

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        if t.pressed:
            if finger == -1 and t.position.distance_to(global_position) <= radius:
                finger = t.index
                held = true
                pressed.emit()
                queue_redraw()
        elif t.index == finger:
            finger = -1
            held = false
            released.emit()
            queue_redraw()

func _draw() -> void:
    var a := 0.9 if held else 0.55
    draw_circle(Vector2.ZERO, radius, Color(base_color, a))
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.95), 4.0, true)
    var font := ThemeDB.fallback_font
    var fs := 28
    var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
    draw_string(font, Vector2(-ts.x * 0.5, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
