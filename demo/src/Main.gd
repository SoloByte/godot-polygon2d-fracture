extends Node2D



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




export(Array, PackedScene) var test_scenes

var _cur_test_scene_index : int = 0
var _cur_test_scene = null




func _ready():
	_cur_test_scene_index = -1
	changeTest()



func _input(event):
	if event.is_action_pressed("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	if event.is_action_pressed("change-test"):
		changeTest()


func changeTest() -> void:
	Engine.time_scale = 1.0
	if _cur_test_scene:
		_cur_test_scene.queue_free()
	
	_cur_test_scene_index = wrapi(_cur_test_scene_index + 1, 0, test_scenes.size())
	var instance = test_scenes[_cur_test_scene_index].instance()
	add_child(instance)
	_cur_test_scene = instance
