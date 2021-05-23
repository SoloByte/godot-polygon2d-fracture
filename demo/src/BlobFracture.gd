extends Node2D




onready var _rng := RandomNumberGenerator.new()
onready var _blob_parent := $BlobParent
onready var _pool_cut_visualizer := $Pool_CutVisualizer
onready var _pool_fracture_shards := $Pool_FractureShards



func _ready() -> void:
	for blob in _blob_parent.get_children():
		blob.connect("Damaged", self, "On_Blob_Damaged")
		blob.connect("Fractured", self, "On_Blob_Fractured")



func spawnShapeVisualizer(cut_pos : Vector2, cut_shape : PoolVector2Array, fade_speed : float) -> void:
	var instance = _pool_cut_visualizer.getInstance()
	instance.spawn(cut_pos, fade_speed)
	instance.setPolygon(cut_shape)


func spawnFractureBody(fracture_shard : Dictionary, new_mass : float, color : Color, fracture_force : float, p : float) -> void:
	var instance = _pool_fracture_shards.getInstance()
	if not instance:
		return
	
	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
	instance.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), _rng.randf_range(0.5, 2.0))
	instance.setPolygon(fracture_shard.centered_shape, color, {})
	instance.setMass(new_mass)
#	instance.addForce(dir * 500.0)
#	instance.addTorque(_rng.randf_range(-2, 2))
	instance.addForce(dir * fracture_force * p)
	instance.addTorque(_rng.randf_range(-2, 2) * p)




func On_Blob_Damaged(blob, pos : Vector2, shape : PoolVector2Array, color : Color, fade_speed : float) -> void:
	spawnShapeVisualizer(pos, shape, fade_speed)

func On_Blob_Fractured(blob, fracture_shard : Dictionary, new_mass : float, color : Color, fracture_force : float, p : float) -> void:
	spawnFractureBody(fracture_shard, new_mass, color, fracture_force, p)
