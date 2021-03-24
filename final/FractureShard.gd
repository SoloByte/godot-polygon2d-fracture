class_name FractureShard




var polygon : PoolVector2Array
var centroid := Vector2.ZERO
var world_pos := Vector2.ZERO
var area : float = 0.0




func _init(poly : PoolVector2Array, centroid : Vector2, world_pos : Vector2, area : float) -> void:
	self.polygon = poly
	self.centroid = centroid
	self.world_pos = world_pos
	self.area = area
