extends Node2D




const CUT_LINE_POINT_MIN_DISTANCE : float = 25.0
const CUT_LINE_STATIONARY_DELAY : float = 0.1
const CUT_LINE_DIRECTION_THRESHOLD : float = -0.7 #smaller than treshold ends line (start_dir.dot(cur_dir) < threshold = endLine)

const CUT_LINE_MIN_LENGTH : float = 100.0
const CUT_LINE_SEGMENT_MIN_LENGTH : float = 250.0




export(Color) var fracture_body_color
export(PackedScene) var fracture_body_template
export(PackedScene) var rigidbody_template
export(PackedScene) var cut_shape_visualizer_template



onready var polyFracture := PolygonFracture.new()
onready var _source_polygon_parent := $SourcePolygons
onready var _parent := $Parent
onready var _rng := RandomNumberGenerator.new()
onready var _cut_shape : PoolVector2Array = PolygonLib.createCirclePolygon(100.0, 1)
onready var _slowmo_timer := $SlowMoTimer
onready var _cut_line := $CutLine




var _input_disabled : bool = false

var _cur_fracture_color : Color = fracture_body_color

var _cut_line_enabled : bool = false
var _cut_line_total_length : float = 0.0
var _cut_line_points : PoolVector2Array = []
var _cut_line_start_direction := Vector2.ZERO
var _cut_line_t : float = 0.0



#var _debug_cut_shape_polygon2d := Polygon2D.new()



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
	
#	add_child(_debug_cut_shape_polygon2d)
#	_debug_cut_shape_polygon2d.color = Color.red
#	_debug_cut_shape_polygon2d.antialiased = true


func _process(delta: float) -> void:
	if _cut_line_enabled:
		var cur_pos : Vector2 = get_global_mouse_position()
		if _cut_line_t < 1.0:
			_cut_line_t += delta * (1.0 / CUT_LINE_STATIONARY_DELAY)
		calculateCutLine(cur_pos, _cut_line_t)


func _input(event: InputEvent) -> void:
	if _input_disabled: return
	
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if _cut_line_enabled:
				if not event.pressed:
					endCutLine()
					_cut_line_enabled = false
					_cut_line.visible = false
			else:
				if event.pressed:
					_cut_line_enabled = true
					_cut_line.visible = true
		elif event.button_index == 2 and not _cut_line_enabled:
			if event.pressed:
				simpleCut(get_global_mouse_position())





func calculateCutLine(cur_pos : Vector2, t : float) -> void:
	if _cut_line_points.size() <= 0:
		_cut_line_points.append(cur_pos)
	else:
		var last_pos : Vector2 = lerp(_cut_line_points[_cut_line_points.size() - 1], cur_pos, t)
		var vec : Vector2 = cur_pos - last_pos
		var dir : Vector2 = vec.normalized()
		
		if _cut_line_start_direction == Vector2.ZERO:
			_cut_line_start_direction = dir
		elif dir == Vector2.ZERO:
			endCutLine()
			return
		else:
			if _cut_line_start_direction.dot(dir) < CUT_LINE_DIRECTION_THRESHOLD:
				endCutLine()
				return
		
		var last_point : Vector2 = _cut_line_points[_cut_line_points.size() - 1]
		var dis : float = (cur_pos - last_point).length()
		if dis > CUT_LINE_POINT_MIN_DISTANCE:
			_cut_line_points.append(cur_pos)
			_cut_line.points = _cut_line_points
			_cut_line_t = 0.0
			_cut_line_total_length += dis
		else:
			_cut_line.points = _cut_line_points
			_cut_line.add_point(cur_pos, -1)


func startCutLine() -> void:
	pass


func endCutLine() -> void:
	if _cut_line_points.size() > 1 and _cut_line_total_length > CUT_LINE_MIN_LENGTH:
		var final_line : PoolVector2Array = [_cut_line_points[0]]
		var final_shape : PoolVector2Array = []
		var i : int = 0
#		var construct_point := Vector2.ZERO
		while i < _cut_line_points.size() - 1:
			var start : Vector2 = _cut_line_points[i]
			var total_dis : float = 0.0
			for j in range(i + 1, _cut_line_points.size()):
				var end : Vector2 = _cut_line_points[j]
				var vec : Vector2 = end - start 
				var dis : float = vec.length()
				var dir : Vector2 = vec.normalized()
				total_dis += dis
				if total_dis > CUT_LINE_SEGMENT_MIN_LENGTH or j >= _cut_line_points.size() - 1:
					
					#TODO check if cut shape merging produces correct shapes !?
