extends RigidBody2D


export(Vector2) var rand_linear_velocity_range = Vector2(750.0, 1000.0)
#export(Vector2) var rand_angular_velocity_range = Vector2(-10.0, 10.0)
export(float) var radius : float = 250.0
export(int, 0, 5, 1) var smoothing : int = 1


onready var _polygon2d := $Polygon2D
onready var _line2d := $Polygon2D/Line2D
onready var _col_polygon2d := $CollisionPolygon2D
onready var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	var poly = PolygonLib.createCirclePolygon(radius, smoothing)
	setPolygon(poly)
	
	linear_velocity = Vector2.RIGHT.rotated(PI * 2.0 * _rng.randf()) * _rng.randf_range(rand_linear_velocity_range.x, rand_linear_velocity_range.y)
#	angular_velocity = _rng.randf_range(rand_angular_velocity_range.x, rand_angular_velocity_range.y)



func getGlobalRotPolygon() -> float:
	return _polygon2d.global_rotation

func setPolygon(poly : PoolVector2Array) -> void:
	_polygon2d.set_polygon(poly)
	_col_polygon2d.set_polygon(poly)
	poly.append(poly[0])
	_line2d.points = poly


func getPolygon() -> PoolVector2Array:
	return _polygon2d.get_polygon()


func get_polygon() -> PoolVector2Array:
	return getPolygon()

func set_polygon(poly : PoolVector2Array) -> void:
	setPolygon(poly)

#func _process(delta: float) -> void:
#	print("Rot RB: ", global_rotation, " Rot Poly: ", _polygon2d.global_rotation, " Rot Deg RB: ", rotation_degrees, " Rot Deg Poly: ", _polygon2d.rotation_degrees)
