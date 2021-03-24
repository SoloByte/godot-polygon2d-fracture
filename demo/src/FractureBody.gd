extends RigidBody2D




onready var _col_poly := $CollisionPolygon2D
onready var _poly := $Polygon2D
onready var _line := $Line2D









func setPolygon(polygon) -> void:
	_col_poly.set_polygon(polygon)
	_poly.set_polygon(polygon)
	polygon.append(polygon[0])
	_line.points = polygon


func setColor(color : Color) -> void:
	modulate = color


func _on_Timer_timeout() -> void:
	queue_free()
