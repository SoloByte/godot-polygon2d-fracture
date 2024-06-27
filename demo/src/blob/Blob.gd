extends RigidBody2D
class_name Blob




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




#Blobs are the enemies of my game Fracture Hell.
#This script is almost identical to the one I use in Fracture Hell.
#Check the game out on itch.io [https://solobytegames.itch.io/fracture-hell].
#Comments, Feedback, a Rating, or any other form of interaction is greatly appreciated :D




signal Died(ref, pos)
signal Damaged(blob, pos, shape, color, fade_speed)
signal Fractured(blob, fracture_shard, new_mass, color, fracture_force, p)

@export var advanced_regeneration: bool = false
@export var invincible_time: float = 0.5
@export var color_default: Color
@export var radius: float = 24.0
@export var smoothing : int = 1 # (int, 0, 4)
@export var knockback_resistance_base: float = 1.0 #1.0 = no change #2.0 means twice as fast over #0.5 means takes longer twice as much

@export var shape_area_percent : float = 0.25#shape_area < start_area * shape_area_percent -> shape will be fractured # (float, 0.0, 1.0)

@export var fractures: int = 2
@export var fracture_force: float = 200.0
@export var heal_treshold : float = 0.8 #if health percent is above that threshold the start poly is used instead of morphing polygons # (float, 0.0, 1.0)

@export var collision_damage := Vector2(5, 10)
@export var collision_knockback_force: float = 10000
@export var collision_knockback_time: float = 0.15

@export var find_new_target_pos_tolerance: float = 50.0
@export var target_reached_tolerance: float = 10.0
@export var target_pos_interval_range := Vector2(0.5, 1.5)
@export var keep_distance_range := Vector2.ZERO

#export(int) var score_points : int = 25

@export var rotate_towards_velocity: bool = false
@export var max_speed: float = 250.0
@export var accel: float = 1000.0
@export var decel: float = 1500.0


@export var regeneration_interval_range: Vector2 = Vector2.ZERO
@export var regeneration_start_threshold : float = 0.5 # (float, 0.0, 1.0)
@export var regeneration_amount: float = 10.0
@export var regeneration_color: Color = Color.WHITE


var cur_area : float = 0.0
var start_area : float = 0.0
var target = null
var target_pos := Vector3.ZERO
var prev_target_pos := Vector2.ZERO

var knockback_resistance : float = 1.0
var knockback_timer : float = 0.0

var start_poly : PackedVector2Array

var total_frame_heal_amount : float = 0.0

var regeneration_timer : Timer = null
var regeneration_started : bool = false

var polygon_restorer : PolygonRestorer = null


@onready var find_new_target_pos_tolerance_sq : float = find_new_target_pos_tolerance * find_new_target_pos_tolerance
@onready var target_reached_tolerance_sq : float = target_reached_tolerance * target_reached_tolerance
@onready var max_speed_sq : float = max_speed * max_speed

@onready var _col_polygon := $CollisionPolygon2D
@onready var _polygon := $Shape3D/Polygon2D
@onready var _line := $Shape3D/Line2D
@onready var _drop_poly := $DropPoly
@onready var _origin_poly := $OriginPoly

@onready var _rng := RandomNumberGenerator.new()
@onready var _target_pos_timer := $TargetPosTimer
@onready var _poly_fracture := PolygonFracture.new()
@onready var _hit_flash_poly := $FlashPolygon
@onready var _hit_flash_anim_player := $AnimationPlayer
@onready var _invincible_timer := $InvincibleTimer



func isInvincible() -> bool:
	return not _invincible_timer.is_stopped()

func isDead() -> bool:
	return cur_area <= 0.0

func canBeHealed() -> bool:
	return getHealthPercent() < 1.0 and not isDead()

func getHealthPercent() -> float:
	if start_area == 0.0:
		return 0.0
	return cur_area / start_area

func hasRegeneration() -> bool:
	return regeneration_timer != null and regeneration_amount > 0.0

func canRegenerate() -> bool:
	return (getHealthPercent() < regeneration_start_threshold or regeneration_started) and regeneration_timer.is_stopped()

