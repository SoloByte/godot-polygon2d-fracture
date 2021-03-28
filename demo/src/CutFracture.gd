extends Node2D



export(Color) var fracture_body_color
export(PackedScene) var fracture_body_template
export(PackedScene) var rigidbody_template

export(int) var cuts : int = 3
export(int) var min_area : int = 25



onready var polyFracture := PolygonFracture.new()
onready var _source_polygon_parent := $SourcePolygons
onready var _parent := $Parent
onready var _rng := RandomNumberGenerator.new()
onready var _cut_shape : PoolVector2Array = PolygonLib.createCirclePolygon(150.0, 1)


var _cur_fracture_color : Color = fracture_body_color


func _ready() -> void:
	_rng.randomize()
	
	var color := Color.white
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	_source_polygon_parent.modulate = _cur_fracture_color



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
		c.a = 0.25
		p.modulate = c
		
		var old_sources : Array = []
		for source in _source_polygon_parent.get_children():
			if source.has_method("getPolygon"):
				old_sources.append(source)
				var source_polygon : PoolVector2Array = source.getPolygon()
				var local_cut_pos : Vector2 = source.to_local(cut_pos)
				var total_area : float = PolygonLib.getPolygonArea(source_polygon)
				
				var p1 = Polygon2D.new()
				add_child(p1)
				p1.set_polygon(source_polygon)
				p1.global_position = source.global_position
				p1.global_rotation = source.getGlobalRotPolygon()
				p1.z_index = 1
				var c1 = Color.blue
				c1.a = 0.25
				p1.modulate = c1
				
				var cut_info : Dictionary = PolygonLib.cutShape(local_cut_pos, source_polygon, source.getGlobalRotPolygon(), _cut_shape, 0.0, false)
				
				if cut_info.intersected and cut_info.intersected.size() > 0:
					for shape in cut_info.intersected:
						var area : float = PolygonLib.getPolygonArea(shape)
						if area < min_area * 2.0:
							continue
						var fracture_info : Array = polyFracture.fractureDelaunay(shape, source.global_position, source.getGlobalRotPolygon(), cuts, min_area)
						for fracture_shard in fracture_info:
							spawnFractureBody(fracture_shard)
				
				var s_mass : float = source.mass
				var s_lin_vel : Vector2 = source.linear_velocity
				var s_ang_vel : float = source.angular_velocity
				if cut_info.final and cut_info.final.size() > 0:
					for shape in cut_info.final:
						var shape_area : float = PolygonLib.getPolygonArea(shape)
						if shape_area < min_area * 2.0:
							continue
						
#						var spawn_info : Dictionary = PolygonLib.getShapeSpawnInfo(source, shape)
						
						var centroid : Vector2 = PolygonLib.calculatePolygonCentroid(shape)
						var spawn_pos : Vector2 = _source_polygon_parent.to_global(centroid) + source.global_position
						var centered_shape : PoolVector2Array = PolygonLib.translatePolygon(shape, -centroid)
						
						var instance = rigidbody_template.instance()
						_source_polygon_parent.add_child(instance)
						instance.global_position = spawn_pos
						instance.setPolygon(centered_shape)
						
						instance.linear_velocity = s_lin_vel
						instance.angular_velocity = s_ang_vel
						instance.mass = s_mass * (shape_area / total_area)
						
						var p2 = Polygon2D.new()
						add_child(p2)
						p2.set_polygon(centered_shape)
						p2.global_position = spawn_pos
						p2.z_index = 5
						var c2 = Color.green
#						c2.a = 0.25
						p2.modulate = c2
		
		for source in old_sources:
			_source_polygon_parent.remove_child(source)


func spawnFractureBody(fracture_shard : Dictionary) -> void:
	var instance = polyFracture.spawnFractureBody(_parent, fracture_body_template, fracture_shard).instance
	
	instance.setColor(_cur_fracture_color)
	var dir : Vector2 = (to_global(fracture_shard.centroid) - global_position).normalized()
	instance.apply_central_impulse(dir * _rng.randf_range(300, 500))
	instance.angular_velocity = _rng.randf_range(-1, 1)
