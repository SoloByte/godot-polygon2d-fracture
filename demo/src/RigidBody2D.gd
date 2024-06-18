extends RigidBody2D




# MIT License
# -----------------------------------------------------------------------
#                       This file is part of:                           
#                     GODOT Polygon 2D Fracture                         
#           https://github.com/SoloByte/godot-polygon2d-fracture          
# -----------------------------------------------------------------------
# Copyright (c) 2021 David Grueneis
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.




@export var rand_linear_velocity_range: Vector2 = Vector2(750.0, 1000.0)
#export(Vector2) var rand_angular_velocity_range = Vector2(-10.0, 10.0)
@export var radius: float = 250.0
@export var smoothing : int = 1 # (int, 0, 5, 1)

@export var placed_in_level: bool = false
@export var randomize_texture_properties: bool = true
@export var poly_texture: Texture2D




@onready var _polygon2d := $Polygon2D
@onready var _line2d := $Polygon2D/Line2D
@onready var _col_polygon2d := $CollisionPolygon2D
@onready var _rng := RandomNumberGenerator.new()



func _ready() -> void:
	_rng.randomize()
	if placed_in_level:
		var poly = PolygonLib.createCirclePolygon(radius, smoothing)
		setPolygon(poly)
		
		linear_velocity = Vector2.RIGHT.rotated(PI * 2.0 * _rng.randf()) * _rng.randf_range(rand_linear_velocity_range.x, rand_linear_velocity_range.y)
		
		_polygon2d.texture = poly_texture
		if randomize_texture_properties:
			var rand_scale : float = _rng.randf_range(0.5, 2.0)
			_polygon2d.texture_scale = Vector2(rand_scale, rand_scale)
			_polygon2d.texture_rotation = _rng.randf_range(0.0, PI * 2.0)
			_polygon2d.texture_offset = Vector2(_rng.randf_range(-500, 500), _rng.randf_range(-500, 500))



func getGlobalRotPolygon() -> float:
	return _polygon2d.global_rotation

func setPolygon(poly : PackedVector2Array) -> void:
	_polygon2d.set_polygon(poly)
	_col_polygon2d.set_polygon(poly)
	poly.append(poly[0])
	_line2d.points = poly


func setTexture(texture_info : Dictionary) -> void:
	_polygon2d.texture = texture_info.texture
	_polygon2d.texture_scale = texture_info.scale
	_polygon2d.texture_offset = texture_info.offset
	_polygon2d.texture_rotation = texture_info.rot


func getTextureInfo() -> Dictionary:
	return {"texture" : _polygon2d.texture, "rot" : _polygon2d.texture_rotation, "offset" : _polygon2d.texture_offset, "scale" : _polygon2d.texture_scale}


func getPolygon() -> PackedVector2Array:
	return _polygon2d.get_polygon()


func get_polygon() -> PackedVector2Array:
	return getPolygon()

func set_polygon(poly : PackedVector2Array) -> void:
	setPolygon(poly)