func isRegenerating() -> bool:
	return regeneration_started

func setTarget(new_target) -> void:
	target = new_target
#	if target and is_instance_valid(target):
	startTargetPosTimer(target_pos_interval_range.x, target_pos_interval_range.y)
	setNewTargetPos()

func isKnockbackActive() -> bool:
	return knockback_timer > 0.0

func getCurColor() -> Color:
	return _origin_poly.modulate

func getCurMaxSpeed() -> float:
	var factor :  float = 1.0
	if isRegenerating():
		factor = 2.0
	return lerp(max_speed, max_speed * 1.2, 1.0 - getHealthPercent()) * factor

func getCurMaxSpeedSq() -> float:
	var speed : float = getCurMaxSpeed()
	return speed * speed

func getCurAccel() -> float:
	var factor :  float = 1.0
	return lerp(accel, accel * 1.3, 1.0 - getHealthPercent()) * factor

func getCurDecel() -> float:
	var factor :  float = 1.0
	return lerp(decel, decel * 1.3, 1.0 - getHealthPercent()) * factor

func hasTarget() -> bool:
	return target != null





func _ready() -> void:
	_rng.randomize()
	
	if radius > 0.0:
		var new_polygon : PackedVector2Array = PolygonLib.createCirclePolygon(radius, smoothing)
		start_poly = new_polygon
		setPolygon(start_poly)
		mass = radius
		start_area = PI * radius * radius
	else:
		start_poly = _polygon.get_polygon()
		setPolygon(start_poly, true)
		start_area = PolygonLib.getPolygonArea(start_poly)
	
	cur_area = start_area
	
	
	if not advanced_regeneration:
		polygon_restorer = PolygonRestorer.new()
		polygon_restorer.addShape(_polygon.get_polygon(), start_area)
	
	applyColor(color_default)
	
	_hit_flash_poly.visible = false
	
	
	_origin_poly.set_polygon(_polygon.get_polygon())
	_drop_poly.set_polygon(_polygon.get_polygon())
#	_drop_poly.set_polygon(PolygonLib.scalePolygon(_polygon.get_polygon(), Vector2(1.5, 1.5)))
	_drop_poly.modulate.a = lerp(0.2, 0.7, 1.0 - getHealthPercent())
	
	
	if regeneration_interval_range != Vector2.ZERO:
		var timer := Timer.new()
		add_child(timer)
		timer.one_shot = true
		timer.autostart = false
		timer.connect("timeout", Callable(self, "On_Regeneration_Timer_Timeout"))
		regeneration_timer = timer
	
	setTarget(null)




func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if isKnockbackActive(): return


	if state.get_contact_count() > 0:
		
		var collisions : Dictionary = {}
		#filtering the collisions
		for i in range(state.get_contact_count()):
			var id = state.get_contact_collider_id(i)
			if collisions.has(id):
				var shape = state.get_contact_collider_shape(i)
				collisions[id].shapes.append(shape)
			else:
				var body = state.get_contact_collider_object(i)
				var shape = state.get_contact_collider_shape(i)
				var pos = state.get_contact_collider_position(i)
				collisions[id] = {"body" : body, "shapes" : [shape], "pos" : pos}
		
		
		var count : int = collisions.values().size()
		if target == null and count > 0:
			if count == 1:
				setTarget(collisions.values()[0].body)
			else:
				var rand_index : int = _rng.randi_range(0, count - 1)
				setTarget(collisions.values()[rand_index].body)
		
		
		for col in collisions.values():
			if col.body is RigidBody2D:
				if col.body.has_method("damage"):
					var force : Vector2 = (col.body.global_position - global_position).normalized() * collision_knockback_force
					col.body.call_deferred("damage", collision_damage, col.pos, force, collision_knockback_time, self, getCurColor())
		
	var input := Vector2.ZERO
	
	if target and is_instance_valid(target): 
		if find_new_target_pos_tolerance > 0.0:
			var dis : float = (prev_target_pos - target.global_position).length_squared()
			if dis > find_new_target_pos_tolerance_sq:
				setNewTargetPos()
	
	if target_pos.z == 1.0:
		var cur_target_pos := Vector2(target_pos.x, target_pos.y)
		var target_vec := cur_target_pos - global_position
		var dis : float = target_vec.length_squared()
		
		if dis > target_reached_tolerance_sq:
			input = target_vec.normalized()
	
	
	if input != Vector2.ZERO:
		var increase : Vector2 = input * getCurAccel() * state.step
		state.linear_velocity += increase
		if state.linear_velocity.length_squared() > getCurMaxSpeedSq():
			state.linear_velocity = state.linear_velocity.normalized() * getCurMaxSpeed()
	else:
		var decrease : Vector2 = linear_velocity.normalized() * getCurDecel() * state.step
		if decrease.length_squared() >= state.linear_velocity.length_squared():
			state.linear_velocity = Vector2.ZERO
		else:
			state.linear_velocity -= decrease
	
	if rotate_towards_velocity:
		global_rotation = state.linear_velocity.angle()



