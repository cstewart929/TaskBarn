extends Node

var animals := {}
const SAVE_PATH := "user://animals.save"

func register_animal(animal):
	animals[animal.animal_id] = animal

func unregister_animal(animal):
	animals.erase(animal.animal_id)

func update_and_save():
	var data = {}
	for id in animals:
		var a = animals[id]
		data[id] = {
			"name": a.animal_name,
			"tasks": a.tasks
		}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_all():
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if typeof(result) == TYPE_DICTIONARY:
		return result
	return {} 