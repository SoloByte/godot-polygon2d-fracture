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

var _cur_fracture_color : Color = fracture_body_color


func _ready() -> void:
	_rng.randomize()
	
	var color := Color.white
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	_source_polygon_parent.modulate = _cur_fracture_color



func _process(delta: float) -> void:
	for source in _source_polygon_parent.get_children():
		if source is Polygon2D:
			source.global_rotation += deg2rad(10) * delta



func spawnPoly(new_poly : PoolVector2Array, spawn_pos : Vector2, spawn_rot : float, color : Color) -> void:
	var p = Polygon2D.new()
	_source_polygon_parent.add_child(p)
	p.global_position = spawn_pos
	p.set_polygon(new_poly)
	p.modulate = color
	
	var center = Polygon2D.new()
	p.add_child(center)
	center.set_polygon(PolygonLib.createCirclePolygon(25.0, 1))
	center.modulate = Color.black

func spawnRigibody2d(new_poly : PoolVector2Array, spawn_pos : Vector2, spawn_rot : float, color : Color, lin_vel : Vector2, ang_vel : float, mass : float, cut_pos : Vector2) -> void:
	var instance = rigidbody_template.instance()
	_source_polygon_parent.add_child(instance)
	instance.global_position = spawn_pos
	instance.set_polygon(new_poly)
	instance.modulate = color
	instance.linear_velocity = lin_vel + (spawn_pos - cut_pos).normalized() * 50
	instance.angular_velocity = ang_vel
	instance.mass = mass
	
	var center = Polygon2D.new()
	instance.add_child(center)
	center.set_polygon(PolygonLib.createCirclePolygon(25.0, 1))
	center.modulate = Color.black


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cut"):
		var cut_pos : Vector2 = get_global_mouse_position()
		
		var p = Polygon2D.new()
		add_child(p)
		p.set_polygon(_cut_shape)
		p.global_position = cut_pos
		p.modulate = Color.red
		p.z_index = 3
		var c = Color.red
		c.a = 0.1
		p.color = c
		
		for source in _source_polygon_parent.get_children():
			var source_polygon : PoolVector2Array = source.get_polygon()
			var total_area : float = PolygonLib.getPolygonArea(source_polygon)
			var local_cut_pos : Vector2 = source.to_local(cut_pos)
			var source_pos : Vector2 = source.global_position
			var source_rot : float = source.global_rotation
			var s_lin_vel := Vector2.ZERO
			var s_ang_vel : float = 0.0
			var s_mass : float = 0.0
			if source is RigidBody2D:
				s_lin_vel = source.linear_velocity
				s_ang_vel = source.angular_velocity
				s_mass = source.mass
			
			var cut_info : Dictionary = PolygonLib.cutShape(source_polygon, source_rot, _cut_shape, local_cut_pos, 0.0, true)
			
			if cut_info.intersected and cut_info.intersected.size() > 0:
				for shape in cut_info.intersected:
					var area : float = PolygonLib.getPolygonArea(shape)
					if area < 2000:
						continue
					
					
					var fracture_info : Array = polyFracture.fractureDelaunay(shape, source_pos, 0.0, 3, 250)
					for fracture_shard in fracture_info:
						spawnFractureBody(fracture_shard)
			
			
			if cut_info.final and cut_info.final.size() > 0:
				for shape in cut_info.final:
					var shape_area : float = PolygonLib.getPolygonArea(shape)
					if shape_area < 2000:
						continue
					
					var centroid : Vector2 = PolygonLib.calculatePolygonCentroid(shape)
					var spawn_pos : Vector2 = _source_polygon_parent.to_global(centroid) + source_pos
					var centered_shape : PoolVector2Array = PolygonLib.translatePolygon(shape, -centroid)
					
					if source is Polygon2D:
						call_deferred("spawnPoly", centered_shape, spawn_pos, 0.0, source.modulate)
					else:
						var mass : float = s_mass * (shape_area / total_area)
						call_deferred("spawnRigibody2d", centered_shape, spawn_pos, 0.0, source.modulate, s_lin_vel, s_ang_vel, mass, cut_pos)
			
			source.queue_free()
		Engine.time_scale = 0.1
		_slowmo_timer.start(0.25)


func spawnFractureBody(fracture_shard : Dictionary) -> void:
	var instance = polyFracture.spawnFractureBody(_parent, fracture_body_template, fracture_shard).instance
	
	instance.setColor(_cur_fracture_color)
	var dir : Vector2 = (to_global(fracture_shard.centroid) - global_position).normalized()
	instance.apply_central_impulse(dir * _rng.randf_range(300, 500))
	instance.angular_velocity = _rng.randf_range(-1, 1)


func _on_SlowMoTimer_timeout() -> void:
	Engine.time_scale = 1.0