func _process(delta: float) -> void:
	processKnockbackTimer(delta)
	
	if target != null and not is_instance_valid(target):
		setTarget(null)


func applyColor(color : Color) -> void:
	_polygon.modulate = color
	_line.modulate = color
	_origin_poly.modulate = color


func damage(damage : Vector2, point : Vector2, knockback_force : Vector2, knockback_time : float, damage_dealer, damage_color : Color) -> Dictionary:
	if isDead(): 
		return {"percent_cut" : 0.0, "dead" : true}
	
	if isInvincible():
		_hit_flash_anim_player.play("invincible-hit-flash")
		return {"percent_cut" : 0.0, "dead" : false} 
	
	setTarget(damage_dealer)
	
	var percent_cut : float = 0.0
	var cut_shape : PackedVector2Array = _poly_fracture.generateRandomPolygon(damage, Vector2(12,72), Vector2.ZERO)
	var cut_shape_area : float = PolygonLib.getPolygonArea(cut_shape)
	emit_signal("Damaged", self, point, cut_shape, damage_color, 5.0)
#	spawnShapeVisualizer(point, 0.0, cut_shape, damage_color, 1.0)
	var fracture_info : Dictionary = _poly_fracture.cutFracture(_polygon.get_polygon(), cut_shape, get_global_transform(), Transform2D(0.0, point), start_area * shape_area_percent, 200, 50, fractures)
	
	
	var p : float = cut_shape_area / cur_area
	for fracture in fracture_info.fractures:
		for shard in fracture:
			emit_signal("Fractured", self, shard, mass * (shard.area / cur_area), getCurColor(), fracture_force, p)
#			spawnFractureBody(shard, mass * (shard.area / cur_area), p)
	
	
	if not fracture_info or not fracture_info.shapes or fracture_info.shapes.size() <= 0:
#		if not award_points:
#			score_points = 0
		
		if hasRegeneration():
			regeneration_started = false
			regeneration_timer.stop()
		
		call_deferred("kill")
		percent_cut = 1.0
		cur_area = 0.0
	else:
		var cur_shape
		var biggest_area : float = -1
		for shape in fracture_info.shapes:
			if shape.area > biggest_area:
				biggest_area = shape.area
				cur_shape = shape
		
#		if polygon_restorer:
#			polygon_restorer.addShape(_polygon.get_polygon(), cur_area)
		
		if polygon_restorer:
			polygon_restorer.addShape(cur_shape.shape, cur_shape.area)
		
		setPolygon(cur_shape.shape)
		
#		SoundServer.play2D("hurt", global_position, "blob", 1.0, SoundServer.OVERRIDE_BEHAVIOUR.OLDEST, -1)
		
		if _rng.randf() > 0.1:
			apply_central_impulse(knockback_force)
			knockback_timer = knockback_time
		
		percent_cut = cur_shape.area / cur_area
		cur_area = cur_shape.area
		
		_hit_flash_anim_player.play("hit-flash")
		
		_drop_poly.modulate.a = lerp(0.2, 0.7, 1.0 - getHealthPercent())
		
		_invincible_timer.start(invincible_time)
		if hasRegeneration():
			if canRegenerate():
				var rand_time : float = _rng.randf_range(abs(regeneration_interval_range.x), abs(regeneration_interval_range.y))
				regeneration_timer.start(rand_time)
				if not regeneration_started:
					regeneration_started = true
					applyColor(regeneration_color)
			
	return {"percent_cut" : percent_cut , "dead" : isDead()}


