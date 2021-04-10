extends Polygon2D


const LINE_FADE_SPEED : float  = 0.8




signal Despawn(ref)





onready var _line := $Line2D
onready var _timer := $Timer
onready var _line_lerp_start_color : Color = _line.modulate




var _t : float = 1.0

#var _lin_vel := Vector2.ZERO
#var _ang_vel : float = 0.0
#var _dead : bool = false



func _process(delta: float) -> void:
	if _t < 1.0:
		_t += delta * LINE_FADE_SPEED
		_line.modulate = lerp(_line_lerp_start_color, self_modulate, min(_t, 1.0))
	
#	global_position += _lin_vel * delta
#	global_rotation += _ang_vel * delta
#	if _dead:
#		scale = lerp(scale, Vector2.ZERO, delta)


func spawn(pos : Vector2, rot : float, s : Vector2, poly : PoolVector2Array, c : Color, texture_info : Dictionary, lifetime : float = 3.0) -> void:
	visible = true
	
	global_position = pos
	global_rotation = rot
	global_scale = s
	
	_timer.start(lifetime)
	_t = 0.0
	
	setPolygon(poly)
	setTexture(texture_info)
	setColor(c)
	
	set_process(true)


func despawn() -> void:
#	_dead = false
	visible = false
	set_process(false)
	_t = 1.0


#func addForce(force : Vector2) -> void:
#	_lin_vel += force
#
#func setAngularRot(rot : float) -> void:
#	_ang_vel = rot


func setPolygon(polygon : PoolVector2Array) -> void:
	set_polygon(polygon)
	polygon.append(polygon[0])
	_line.points = polygon


func setTexture(texture_info : Dictionary) -> void:
	texture = texture_info.texture
	texture_scale = texture_info.scale
	texture_offset = texture_info.offset
	texture_rotation = texture_info.rot


func setColor(color : Color) -> void:
	self_modulate = color


func _on_Timer_timeout() -> void:
#	if _dead: return
#	_dead = true
	emit_signal("Despawn", self)
