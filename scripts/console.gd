extends CanvasLayer

var console_commands = preload("res://scripts/console_commands.gd")
var console_cvars = preload("res://scripts/console_cvars.gd")
# All recognized commands
var commands = {}
# All recognized cvars
var cvars = {}

var cmd_history = []
var cmd_history_count = 0
var cmd_history_up = 0

var console_opened = false

func _ready():
	$output.set_selection_enabled(true)
	$output.set_scroll_follow(true)
	$output.set_focus_mode($output.FOCUS_NONE)

	append_bbcode("Type [color=yellow]cmdlist[/color] to get a list of all commands avaliables\n")
	append_bbcode("Type [color=yellow]cvarlist[/color] to get a list of all cvars avaliables\n")

	# Register commands
	register_command("echo", {
		description = "Prints a string in console",
		args = "<string>",
		num_args = 1
	})

	register_command("cmdlist", {
		description = "Lists all available commands",
		args = "",
		num_args = 0
	})

	register_command("cvarlist", {
		description = "Lists all available cvars",
		args = "",
		num_args = 0
	})

	register_command("history", {
		description = "Print all previous cmd used during the session",
		args = "",
		num_args = 0
	})

	register_command("quit", {
		description = "Exits the application",
		args = "",
		num_args = 0
	})

	register_command("clear", {
		description = "Clear the terminal",
		args = "",
		num_args = 0
	})

	register_command("debug_info", {
		description = "Toggle debug info",
		args = "",
		num_args = 0
	})

	# Register cvars
	register_cvar("max_fps", {
		description = "The maximal framerate at which the application can run",
		type = "int",
		default_value = 100,
		min_value = 10,
		max_value = 1000
	})

	register_cvar("fov", {
		description = "The fov of the camera",
		type = "int",
		default_value = 90,
		min_value = 50,
		max_value = 100
	})

# Registers a new command
func register_command(name, args):
	commands[name] = args

# Registers a new cvar (control variable)
func register_cvar(name, args):
	cvars[name] = args
	cvars[name].value = cvars[name].default_value

func append_bbcode(bbcode):
	$output.set_bbcode($output.get_bbcode() + bbcode)

func _input(event):
	if event.is_action_pressed("console_toggle"):
		if !console_opened:
			get_tree().set_pause(true)
			$animation_player.play("fade_in")
			$output.show()
			$input.show()
			$input.grab_focus()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			console_opened = true
		elif console_opened:
			get_tree().set_pause(false)
			$animation_player.play("fade_out")
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			console_opened = false

	if event.is_action_pressed("console_up"):
		if (cmd_history_up > 0 and cmd_history_up <= cmd_history.size()):
			cmd_history_up-=1
			$input.text = (cmd_history[cmd_history_up])

	if event.is_action_pressed("console_down"):
		if (cmd_history_up > -1 and cmd_history_up + 1 < cmd_history.size()):
			cmd_history_up +=1
			$input.text = (cmd_history[cmd_history_up])

	if $input.text != "" and $input.has_focus() and Input.is_key_pressed(KEY_TAB):
		complete()

func _on_animation_player_animation_finished(anim_name):
	if !console_opened:
		$output.hide()
		$input.hide()

func _on_input_text_entered(text):
	if cmd_history.size() > 0:
		if (text != cmd_history[cmd_history_count - 1]):
			cmd_history.append(text)
			cmd_history_count+=1
	else:
		cmd_history.append(text)
		cmd_history_count+=1
	cmd_history_up = cmd_history_count

	var text_splitted = text.split(" ", true)
	# Don't do anything if the LineEdit contains only spaces
	if not text.empty() and text_splitted[0]:
		handle_command(text)
		$input.clear()