func setNewTargetPos() -> void:
	if not target or not is_instance_valid(target): 
		prev_target_pos = Vector2.ZERO
		var rand_angle : float = _rng.randf() * 2.0 * PI
		var v := Vector2.RIGHT.rotated(rand_angle) * _rng.randf() * 1500
		target_pos = Vector3(v.x, v.y, 1.0)
		return
	if keep_distance_range.y <= 0.0:
		target_pos = Vector3(target.global_position.x, target.global_position.y, 1.0)
		prev_target_pos = target.global_position
	else:
		var random_rot : float = _rng.randf_range(0, PI * 2.0)
		var pos : Vector2 = target.global_position + Vector2.RIGHT.rotated(random_rot) * _rng.randf_range(keep_distance_range.x, keep_distance_range.y)
		target_pos = Vector3(pos.x, pos.y, 1.0)
		prev_target_pos = target.global_position


func startTargetPosTimer(min_time : float, max_time : float) -> void:
	if max_time <= 0.0: return
	var time : float = _rng.randf_range(min_time, max_time)
	_target_pos_timer.start(time)


func kill() -> void:
#	SoundServer.play2D("die", global_position, "blob", 1.0, SoundServer.OVERRIDE_BEHAVIOUR.OLDEST, -1)
	emit_signal("Died", self, global_position)
	queue_free()


func heal(heal_amount : float) -> void:
	if canBeHealed():
		if getHealthPercent() > heal_treshold:
			setPolygon(start_poly)
			cur_area = start_area
			_hit_flash_anim_player.play("heal")
			_drop_poly.modulate.a = lerp(0.2, 0.7, 1.0 - getHealthPercent())
			if hasRegeneration():
				regeneration_started = false
				regeneration_timer.stop()
				applyColor(color_default)
		else:
			if total_frame_heal_amount == 0.0:
				call_deferred("restore")
			total_frame_heal_amount += heal_amount


func restore() -> void:
	if total_frame_heal_amount > 0.0:
		var poly : PackedVector2Array
		var area : float = 0.0
		if polygon_restorer:
			var shape_entry : Dictionary = polygon_restorer.popLast()
			poly = shape_entry.shape
			area = shape_entry.area
		else:
			poly = PolygonLib.restorePolygon(_polygon.get_polygon(), start_poly, total_frame_heal_amount)
			area = PolygonLib.getPolygonArea(poly)
		
		if area / start_area > heal_treshold:
			cur_area = start_area
			setPolygon(start_poly)
		else:
			cur_area = area
			setPolygon(poly)
		
		_hit_flash_anim_player.play("heal")
		_drop_poly.modulate.a = lerp(0.2, 0.7, 1.0 - getHealthPercent())
		
		if hasRegeneration():
			if getHealthPercent() < 1.0:
				if canRegenerate():
					var rand_time : float = _rng.randf_range(abs(regeneration_interval_range.x), abs(regeneration_interval_range.y))
					regeneration_timer.start(rand_time)
			else:
				regeneration_started = false
				applyColor(color_default)
		
	total_frame_heal_amount = 0.0


func setPolygon(new_polygon : PackedVector2Array, exclude_main_poly : bool = false) -> void:
	_col_polygon.call_deferred("set_polygon", new_polygon)
	
	if not exclude_main_poly:
		_polygon.set_polygon(new_polygon)
	
	_hit_flash_poly.set_polygon(new_polygon)
	new_polygon.append(new_polygon[0])
	_line.points = new_polygon


func processKnockbackTimer(delta : float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta * knockback_resistance
		if knockback_timer <= 0.0:
			knockback_timer = 0.0




func _on_TargetPosTimer_timeout() -> void:
	setNewTargetPos()
	startTargetPosTimer(target_pos_interval_range.x, target_pos_interval_range.y)


func On_Regeneration_Timer_Timeout() -> void:
	heal(regeneration_amount)
