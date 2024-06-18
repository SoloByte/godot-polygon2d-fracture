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




signal Despawn(ref)




@export var radius: float = 50.0




@onready var _poly := $Polygon2D
@onready var _col_poly := $CollisionPolygon2D
@onready var _timer := $Timer




var point_fracture = null
var launch_velocity : float = 0.0




func _ready() -> void:
	setPolygon(PolygonLib.createCirclePolygon(radius, 1))


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		var body = state.get_contact_collider_object(0)
		if body is RigidBody2D:
			var pos : Vector2 = state.get_contact_collider_position(0)
			point_fracture.fractureCollision(pos, body, self)


func spawn(pos : Vector2, launch_vector : Vector2, lifetime : float, point_fracture) -> void:
	launch_velocity = launch_vector.length()
	self.point_fracture = point_fracture
	global_position = pos
	_timer.start(lifetime)
	
	linear_velocity = launch_vector


func despawn() -> void:
	global_rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	apply_force(Vector2.ZERO)


func destroy() -> void:
	_timer.stop()
	emit_signal("Despawn", self)


func setPolygon(polygon : PackedVector2Array) -> void:
	_poly.set_polygon(polygon)
	_col_poly.set_polygon(polygon)


func _on_Timer_timeout() -> void:
	point_fracture.fractureBallDespawned(global_position, _poly.get_polygon())
	destroy()