func handle_command(text):
	# The current console text, splitted by spaces (for arguments)
	var cmd = text.split(" ", true)
	# Check if the first word is a valid command
	if commands.has(cmd[0]):
		var command = commands[cmd[0]]
		print("> " + text)
		append_bbcode("[b]> " + text + "[/b]\n")
		# If no argument is supplied, then show command description and usage, but only if command has at least 1 argument required
		if cmd.size() == 1 and not command.num_args == 0:
			describe_command(cmd[0])
		else:
			# Run the command! If there are no arguments, don't pass any to the other script.
			if command.num_args == 0:
				console_commands.call(cmd[0].replace(".",""))
			else:
				console_commands.call(cmd[0].replace(".",""), text)

	# Check if the first word is a valid cvar
	elif cvars.has(cmd[0]):
		var cvar = cvars[cmd[0]]
		print("> " + text)
		append_bbcode("[b]> " + text + "[/b]\n")
		# If no argument is supplied, then show cvar description and usage
		if cmd.size() == 1:
			describe_cvar(cmd[0])
		else:
			# Let the cvar change values!
			if cvar.type == "str":
				for word in range(1, cmd.size()):
					if word == 1:
						cvar.value = str(cmd[word])
					else:
						cvar.value += str(" " + cmd[word])
			elif cvar.type == "int":
					cvar.value = int(cmd[1])
			elif cvar.type == "float":
				cvar.value = float(cmd[1])

			# Call setter code
			if cvar.value < cvar.min_value or cvar.value > cvar.max_value:
				append_bbcode("[i][color=#ff8888]" + str(cvar.value) + " is not a valid value[/color][/i]\n")
			else:
				console_cvars.call(cmd[0], cvar.value)
	else:
		# Treat unknown commands as unknown
		append_bbcode("[b]> " + text + "[/b]\n")
		append_bbcode("[i][color=#ff8888]Unknown command or cvar: " + cmd[0] + "[/color][/i]\n")

func get_history_str():
	var strOut = ""
	var count = 0
	for i in cmd_history:
		strOut += "[color=#ffff66]" + str(count) + ".[/color] " + i + "\n"
		count+=1
	return strOut

func complete():
	var text = $input.text
	var matches = 0
	# If there are no matches found yet, try to complete for a command or cvar
	if matches == 0:
		for command in commands:
			if command.begins_with(text):
				describe_command(command)
				$input.text = (command + " ")
				$input.set_cursor_position(100)
				matches += 1
		for cvar in cvars:
			if cvar.begins_with(text):
				describe_cvar(cvar)
				$input.text = (cvar + " ")
				$input.set_cursor_position(100)
				matches += 1

# Describes a command, user by the "cmdlist" command and when the user enters a command name without any arguments (if it requires at least 1 argument)
func describe_command(cmd):
	var command = commands[cmd]
	var description = command.description
	var args = command.args
	var num_args = command.num_args
	if num_args >= 1:
		append_bbcode("[color=#ffff66]" + cmd + ":[/color] " + description + " [color=#88ffff](usage: " + cmd + " " + args + ")[/color]\n")
	else:
		append_bbcode("[color=#ffff66]" + cmd + ":[/color] " + description + " [color=#88ffff](usage: " + cmd + ")[/color]\n")

# Describes a cvar, used by the "cvarlist" command and when the user enters a cvar name without any arguments
func describe_cvar(cvar):
	var cvariable = cvars[cvar]
	var description = cvariable.description
	var type = cvariable.type
	var default_value = cvariable.default_value
	var value = cvariable.value
	if type == "str":
		append_bbcode("[color=#88ff88]" + str(cvar) + ":[/color] [color=#9999ff]\"" + str(value) + "\"[/color]  " + str(description) + " [color=#ff88ff](default: \"" + str(default_value) + "\")[/color]\n")
	else:
		var min_value = cvariable.min_value
		var max_value = cvariable.max_value
		append_bbcode("[color=#88ff88]" + str(cvar) + ":[/color] [color=#9999ff]" + str(value) + "[/color]  " + str(description) + " [color=#ff88ff](min: " + str(min_value) + ", max: " + str(max_value) + ", default: " + str(default_value) + ")[/color]\n")

# Exit the application
func quit():
	get_tree().quit()

# Clear the console output
func clear():
	$output.set_bbcode("")

# Change the camera fov
func fov(value):
	$"../main/player/head/camera".set_fov(int(value))