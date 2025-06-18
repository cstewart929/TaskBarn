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

var tasks: Array = []

func _ready():
	add_task_button.pressed.connect(_on_add_task_pressed)
	close_button.pressed.connect(_on_close_pressed)
	name_edit.text_changed.connect(_on_name_changed)

func set_animal_name(name: String):
	name_edit.text = name

func set_tasks(task_list: Array):
	tasks = task_list.duplicate()
	_refresh_checklist()

func _on_name_changed(new_text):
	emit_signal("name_changed", new_text)

func _on_add_task_pressed():
	var task_text = add_task_edit.text.strip_edges()
	if task_text != "":
		tasks.append({"text": task_text, "completed": false})
		add_task_edit.text = ""
		_refresh_checklist()
		emit_signal("task_added", task_text)
		emit_signal("tasks_changed", tasks)

func _on_task_toggled(idx, pressed):
	tasks[idx]["completed"] = pressed
	emit_signal("task_toggled", idx, pressed)
	emit_signal("tasks_changed", tasks)

func _refresh_checklist():
	for child in checklist_container.get_children():
		child.queue_free()
	for i in range(tasks.size()):
		var hbox = HBoxContainer.new()
		var checkbox = CheckBox.new()
		checkbox.button_pressed = tasks[i]["completed"]
		checkbox.toggled.connect(func(pressed): _on_task_toggled(i, pressed))
		var label = Label.new()
		label.text = tasks[i]["text"]
		hbox.add_child(checkbox)
		hbox.add_child(label)
		checklist_container.add_child(hbox)

func _on_close_pressed():
	emit_signal("menu_closed")
	hide() 
