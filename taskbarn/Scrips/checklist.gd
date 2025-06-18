extends Control

signal name_changed(new_name)
signal task_added(task_text)
signal task_toggled(index, completed)
signal menu_closed()
signal tasks_changed(tasks)

@onready var name_edit: LineEdit = $Panel/VBoxContainer/HBoxContainer_Name/LineEdit
@onready var add_task_edit: LineEdit = $Panel/VBoxContainer/HBoxContainer_AddTask/LineEdit
@onready var add_task_button: Button = $Panel/VBoxContainer/HBoxContainer_AddTask/Button
@onready var checklist_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ChecklistContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var kill_button: Button = $Panel/VBoxContainer/KillButton

var tasks: Array = []
var current_animal = null

func _ready():
	add_task_button.pressed.connect(_on_add_task_pressed)
	name_edit.text_changed.connect(_on_name_changed)
	kill_button.pressed.connect(_on_kill_pressed)

func set_animal_name(name: String):
	name_edit.text = name
	if current_animal:
		current_animal.animal_name = name
		current_animal.name_label.text = name
		AnimalManager.update_and_save()
	kill_button.text = "Kill " + name

func set_tasks(task_list: Array):
	tasks = task_list.duplicate()
	_refresh_checklist()
	if current_animal:
		current_animal.tasks = tasks.duplicate()
		current_animal.update_texture()
		AnimalManager.update_and_save()

func _on_name_changed(new_text):
	emit_signal("name_changed", new_text)
	if current_animal:
		current_animal.animal_name = new_text
		current_animal.name_label.text = new_text
		AnimalManager.update_and_save()
	kill_button.text = "Kill " + new_text

func _on_add_task_pressed():
	var task_text = add_task_edit.text.strip_edges()
	if task_text != "":
		tasks.append({"text": task_text, "completed": false})
		add_task_edit.text = ""
		_refresh_checklist()
		emit_signal("task_added", task_text)
		emit_signal("tasks_changed", tasks)
		if current_animal:
			current_animal.tasks = tasks.duplicate()
			current_animal.update_texture()
			AnimalManager.update_and_save()

func _on_task_toggled(idx, pressed):
	tasks[idx]["completed"] = pressed
	emit_signal("task_toggled", idx, pressed)
	emit_signal("tasks_changed", tasks)
	if current_animal:
		current_animal.tasks = tasks.duplicate()
		current_animal.update_texture()
		AnimalManager.update_and_save()

func _refresh_checklist():
	for child in checklist_container.get_children():
		child.queue_free()
	for i in range(tasks.size()):
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(180, 0) # Set max width for the row
		var checkbox = CheckBox.new()
		checkbox.button_pressed = tasks[i]["completed"]
		checkbox.toggled.connect(func(pressed): _on_task_toggled(i, pressed))
		var label = Label.new()
		label.text = tasks[i]["text"]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var del_btn = Button.new()
		del_btn.text = "🗑"
		del_btn.connect("pressed", Callable(self, "_on_task_delete_pressed").bind(i))
		row.add_child(checkbox)
		row.add_child(label)
		row.add_child(del_btn)
		checklist_container.add_child(row)

func _on_task_delete_pressed(idx):
	tasks.remove_at(idx)
	_refresh_checklist()
	emit_signal("tasks_changed", tasks)
	if current_animal:
		current_animal.tasks = tasks.duplicate()
		current_animal.update_texture()
		AnimalManager.update_and_save()

func _on_close_pressed():
	emit_signal("menu_closed")
	hide()

func _on_kill_pressed():
	if current_animal:
		current_animal.queue_free()
		AnimalManager.unregister_animal(current_animal)
		AnimalManager.update_and_save()
		hide() 
