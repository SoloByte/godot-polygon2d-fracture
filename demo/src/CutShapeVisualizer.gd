extends Polygon2D




export(Color) var start_color = Color(1.5, 1.5, 1.5, 1.0)
export(Color) var end_color = Color(1.0, 1.0, 1.0, 0.1)
export(float) var fade_speed = 1.0




var t : float = 0.0




func _process(delta: float) -> void:
	if fade_speed > 0.0:
		t += delta * fade_speed
		
		color = lerp(start_color, end_color, t)
		
		if t >= 1.0:
			queue_free()



func setPolygon(poly : PoolVector2Array) -> void:
	t = 0.0
	color = start_color
	set_polygon(poly)
