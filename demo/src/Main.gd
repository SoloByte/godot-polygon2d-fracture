extends Node2D




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
