extends Node2D

@onready var add_animal_button: Button = $"Add Animal"
@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var animal_scene: PackedScene = preload("res://Scenes/animal.tscn")

func _ready():
	add_animal_button.pressed.connect(_on_add_animal_pressed)
	_spawn_animals_from_save()

func _spawn_animals_from_save():
	var all_data = AnimalManager.load_all()
	for id in all_data.keys():
		var animal = animal_scene.instantiate()
		animal.animal_id = id
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
	var tries = 0
	var pos = Vector2.ZERO
	while tries < 10:
		pos = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
		if Geometry2D.is_point_in_polygon(pos, vertices):
			break
		tries += 1
	animal.global_position = nav_region.global_position + pos
	print("Spawning animal at: ", animal.global_position)
	animal.z_index = 1000
	add_child(animal)
