extends Node2D



enum HEAL_METHOD {DISABLED = 0, INTERVAL = 1, TRIGGER = 2}



export(bool) var mode_static : bool = false
export(float, 1.0, 1000.0) var radius : float = 1.0
export(int, 0, 4) var smoothing : int = 0
export(int, LAYERS_2D_PHYSICS) var collision_layer


export(HEAL_METHOD) var heal_method : int = HEAL_METHOD.DISABLED
export(float) var heal_amount : float = 0.1
export(float) var heal_interval : float = 1.0
export(bool) var autostart : bool = false
export(bool) var enabled : bool = true

var _heal_timer : Timer = null
var _heal_enabled : bool = false


onready var _polygon2d := $Polygon2D
onready var _circle_cast := $CircleCast
onready var _anim_player := $AnimationPlayer


func isEnabled() -> bool:
	return _heal_enabled and not heal_method == HEAL_METHOD.DISABLED



func _ready() -> void:
	_heal_enabled = enabled

	var poly : PoolVector2Array = PolygonLib.createCirclePolygon(radius, smoothing, Vector2.ZERO)
	setPolygon(poly)
	
	_circle_cast.radius = radius
	_circle_cast.collision_layer = collision_layer
	
	if heal_method == HEAL_METHOD.INTERVAL:
		var timer := Timer.new()
		add_child(timer)
		timer.wait_time = heal_interval
		timer.one_shot = false
		timer.autostart = false
		timer.connect("timeout", self, "On_Heal_Timer_Timeout")
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



func setPolygon(polygon : PoolVector2Array) -> void:
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