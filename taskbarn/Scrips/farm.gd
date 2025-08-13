extends Node2D

@onready var add_animal_button: Button = $"Add Animal"
@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var animal_scene: PackedScene = preload("res://Scenes/animal.tscn")
@onready var checklist_menu: Control = $ChecklistMenu
@onready var gun_mode_button: CheckButton = $CheckButton
var gun_mode_active := false
var gun_cursor = preload("res://Assets/gun.png")

func _ready():
	add_animal_button.pressed.connect(_on_add_animal_pressed)
	checklist_menu.visible = false
	checklist_menu.menu_closed.connect(_on_menu_closed)
	gun_mode_button.toggled.connect(_on_gun_mode_toggled)
	_spawn_animals_from_save()

func _spawn_animals_from_save():
	var all_data = AnimalManager.load_all()
	var nav_poly = nav_region.navigation_polygon
	var vertices = nav_poly.get_vertices()
	if vertices.is_empty():
		print("Navigation polygon has no vertices!")
		return
	var min_x = vertices[0].x
	var max_x = vertices[0].x
	var min_y = vertices[0].y
	var max_y = vertices[0].y
	for v in vertices:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
		min_y = min(min_y, v.y)
		max_y = max(max_y, v.y)
	var viewport_width = get_viewport().size.x
	var menu_right = viewport_width / 3.0
	for id in all_data.keys():
		var animal = animal_scene.instantiate()
		animal.animal_id = id
		var d = all_data[id]
		animal.animal_name = d.get("name", "")
		animal.tasks = d.get("tasks", [])
		var tries = 0
		var pos = Vector2.ZERO
		while tries < 20:
			pos = Vector2(
				randf_range(min_x, max_x),
				randf_range(min_y, max_y)
			)
			var global_pos = nav_region.global_position + pos
			if Geometry2D.is_point_in_polygon(pos, vertices) and global_pos.x > menu_right:
				break
			tries += 1
		animal.global_position = nav_region.global_position + pos
		add_child(animal)

func _on_add_animal_pressed():
	print("Add Animal button pressed")
	var animal = animal_scene.instantiate()
	var nav_poly = nav_region.navigation_polygon
	var vertices = nav_poly.get_vertices()
	if vertices.is_empty():
		print("Navigation polygon has no vertices!")
		return
	var min_x = vertices[0].x
	var max_x = vertices[0].x
	var min_y = vertices[0].y
	var max_y = vertices[0].y
	for v in vertices:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
		min_y = min(min_y, v.y)
		max_y = max(max_y, v.y)
	var viewport_width = get_viewport().size.x
	var menu_right = viewport_width / 3.0
	var tries = 0
	var pos = Vector2.ZERO
	while tries < 20:
		pos = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
		var global_pos = nav_region.global_position + pos
		if Geometry2D.is_point_in_polygon(pos, vertices) and global_pos.x > menu_right:
			break
		tries += 1
	animal.global_position = nav_region.global_position + pos
	print("Spawning animal at: ", animal.global_position)
	animal.z_index = 1000
	add_child(animal)

func show_animal_menu(animal):
	checklist_menu.current_animal = animal
	checklist_menu.set_animal_name(animal.animal_name)
	checklist_menu.set_tasks(animal.tasks)
	checklist_menu.visible = true

func _on_menu_closed():
	checklist_menu.visible = false

func _on_gun_mode_toggled(button_pressed):
	gun_mode_active = button_pressed
	if gun_mode_active:
		Input.set_custom_mouse_cursor(gun_cursor)
		checklist_menu.visible = false
	else:
		Input.set_custom_mouse_cursor(null)

func delete_animal(animal):
	animal.queue_free()
	AnimalManager.unregister_animal(animal)
	AnimalManager.update_and_save()
