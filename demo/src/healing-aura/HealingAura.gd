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





enum HEAL_METHOD {DISABLED = 0, INTERVAL = 1, TRIGGER = 2}



@export var mode_static: bool = false
@export var radius : float = 1.0 # (float, 1.0, 1000.0)
@export var smoothing : int = 0 # (int, 0, 4)
@export var collision_layer: int # (int, LAYERS_2D_PHYSICS)


@export var heal_method: HEAL_METHOD = HEAL_METHOD.DISABLED
@export var heal_amount: float = 0.1
@export var heal_interval: float = 1.0
@export var autostart: bool = false
@export var enabled: bool = true

var _heal_timer : Timer = null
var _heal_enabled : bool = false


@onready var _polygon2d := $Polygon2D
@onready var _circle_cast := $CircleCast
@onready var _anim_player := $AnimationPlayer


func isEnabled() -> bool:
	return _heal_enabled and not heal_method == HEAL_METHOD.DISABLED



func _ready() -> void:
	_heal_enabled = enabled

	var poly : PackedVector2Array = PolygonLib.createCirclePolygon(radius, smoothing, Vector2.ZERO)
	setPolygon(poly)
	
	_circle_cast.radius = radius
	_circle_cast.collision_layer = collision_layer
	
	if heal_method == HEAL_METHOD.INTERVAL:
		var timer := Timer.new()
		add_child(timer)
		timer.wait_time = heal_interval
		timer.one_shot = false
		timer.autostart = false
		timer.connect("timeout", Callable(self, "On_Heal_Timer_Timeout"))
		_heal_timer = timer
	
	
	if autostart and isEnabled():
		enable()




func enable() -> void:
	_heal_enabled = true
	if _heal_timer and _heal_timer.is_stopped():
		_heal_timer.start()
	
	_anim_player.play("idle")

func disable() -> void:
	_heal_enabled = false
	if _heal_timer and not _heal_timer.is_stopped():
		_heal_timer.stop()
	
	_anim_player.stop(true)



func setPolygon(polygon : PackedVector2Array) -> void:
	_polygon2d.set_polygon(polygon)


func cast() -> void:
	var results : Array
	if mode_static:
		results = _circle_cast.castStatic()
	else:
		results = _circle_cast.cast()
	
	var filtered : Dictionary = CircleCast.filterResultsAdv(results)
	
	for f in filtered.values():
		heal(f.body)
	
	if filtered.size() > 0:
		_anim_player.play("heal")


func heal(body) -> void:
	if not body: return
	if not body.has_method("heal"): return
	
	body.heal(heal_amount)



func On_Heal_Timer_Timeout() -> void:
	cast()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "heal":
		_anim_player.play("idle")
