extends Node2D



export(Color) var fracture_body_color
export(PackedScene) var fracture_body_template
export(PackedScene) var rigidbody_template



onready var polyFracture := PolygonFracture.new()
onready var _source_polygon_parent := $SourcePolygons
onready var _parent := $Parent
onready var _rng := RandomNumberGenerator.new()
onready var _cut_shape : PoolVector2Array = PolygonLib.createCirclePolygon(100.0, 1)
onready var _slowmo_timer := $SlowMoTimer
onready var _cut_line := $CutLine


var _cur_fracture_color : Color = fracture_body_color
var _cut_line_start := Vector2.ZERO



func _ready() -> void:
	_rng.randomize()
	
	var color := Color.white
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	_source_polygon_parent.modulate = _cur_fracture_color
	
	_cut_line.clear_points()
	_cut_line.visible = false
	
	for source in _source_polygon_parent.get_children():
		if source is Polygon2D:
			source.global_rotation = _rng.randf() * PI * 2.0



func _process(delta: float) -> void:
#	for source in _source_polygon_parent.get_children():
#		if source is Polygon2D:
#			source.global_rotation += deg2rad(90) * delta
	
	if _cut_line.visible:
		_cut_line.set_point_position(1, _cut_line.to_local(get_global_mouse_position()))



func spawnPoly(new_poly : PoolVector2Array, spawn_pos : Vector2, spawn_rot : float, color : Color) -> void:
	var p = Polygon2D.new()
	_source_polygon_parent.add_child(p)
	p.global_position = spawn_pos
	p.set_polygon(new_poly)
	p.modulate = color

func spawnRigibody2d(new_poly : PoolVector2Array, spawn_pos : Vector2, spawn_rot : float, color : Color, lin_vel : Vector2, ang_vel : float, mass : float, cut_pos : Vector2) -> void:
	var instance = rigidbody_template.instance()
	_source_polygon_parent.add_child(instance)
	instance.global_position = spawn_pos
	instance.set_polygon(new_poly)
	instance.modulate = color
	instance.linear_velocity = lin_vel + (spawn_pos - cut_pos).normalized() * 50
	instance.angular_velocity = ang_vel
	instance.mass = mass








func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cut_line"):
		_cut_line_start = get_global_mouse_position()
		var points : PoolVector2Array = [_cut_line_start, _cut_line_start]
		_cut_line.visible = true
		_cut_line.points = points
	
	
	if event.is_action_released("cut_line"):
		var cut_line_end : Vector2 = get_global_mouse_position()
		var vec : Vector2 = cut_line_end - _cut_line_start
		var dis : float = vec.length()
		var dir : Vector2 = vec.normalized()
		var cut_shape = PolygonLib.createBeamPolygon(dir, dis, 1.0, 1.0, Vector2.ZERO)
		cut(_cut_line_start, cut_shape, 0.0)
		
		_cut_line.clear_points()
		_cut_line.visible = false
	
	
	
	if event.is_action_pressed("cut"):
		var cut_pos : Vector2 = get_global_mouse_position()
		cut(cut_pos, _cut_shape, 0.0)
	
	
	if event.is_action_pressed("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()







func cut(cut_pos : Vector2, cut_shape : PoolVector2Array, cut_rot : float) -> void:
	for source in _source_polygon_parent.get_children():
		var source_polygon : PoolVector2Array = source.get_polygon()
		var total_area : float = PolygonLib.getPolygonArea(source_polygon)
		
		var source_trans : Transform2D = source.get_global_transform()#Transform2D(source.global_rotation, source.global_position)
		var cut_trans := Transform2D(cut_rot, cut_pos)
		
		var s_lin_vel := Vector2.ZERO
		var s_ang_vel : float = 0.0
		var s_mass : float = 0.0
		
		if source is RigidBody2D:
			s_lin_vel = source.linear_velocity
			s_ang_vel = source.angular_velocity
			s_mass = source.mass
		
		
		var cut_fracture_info : Dictionary = polyFracture.cutFracture(source_polygon, cut_shape, source_trans, cut_trans, 5000, 3000, 250, 3)
		for fracture in cut_fracture_info.fractures:
			for fracture_shard in fracture:
				spawnFractureBody(fracture_shard)
		
		
		
		for shape in cut_fracture_info.shapes:
			var spawn_pos : Vector2 = _source_polygon_parent.to_global(shape.centroid) + shape.world_pos
			if source is Polygon2D:
				call_deferred("spawnPoly", shape.centered_shape, spawn_pos, 0.0, source.modulate)
			else:
				var mass : float = s_mass * (shape.area / total_area)
				call_deferred("spawnRigibody2d", shape.centered_shape, spawn_pos, 0.0, source.modulate, s_lin_vel, s_ang_vel, mass, cut_pos)
		
		source.queue_free()
	
#	Engine.time_scale = 0.1
#	_slowmo_timer.start(0.25)







func spawnFractureBody(fracture_shard : Dictionary) -> void:
	var instance = polyFracture.spawnShape(_parent, fracture_body_template, fracture_shard).instance
	
	instance.setColor(_cur_fracture_color)
	var dir : Vector2 = (to_global(fracture_shard.centroid) - global_position).normalized()
	instance.apply_central_impulse(dir * _rng.randf_range(300, 500))
	instance.angular_velocity = _rng.randf_range(-1, 1)


func _on_SlowMoTimer_timeout() -> void:
	Engine.time_scale = 1.0
