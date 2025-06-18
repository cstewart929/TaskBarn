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

# Add nav polygon cache for drag/throw clamping
var nav_vertices: Array = []
var nav_global: Vector2 = Vector2.ZERO

# Drag and throw
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO
var throw_velocity: Vector2 = Vector2.ZERO

var last_stage: int = -1
var smoke_scene: PackedScene = preload("res://Scenes/smoke_puff.tscn")

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
	# Cache nav polygon for drag/throw
	var nav_region = get_tree().get_root().find_child("NavigationRegion2D", true, false)
	if nav_region:
		var nav_poly = nav_region.navigation_polygon
		if nav_poly:
			nav_vertices = nav_poly.get_vertices()
			nav_global = nav_region.global_position
	area.body_entered.connect(_on_body_entered)

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
	if is_dragging:
		velocity = Vector2.ZERO
		return
	# Throwing logic
	if throw_velocity.length() > 0.1:
		global_position += throw_velocity * delta
		throw_velocity = throw_velocity.move_toward(Vector2.ZERO, 100 * delta)
	else:
		throw_velocity = Vector2.ZERO
	if !is_menu_open:
		# Move towards target
		if nav_agent.is_navigation_finished():
			velocity = Vector2.ZERO
		else:
			velocity = nav_agent.get_next_path_position() - global_position
			velocity = velocity.normalized() * 50 # Adjust speed as needed
		move_and_slide()

func _on_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Open menu or gun mode
			var farm = get_tree().get_root().find_child("Node2D", true, false)
			if farm:
				if farm.gun_mode_active:
					farm.delete_animal(self)
				else:
					farm.show_animal_menu(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				# Start drag
				is_dragging = true
				drag_offset = global_position - event.global_position
				last_mouse_pos = event.global_position

func _input(event):
	if is_dragging:
		if event is InputEventMouseMotion:
			global_position = event.global_position + drag_offset
			throw_velocity = (event.global_position - last_mouse_pos) * 5.0
			last_mouse_pos = event.global_position
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			# End drag on mouse release anywhere
			is_dragging = false
			throw_velocity = (event.global_position - last_mouse_pos) * 5.0

func update_texture():
	var tex_path = "res://Assets/egg.png"
	var stage = 0
	if tasks.size() < 1:
		tex_path = "res://Assets/egg.png"
		stage = 0
	elif tasks.size() < 3:
		tex_path = "res://Assets/chicken.png"
		stage = 1
	elif tasks.size() < 5:
		tex_path = "res://Assets/pig.png"
		stage = 2
	elif tasks.size() < 10:
		tex_path = "res://Assets/cow.png"
		stage = 3
	else:
		tex_path = "res://Assets/dragon.png"
		stage = 4
	if stage != last_stage:
		# Play smoke puff
		var smoke = smoke_scene.instantiate()
		get_tree().current_scene.add_child(smoke)
		smoke.global_position = global_position
		smoke.get_node("CPUParticles2D").emitting = true
	last_stage = stage
	sprite.texture = load(tex_path)

func _exit_tree():
	AnimalManager.unregister_animal(self)

func _on_body_entered(body):
	if body is CharacterBody2D and body != self:
		# Stop and reverse direction
		if nav_agent.is_navigation_finished():
			return
		# Reverse direction by picking a new random roam point
		roam_to_random_point()
		# Also tell the other animal to reverse
		if "roam_to_random_point" in body:
			body.roam_to_random_point()
