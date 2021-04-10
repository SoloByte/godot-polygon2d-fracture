extends Node2D




const CUT_LINE_POINT_MIN_DISTANCE : float = 40.0 #distance before new point is added (the smaller the more detailed is the visual line (not the cut line)
const CUT_LINE_STATIONARY_DELAY : float = 0.1 #after that amount of seconds remaining stationary will end the cut line process and cut the sources
const CUT_LINE_DIRECTION_THRESHOLD : float = -0.7 #smaller than treshold will end the cut line process and cut the sources (start_dir.dot(cur_dir) < threshold = endLine)

const CUT_LINE_MIN_LENGTH : float = 50.0 #the min length the cut line must have to be used for cutting (otherwise it will be discarded and no cutting occurs)
const CUT_LINE_EPSILON : float = 10.0 # used in func simplifyLineRDP // how detailed the actual cut line is (opposed to CUT_LINE_POINT_MIN_DISTANCE which determines how detailed the visual cut line is)
#const CUT_LINE_SEGMENT_MIN_LENGTH : float = 250.0 #used in my own simplifyLine func //how detailed the actual cut line is (opposed to CUT_LINE_POINT_MIN_DISTANCE which determines how detailed the visual cut line is)




export(Color) var fracture_body_color
export(PackedScene) var rigidbody_template




onready var polyFracture := PolygonFracture.new()
onready var _source_polygon_parent := $SourcePolygons
onready var _rng := RandomNumberGenerator.new()
onready var _cut_shape : PoolVector2Array = PolygonLib.createCirclePolygon(100.0, 1)
onready var _slowmo_timer := $SlowMoTimer
onready var _cut_line := $CutLine
onready var _pool_cut_visualizer := $Pool_CutVisualizer
onready var _pool_fracture_shards := $Pool_FractureShards




var _input_disabled : bool = false

var _cur_fracture_color : Color = fracture_body_color

var _cut_line_enabled : bool = false
var _cut_line_total_length : float = 0.0
var _cut_line_points : PoolVector2Array = []
var _cut_line_start_direction := Vector2.ZERO
var _cut_line_t : float = 0.0
var _cut_line_last_end_point := Vector3.ZERO #z is used as bool -> 0 = not a valid point/ 1 = valid point




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


func _process(delta: float) -> void:
	if _cut_line_enabled:
		var cur_pos : Vector2 = get_global_mouse_position()
		if _cut_line_t < 1.0:
			_cut_line_t += delta * (1.0 / CUT_LINE_STATIONARY_DELAY)
		calculateCutLine(cur_pos, _cut_line_t)


func _input(event: InputEvent) -> void:
	if _input_disabled: return
	
	#this system works with 1 button (instead of 2 with right mouse button) -> makes it work on touch screens
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if _cut_line_enabled:
				if not event.pressed:
					if _cut_line.visible:
						endCutLine()
						_cut_line_enabled = false
						_cut_line.visible = false
						_cut_line_last_end_point = Vector3.ZERO
					else:
						simpleCut(get_global_mouse_position())
						_cut_line_total_length = 0.0
						_cut_line_points = []
						_cut_line.clear_points()
						_cut_line_start_direction = Vector2.ZERO
						_cut_line_t = 0.0
						_cut_line_enabled = false
						_cut_line.visible = false
			else:
				if event.pressed:
					_cut_line_enabled = true


#func _exit_tree() -> void:
#	_pool_cut_visualizer.clearPoolInstant()
#	_pool_fracture_shards.clearPoolInstant()





func calculateCutLine(cur_pos : Vector2, t : float) -> void:
	if _cut_line_points.size() <= 0:
		if _cut_line_last_end_point.z > 0.0:# last cut lines end point is new cut lines start point
			_cut_line_points.append(Vector2(_cut_line_last_end_point.x, _cut_line_last_end_point.y))
			_cut_line_last_end_point = Vector3.ZERO
		else:#there was no cut line before
			_cut_line_points.append(cur_pos)
	
	elif _cut_line_points.size() == 1 and not _cut_line.visible:
		var dis : float = (cur_pos - _cut_line_points[_cut_line_points.size() - 1]).length()
		if dis > CUT_LINE_MIN_LENGTH:
			_cut_line.visible = true
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
	if _cut_line_points.size() > 1 and _cut_line_total_length > CUT_LINE_MIN_LENGTH and not _input_disabled:
		
