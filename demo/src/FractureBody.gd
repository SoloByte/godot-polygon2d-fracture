extends RigidBody2D



const LINE_FADE_SPEED : float  = 0.8




signal Despawn(ref)




onready var _col_poly := $CollisionPolygon2D
onready var _poly := $Polygon2D
onready var _line := $Line2D
onready var _timer := $Timer
onready var _line_lerp_start_color : Color = _line.modulate




var _t : float = 1.0




func _process(delta: float) -> void:
	if _t < 1.0:
		_t += delta * LINE_FADE_SPEED
		_line.modulate = lerp(_line_lerp_start_color, _poly.modulate, min(_t, 1.0))


func spawn(pos : Vector2) -> void:
	global_position = pos
#	visible = true
#	_col_poly.set_deferred("disabled", false)
	_timer.start(5.0)
	set_process(true)
	_t = 0.0


func despawn() -> void:
#	_col_poly.set_deferred("disabled", true)
#	visible = false
	global_rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	set_applied_force(Vector2.ZERO)
	set_process(false)
	_t = 1.0



func setPolygon(polygon) -> void:
	_col_poly.set_polygon(polygon)
	_poly.set_polygon(polygon)
	polygon.append(polygon[0])
	_line.points = polygon


func setColor(color : Color) -> void:
	_poly.modulate = color


func _on_Timer_timeout() -> void:
	emit_signal("Despawn", self)
#	queue_free()
