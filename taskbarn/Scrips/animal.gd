extends CharacterBody2D

# Nodes
@onready var sprite: Sprite2D = $Sprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var area: Area2D = $Area2D
@onready var checklist_menu_scene: PackedScene = preload("res://Scenes/checklist_menu.tscn")
var checklist_menu: Control = null
@onready var name_label: Label = $NameLabel
var animal_id: String = ""

# Animal data
var animal_name: String = ""
var tasks: Array = []
var is_menu_open: bool = false

# Movement
var roam_timer: float = 0.0
var roam_pause: float = 1.0

func _ready():
	# Connect click signal
	area.input_event.connect(_on_area_input_event)
	# Generate unique ID if not loaded
	if animal_id == "":
		animal_id = str(randi()) + "_" + str(Time.get_unix_time_from_system()) + "_" + str(Time.get_ticks_usec())
	# Register with AnimalManager
	AnimalManager.register_animal(self)
	# Load animal data from manager if present
	var all_data = AnimalManager.load_all()
	if animal_id in all_data:
		var d = all_data[animal_id]
		animal_name = d.get("name", "")
		tasks = d.get("tasks", [])
	# Set initial texture
	update_texture()
	# Set name label
	name_label.text = animal_name
	# Start roaming
	sprite.z_index = 900

func _process(delta):
	if is_menu_open:
		velocity = Vector2.ZERO
		return
	roam_timer -= delta
	if tasks.size() < 1:
		return
	if roam_timer <= 0 and nav_agent.is_navigation_finished():
		roam_to_random_point()

func roam_to_random_point():
	# Find the NavigationRegion2D in the scene tree
	var nav_region = get_tree().get_root().find_child("NavigationRegion2D", true, false)
	if nav_region == null:
		return
	var nav_poly = nav_region.navigation_polygon
	var vertices = nav_poly.get_vertices()
	if vertices.is_empty():
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
	nav_agent.target_position = nav_region.global_position + pos
	roam_pause = randf_range(1.0, 3.0)
	roam_timer = roam_pause

func _physics_process(delta):
	if !is_menu_open:
		# Move towards target
		if nav_agent.is_navigation_finished():
			velocity = Vector2.ZERO
		else:
			velocity = nav_agent.get_next_path_position() - global_position
			velocity = velocity.normalized() * 50 # Adjust speed as needed
		move_and_slide()

func _on_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		open_checklist_menu()

func open_checklist_menu():
	is_menu_open = true
	if checklist_menu == null:
		checklist_menu = checklist_menu_scene.instantiate()
		get_tree().root.add_child(checklist_menu)
		checklist_menu.set_animal_name(animal_name)
		checklist_menu.set_tasks(tasks)
		checklist_menu.name_changed.connect(_on_menu_name_changed)
		checklist_menu.tasks_changed.connect(_on_menu_tasks_changed)
		checklist_menu.menu_closed.connect(close_checklist_menu)
	else:
		print("Checklist menu reused.")
	checklist_menu.set_animal_name(animal_name)
	checklist_menu.set_tasks(tasks)
	checklist_menu.show()
	await get_tree().process_frame
	var offset = Vector2(10, -10)
	var camera = get_viewport().get_camera_2d()
	var menu_size = checklist_menu.size
	var viewport_size = get_viewport().size

func close_checklist_menu():
	is_menu_open = false
	if checklist_menu:
		checklist_menu.hide()

func _on_menu_name_changed(new_name):
	animal_name = new_name
	name_label.text = animal_name
	AnimalManager.update_and_save()

func _on_menu_tasks_changed(new_tasks):
	tasks = new_tasks.duplicate()
	update_texture()
	AnimalManager.update_and_save()

func update_texture():
	var tex_path = "res://Assets/egg.png"
	if tasks.size() < 1:
		tex_path = "res://Assets/egg.png"
	elif tasks.size() < 3:
		tex_path = "res://Assets/chicken.png"
	elif tasks.size() < 5:
		tex_path = "res://Assets/pig.png"
	elif tasks.size() < 10:
		tex_path = "res://Assets/cow.png"
	else:
		tex_path = "res://Assets/dragon.png"
	sprite.texture = load(tex_path)

func _exit_tree():
	AnimalManager.unregister_animal(self)
