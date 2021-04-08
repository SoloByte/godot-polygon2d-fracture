extends Polygon2D






signal Despawn(ref)





export(Color) var start_color = Color(1.5, 1.5, 1.5, 1.0)
export(Color) var end_color = Color(1.0, 1.0, 1.0, 0.1)



var fade_speed = 1.0
var t : float = 0.0



func _ready() -> void:
	set_process(false)
	visible = false


func spawn(pos : Vector2, fade_speed : float = 1.0) -> void:
	global_position = pos
	visible = true
	if fade_speed > 0.0:
		self.fade_speed = fade_speed
		set_process(true)


func despawn() -> void:
	t = 0.0
	visible = false
	set_process(false)




func _process(delta: float) -> void:
	if fade_speed > 0.0:
		t += delta * fade_speed
		
		color = lerp(start_color, end_color, t)
		
		if t >= 1.0:
			emit_signal("Despawn", self)
#			queue_free()



func setPolygon(poly : PoolVector2Array) -> void:
	t = 0.0
	color = start_color
	set_polygon(poly)