#					var cut_shape : PoolVector2Array = PolygonLib.createBeamPolygon(dir, dis, 2.0, 2.0, construct_point)
#					final_shape = PolygonLib.mergePolygons(final_shape, cut_shape, true)[0]
#					construct_point += dir * dis
					final_line.append(end)
					
					i = j
					break
		
		final_shape = PolygonLib.offsetPolyline(final_line, 2.0, true)[0]
		final_shape = PolygonLib.translatePolygon(final_shape, -_cut_line_points[0])
#		_debug_cut_shape_polygon2d.global_position = _cut_line_points[0]
#		_debug_cut_shape_polygon2d.set_polygon(final_shape)
		cutSourcePolygons(_cut_line_points[0], final_shape, 0.0)
	
	
	
#	_cut_line.visible = false
	_cut_line_total_length = 0.0
	_cut_line_points = []
	_cut_line.clear_points()
	_cut_line_start_direction = Vector2.ZERO
	_cut_line_t = 0.0
	
	_input_disabled = true
	set_deferred("_input_disabled", false)



func simpleCut(pos : Vector2) -> void:
	var cut_pos : Vector2 = pos
	cutSourcePolygons(cut_pos, _cut_shape, 0.0)
	_input_disabled = true
	set_deferred("_input_disabled", false)


func cutSourcePolygons(cut_pos : Vector2, cut_shape : PoolVector2Array, cut_rot : float) -> void:
	var instance = cut_shape_visualizer_template.instance()
	add_child(instance)
	instance.global_position = cut_pos
	instance.setPolygon(cut_shape)
	
#	print("SOURCE CUT STARTED----------------------------------------------------------")
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
#		print("Shapes: ", cut_fracture_info.shapes.size(), " Fractures: ", cut_fracture_info.fractures.size())
		
		if cut_fracture_info.shapes.size() <= 0 and cut_fracture_info.fractures.size() <= 0:
#			print("no cut/fracture occured")
			continue
		
		for fracture in cut_fracture_info.fractures:
			for fracture_shard in fracture:
				spawnFractureBody(fracture_shard)
		
		
		
		for shape in cut_fracture_info.shapes:
			var spawn_pos : Vector2 = _source_polygon_parent.to_global(shape.centroid) + shape.world_pos
#			if source is Polygon2D:
#				call_deferred("spawnPoly", shape.centered_shape, spawn_pos, 0.0, source.modulate)
#			else:
			var mass : float = s_mass * (shape.area / total_area)
			call_deferred("spawnRigibody2d", shape.centered_shape, spawn_pos, 0.0, source.modulate, s_lin_vel, s_ang_vel, mass, cut_pos)
		
		source.queue_free()
	
#	print("SOURCE CUT ENDED----------------------------------------------------------")





#func spawnPoly(new_poly : PoolVector2Array, spawn_pos : Vector2, spawn_rot : float, color : Color) -> void:
#	var p = Polygon2D.new()
#	_source_polygon_parent.add_child(p)
#	p.global_position = spawn_pos
#	p.set_polygon(new_poly)
#	p.modulate = color


func spawnRigibody2d(new_poly : PoolVector2Array, spawn_pos : Vector2, spawn_rot : float, color : Color, lin_vel : Vector2, ang_vel : float, mass : float, cut_pos : Vector2) -> void:
	var instance = rigidbody_template.instance()
	_source_polygon_parent.add_child(instance)
	instance.global_position = spawn_pos
	instance.set_polygon(new_poly)
	instance.modulate = color
	instance.linear_velocity = lin_vel# + (spawn_pos - cut_pos).normalized() * 50
	instance.angular_velocity = ang_vel
	instance.mass = mass
	
#	print("SPAWN RIGIDBODY with poly: ", new_poly)


func spawnFractureBody(fracture_shard : Dictionary) -> void:
	var instance = polyFracture.spawnShape(_parent, fracture_body_template, fracture_shard).instance
	
	instance.setColor(_cur_fracture_color)
	var dir : Vector2 = (to_global(fracture_shard.centroid) - global_position).normalized()
	instance.apply_central_impulse(dir * _rng.randf_range(300, 500))
	instance.angular_velocity = _rng.randf_range(-1, 1)




func _on_SlowMoTimer_timeout() -> void:
	Engine.time_scale = 1.0
