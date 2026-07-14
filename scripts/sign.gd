extends StaticBody3D
## Cartel legible: al interactuar (E) dispara un diálogo de Dialogue Manager.
## El player se encarga de congelar su control mientras dura el diálogo.

@export var dialogue: DialogueResource
@export var dialogue_title := "start"


func start_dialogue() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, dialogue_title)
