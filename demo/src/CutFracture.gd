extends Node2D




const MIN_CUT_SPEED : float = 1.0
const MIN_CUT_LENGTH : float = 50.0
const MAX_CUT_LENGTH : float = 2500.0
const CUT_LINE_SEGMENT_MIN_LENGTH : float = 100.0



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
#var _cut_line_start := Vector2.ZERO


var _cut_line_total_length : float = 0.0

var _cut_line_points : PoolVector2Array = []

var _cut_line_enabled : bool = false

var _last_mouse_pos := Vector2.ZERO

var _input_disabled : bool = false



#var _first_cut_direction := Vector2.ZERO



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
	if _cut_line_enabled:
		var cur_pos : Vector2 = get_global_mouse_position()
		calculateCutLine(cur_pos)
		_last_mouse_pos = cur_pos



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
	if _input_disabled: return
	
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if _cut_line_enabled:
				if not event.pressed:
					endCut()
					_cut_line_enabled = false
			else:
				if event.pressed:
					_cut_line_enabled = true
		elif event.button_index == 2 and not _cut_line_enabled:
			if event.pressed:
				simpleCut(get_global_mouse_position())


func calculateCutLine(cur_pos : Vector2) -> void:
	if _cut_line_points.size() <= 0:
		_cut_line_points.append(cur_pos)
	else:
		var last_pos : Vector2 = _last_mouse_pos
		var vec : Vector2 = cur_pos - last_pos
		var dis : float = vec.length()
		var dir : Vector2 = vec.normalized()
		
		_cut_line_total_length += dis
		if not _cut_line.visible and _cut_line_total_length > MIN_CUT_LENGTH:
			_cut_line.visible = true
		
		if _cut_line_total_length > MAX_CUT_LENGTH:
			endCut()
			return
		
#		if _first_cut_direction == Vector2.ZERO:
#			_first_cut_direction = dir
#		else:
#			if _first_cut_direction.dot(dir) < -0.5:
#				endCut()
#				return
			
		if dis > MIN_CUT_SPEED:
			_cut_line_points.append(cur_pos)
			_cut_line.points = _cut_line_points
		else:
			endCut()
			return


func startCut() -> void:
	pass


func endCut() -> void:
	if _cut_line_points.size() > 1:
		var final_shape : PoolVector2Array = []
		var i : int = 0
		var construct_point := Vector2.ZERO
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
					
					var cut_shape : PoolVector2Array = PolygonLib.createBeamPolygon(dir, dis, 1.0, 1.0, construct_point)
					final_shape = PolygonLib.mergePolygons(final_shape, cut_shape, true)[0]
					construct_point += dir * dis
					
					i = j
					break
		
		cut(_cut_line_points[0], final_shape, 0.0)
	
	
	
	_cut_line.visible = false
	_cut_line_total_length = 0.0
	_cut_line_points = []
	_cut_line.clear_points()
#	_first_cut_direction = Vector2.ZERO
	
	_input_disabled = true
	set_deferred("_input_disabled", false)



func simpleCut(pos : Vector2) -> void:
	var cut_pos : Vector2 = pos
	cut(cut_pos, _cut_shape, 0.0)
	_input_disabled = true
	set_deferred("_input_disabled", false)

#func _input(event: InputEvent) -> void:
#	if _input_disabled: return
#	if event.is_action_pressed("cut_line"):
#		_cut_line_start = get_global_mouse_position()
#		var points : PoolVector2Array = [_cut_line_start, _cut_line_start]
#		_cut_line.visible = true
#		_cut_line.points = points
#
#
#	if event.is_action_released("cut_line"):
#		var cut_line_end : Vector2 = get_global_mouse_position()
#		var vec : Vector2 = cut_line_end - _cut_line_start
#		var dis : float = vec.length()
#		var dir : Vector2 = vec.normalized()
#		var cut_shape = PolygonLib.createBeamPolygon(dir, dis, 1.0, 1.0, Vector2.ZERO)
#		cut(_cut_line_start, cut_shape, 0.0)
#
#		_cut_line.clear_points()
#		_cut_line.visible = false
#		_input_disabled = true
#		set_deferred("_input_disabled", false)
#
#
#
#	if event.is_action_pressed("cut"):
#		var cut_pos : Vector2 = get_global_mouse_position()
#		cut(cut_pos, _cut_shape, 0.0)
#		_input_disabled = true
#		set_deferred("_input_disabled", false)


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
		
		if cut_fracture_info.shapes.size() <= 0 and cut_fracture_info.fractures.size() <= 0:
			continue
		
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
