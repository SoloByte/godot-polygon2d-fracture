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




const LINE_FADE_SPEED : float  = 0.8




signal Despawn(ref)




@onready var _col_poly := $CollisionPolygon2D
@onready var _poly := $Polygon2D
@onready var _line := $Line2D
@onready var _timer := $Timer
@onready var _line_lerp_start_color : Color = _line.modulate




var _t : float = 1.0




func _process(delta: float) -> void:
	if _t < 1.0:
		_t += delta * LINE_FADE_SPEED
		_line.modulate = lerp(_line_lerp_start_color, _poly.modulate, min(_t, 1.0))


func spawn(pos : Vector2) -> void:
	global_position = pos
#	visible = true
#	_col_poly.set_deferred("disabled", false)
	_timer.start(5.0)
	set_process(true)
	_t = 0.0


func despawn() -> void:
#	_col_poly.set_deferred("disabled", true)
#	visible = false
	global_rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	apply_force(Vector2.ZERO)
	set_process(false)
	_t = 1.0


#func setScale(s : Vector2) -> void:
#	var t := Transform2D(0.0, Vector2.ZERO).scaled(s)
#	shape_owner_set_transform(get_shape_owners()[0],t)
#	_poly.scale = s
#	_line.scale = s


func setPolygon(polygon : PackedVector2Array, new_scale : Vector2) -> void:
	_poly.set_polygon(polygon)
	polygon.append(polygon[0])
	_line.points = polygon
	if new_scale != Vector2(1.0, 1.0):
		#physics objects (like the rigidbody2d) can not be scaled
		#thats why the polygon2d/line2d nodes are scale seperate
		#collision polygons can be scaled with "shape_owner_set_transform(owner_id,transform)
		#but here I just scale the polygon for the collision polygon
		polygon = PolygonLib.scalePolygon(polygon, new_scale)
		_poly.scale = new_scale
		_line.scale = new_scale
	_col_poly.set_polygon(polygon)


func setTexture(texture_info : Dictionary) -> void:
	_poly.texture = texture_info.texture
	_poly.texture_scale = texture_info.scale
	_poly.texture_offset = texture_info.offset
	_poly.texture_rotation = texture_info.rot


func setColor(color : Color) -> void:
	_poly.modulate = color


func _on_Timer_timeout() -> void:
	emit_signal("Despawn", self)
#	queue_free()
