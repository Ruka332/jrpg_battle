extends Node

signal new_message(message)

var message_history: Array[String] = []
var max_messages: int = 10

func add_message(text: String):
	message_history.insert(0, text)
	if message_history.size() > max_messages:
		message_history.pop_back()
	emit_signal("new_message", text)
	print("[Battle Log] ", text)  # Debug output
