class_name VirtualJoystick
extends Node2D
# Left-side virtual joystick. output = Vector2 (-1..1). Multi-touch safe (finger index track hota hai).

var radius: float = 140.0
var output := Vector2.ZERO
var finger: int = -1
var knob := Vector2.ZERO

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        if t.pressed:
            if finger == -1 and t.position.distance_to(global_position) <= radius * 1.5:
                finger = t.index
                _update(t.position)
        elif t.index == finger:
            finger = -1
            knob = Vector2.ZERO
            output = Vector2.ZERO
            queue_redraw()
    elif event is InputEventScreenDrag:
        var d := event as InputEventScreenDrag
        if d.index == finger:
            _update(d.position)

func _update(pos: Vector2) -> void:
    var v := (pos - global_position).limit_length(radius)
    knob = v
    output = v / radius
    if output.length() < 0.12:
        output = Vector2.ZERO
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, 0.14))
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.7), 4.0, true)
    draw_circle(knob, radius * 0.38, Color(1, 1, 1, 0.55))
    draw_arc(knob, radius * 0.38, 0.0, TAU, 40, Color(1, 1, 1, 0.95), 3.0, true)