#		var final_line : PoolVector2Array = PolygonLib.simplifyLine(_cut_line_points, CUT_LINE_SEGMENT_MIN_LENGTH)
		var final_line : PoolVector2Array = PolygonLib.simplifyLineRDP(_cut_line_points, CUT_LINE_EPSILON)
		var final_shape : PoolVector2Array = []
		
		final_shape = PolygonLib.offsetPolyline(final_line, 2.0, true)[0]
		final_shape = PolygonLib.translatePolygon(final_shape, -_cut_line_points[0])
		cutSourcePolygons(_cut_line_points[0], final_shape, 0.0, 0.0, 0.25)
	
	
	if _cut_line_points.size() > 1:
		var end_point : Vector2 = _cut_line_points[_cut_line_points.size() - 1]
		_cut_line_last_end_point = Vector3(end_point.x, end_point.y, 1.0)
	else:
		_cut_line_last_end_point = Vector3.ZERO
	
	_cut_line_total_length = 0.0
	_cut_line_points = []
	_cut_line.clear_points()
	_cut_line_start_direction = Vector2.ZERO
	_cut_line_t = 0.0
	
	_input_disabled = true
	set_deferred("_input_disabled", false)


func simpleCut(pos : Vector2) -> void:
	if _input_disabled: return
	
	var cut_pos : Vector2 = pos
	cutSourcePolygons(cut_pos, _cut_shape, 0.0, _rng.randf_range(250.0, 400.0), 2.0)
	_input_disabled = true
	set_deferred("_input_disabled", false)




func cutSourcePolygons(cut_pos : Vector2, cut_shape : PoolVector2Array, cut_rot : float, cut_force : float = 0.0, fade_speed : float = 2.0) -> void:
	var instance = _pool_cut_visualizer.getInstance()
	instance.spawn(cut_pos, fade_speed)
	instance.setPolygon(cut_shape)
	
	for source in _source_polygon_parent.get_children():
		var source_polygon : PoolVector2Array = source.get_polygon()
		var total_area : float = PolygonLib.getPolygonArea(source_polygon)
		
		var source_trans : Transform2D = source.get_global_transform()
		var cut_trans := Transform2D(cut_rot, cut_pos)
		
		var s_lin_vel := Vector2.ZERO
		var s_ang_vel : float = 0.0
		var s_mass : float = 0.0
		
		if source is RigidBody2D:
			s_lin_vel = source.linear_velocity
			s_ang_vel = source.angular_velocity
			s_mass = source.mass
		
		
		var cut_fracture_info : Dictionary = polyFracture.cutFracture(source_polygon, cut_shape, source_trans, cut_trans, 5000, 3000, 250, 1)
		
		if cut_fracture_info.shapes.size() <= 0 and cut_fracture_info.fractures.size() <= 0:
			continue
		
		for fracture in cut_fracture_info.fractures:
			for fracture_shard in fracture:
				spawnFractureBody(fracture_shard, source.getTextureInfo())
		
		
		for shape in cut_fracture_info.shapes:
			var area_p : float = shape.area / total_area
			var mass : float = s_mass * area_p
			var dir : Vector2 = (shape.spawn_pos - cut_pos).normalized()
			
			call_deferred("spawnRigibody2d", shape, source.modulate, s_lin_vel + dir * cut_force, s_ang_vel, mass, cut_pos, source.getTextureInfo())
		
		source.queue_free()



func spawnRigibody2d(shape_info : Dictionary, color : Color, lin_vel : Vector2, ang_vel : float, mass : float, cut_pos : Vector2, texture_info : Dictionary) -> void:
	var instance = rigidbody_template.instance()
	_source_polygon_parent.add_child(instance)
	instance.global_position = shape_info.spawn_pos
	instance.global_rotation = shape_info.spawn_rot
	instance.set_polygon(shape_info.centered_shape)
	instance.modulate = color
	instance.linear_velocity = lin_vel# + (spawn_pos - cut_pos).normalized() * 50
	instance.angular_velocity = ang_vel
	instance.mass = mass
	instance.setTexture(PolygonLib.setTextureOffset(texture_info, shape_info.centroid))


func spawnFractureBody(fracture_shard : Dictionary, texture_info : Dictionary) -> void:
	var instance = _pool_fracture_shards.getInstance()
	if not instance:
		return
	
	instance.spawn(fracture_shard.spawn_pos)
	instance.global_rotation = fracture_shard.spawn_rot
	
	if instance.has_method("setPolygon"):
		instance.setPolygon(fracture_shard.centered_shape)
	
	instance.setColor(_cur_fracture_color)
	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
	instance.linear_velocity = dir * _rng.randf_range(300, 500)
	instance.angular_velocity = _rng.randf_range(-1, 1)
	
	instance.setTexture(PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))




func _on_SlowMoTimer_timeout() -> void:
	Engine.time_scale = 1.0
