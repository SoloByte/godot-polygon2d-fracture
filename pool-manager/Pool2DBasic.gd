extends Node



#!!!----All pooled instances need these 4 things----!!!
#func spawn(pos : Vector2) -> called when instance is used
#func despawn() -> called when instance is finished
#signal Despawn(self) -> instance emits this signal when finished to let the pool know to despawn it
#-----------------------------------------------------



#if pool is added to scene tree from the editor use this or setup the pool via code later
export(bool) var placed_in_level : bool = false
export(PackedScene) var instance_template
export(int) var max_amount : int = 0
export(bool) var instantiate_new_on_empty : bool = false
export(bool) var keep_instances_in_tree : bool = false


#all instances are a child of this node
onready var _instance_parent := $Instances




var template : PackedScene
var max_size : int = 0
var instantiate_new : bool = false
var keep_in_tree : bool = false
#if normal clearPool is used 
#-> the pool waits for instances to be despawned before queue free is called on them
var clear_in_process : bool = false


var instances_ready : Array = []
var instances_in_use : Array = []




func _ready() -> void:
	if placed_in_level:
		setup(instance_template, max_amount, true, instantiate_new_on_empty, keep_instances_in_tree)


func _exit_tree() -> void:
	clearPoolInstant()


func setup(template : PackedScene, max_size : int, ready_on_start : bool, instantiate_new : bool = false, keep_in_tree : bool = false) -> void:
	self.template = template
	self.max_size = max_size
	self.instantiate_new = instantiate_new
	self.keep_in_tree = keep_in_tree
	
	if ready_on_start:
		fillPool()




func getParent():
	return _instance_parent

func getInstance():
	if instances_ready.size() <= 0:
		if instantiate_new:
			addSingleInstance()
			var instance = instances_ready.pop_back()
			instances_in_use.push_back(instance)
			if not keep_in_tree:
				_instance_parent.add_child(instance)
			max_size += 1
			return instance
		else:
			return null
	else:
		var instance = instances_ready.pop_back()
		instances_in_use.push_back(instance)
		if not keep_in_tree:
			_instance_parent.add_child(instance)
		return instance


func fillPool() -> void:
	if max_size <= 0: return
	var cur_size : int = instances_ready.size() + instances_in_use.size()
	addInstances(max(max_size - cur_size, 0))


func clearPoolInstant() -> void:
	for instance in instances_in_use:
		instance.queue_free()
	
	for instance in instances_ready:
		if keep_in_tree:
			instance.queue_free()
		else:
			instance.free()


func clearPool() -> void:
	if clear_in_process: return 
	if instances_in_use.size() > 0:
		clear_in_process = true
	
	for instance in instances_ready:
		if keep_in_tree:
			instance.queue_free()
		else:
			instance.free()


func resizePool(amount : int) -> void:
	if amount == 0: return
	if amount > 0:
		max_size += amount
		addInstances(amount)
	else:
		max_size -= min(amount, max_size)
		removeInstances(max_size)


func addInstances(amount : int) -> void:
	for i in range(amount):
		addSingleInstance()


func addSingleInstance():
	var instance = template.instance()
	instances_ready.push_back(instance)
	if keep_in_tree:
		_instance_parent.add_child(instance)
	instance.connect("Despawn", self, "On_Instance_Despawn")
	return instance


func removeInstances(amount : int) -> void:
	for i in range(abs(amount)):
		if instances_ready.size() > 0:
			var instance = instances_ready.pop_back()
			if keep_in_tree:
				instance.queue_free()
			else:
				instance.free()
		elif instances_in_use.size() > 0:
			var instance = instances_in_use.pop_back()
			instance.queue_free()
		else:
			return





func On_Instance_Despawn(instance) -> void:
	if clear_in_process:
		var index : int = instances_in_use.find(instance)
		if index >= 0:
			instances_in_use.remove(index)
			instance.queue_free()
		
			if instances_in_use.size() <= 0:
				clear_in_process = false
	else:
		var index : int = instances_in_use.find(instance)
		if index >= 0:
			instances_in_use.remove(index)
			instances_ready.append(instance)
			
			if instance.has_method("despawn"):
				instance.despawn()
			
			if not keep_in_tree:
				_instance_parent.remove_child(instance)
