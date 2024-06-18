extends Polygon2D




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





@export var start_color: Color = Color(1.5, 1.5, 1.5, 1.0)
@export var end_color: Color = Color(1.0, 1.0, 1.0, 0.1)



var fade_speed = 1.0
var t : float = 0.0



func _ready() -> void:
	set_process(false)
	visible = false


func spawn(pos : Vector2, fade_speed : float = 1.0) -> void:
	global_position = pos
	visible = true
	if fade_speed > 0.0:
		self.fade_speed = fade_speed
		set_process(true)


func despawn() -> void:
	t = 0.0
	visible = false
	set_process(false)




func _process(delta: float) -> void:
	if fade_speed > 0.0:
		t += delta * fade_speed
		
		color = lerp(start_color, end_color, t)
		
		if t >= 1.0:
			emit_signal("Despawn", self)
#			queue_free()



func setPolygon(poly : PackedVector2Array) -> void:
	t = 0.0
	color = start_color
	set_polygon(poly)
