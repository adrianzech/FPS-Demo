extends Node

# Prints a string in console
static func echo(text):
	# Erase "echo" from the output
	text.erase(0, 5)
	console.append_bbcode(text + "\n")

# Lists all available commands
static func cmdlist():
	var commands = console.commands
	for command in commands:
		console.describe_command(command)

# Lists all available cvars
static func cvarlist():
	var cvars = console.cvars
	for cvar in cvars:
		console.describe_cvar(cvar)

# Print all previous cmd used during the session
static func history():
	console.append_bbcode(console.get_history_str())

# Exits the application
static func quit():
	console.quit()

# Clear the terminal
static func clear():
	console.clear()

# Toggle debug_info
static func debug_info():
	if global.debug_info:
		global.debug_info = false
	else:
		global.debug_info = true