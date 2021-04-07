extends RigidBody2D




signal Despawn(ref)




onready var _col_poly := $CollisionPolygon2D
onready var _poly := $Polygon2D
onready var _line := $Line2D
onready var _timer := $Timer







func spawn(pos : Vector2) -> void:
	global_position = pos
#	visible = true
#	_col_poly.set_deferred("disabled", false)
	_timer.start(5.0)


func despawn() -> void:
#	_col_poly.set_deferred("disabled", true)
#	visible = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	set_applied_force(Vector2.ZERO)



func setPolygon(polygon) -> void:
	_col_poly.set_polygon(polygon)
	_poly.set_polygon(polygon)
	polygon.append(polygon[0])
	_line.points = polygon


func setColor(color : Color) -> void:
	modulate = color


func _on_Timer_timeout() -> void:
	emit_signal("Despawn", self)
#	queue_free()
