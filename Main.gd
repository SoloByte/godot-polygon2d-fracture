extends Node2D




export(Array, PackedScene) var test_scenes

var _cur_test_scene_index : int = 0
var _cur_test_scene = null



onready var _fracture_slider := $CanvasLayer/FracturesSlider
onready var _min_area_slider := $CanvasLayer/MinAreaSlider 
onready var _fractures_label := $CanvasLayer/FracturesSlider/Label
onready var _min_area_label := $CanvasLayer/MinAreaSlider/Label




func _ready():
	_fracture_slider.grab_focus()
	_fractures_label.text = "Fractures: %d" % _fracture_slider.value
	_min_area_label.text = "Min Area: %d" % _min_area_slider.value
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
	var fracture_node = instance.get_node("Fracture")
	fracture_node.cuts = _fracture_slider.value
	fracture_node.min_area = _min_area_slider.value


func _on_VSlider_value_changed(value):
	_fractures_label.text = "Fractures: %d" % value
	var fracture_node = _cur_test_scene.get_node("Fracture")
	fracture_node.cuts = _fracture_slider.value


func _on_MinAreaSlider_value_changed(value):
	_min_area_label.text = "Min Area: %d" % value
	var fracture_node = _cur_test_scene.get_node("Fracture")
	fracture_node.min_area = _min_area_slider.value
