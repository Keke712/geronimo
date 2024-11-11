public class Geronimo : Astal.Application {
private string socket_path { get; private set; }
private bool css_loaded = false;

public static Astal.Application instance;

public override void request (string msg, SocketConnection conn) {
	AstalIO.write_sock.begin(conn, @"missing response implementaton on $instance_name");
}

construct {
	instance_name = "geronimo";
	try {
		acquire_socket();
	}catch (Error e) {
		printerr("%s", e.message);
	}
	instance = this;
}

public Geronimo() {
	Object(
		application_id: "com.github.keke712.geronimo",
		flags: ApplicationFlags.HANDLES_COMMAND_LINE
	);
}

[DBus(visible = false)]
public override void activate(){
	base.activate();

	if (!css_loaded) {
		load_css();
		css_loaded = true;
	}

	add_window (new StatusBar ());
	add_window (new QuickSettings ());
	add_window (new Runner ());
	add_window (new Popup ());

	this.hold();
}

void load_css () {
	Gtk.CssProvider provider = new Gtk.CssProvider ();
	provider.load_from_resource ("com/github/Keke712/geronimo/geronimo.css");
	Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider,
						   Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
}

public string process_command (string command) {
	string[] args = command.split (" ");
	string response = "";

	switch (args[0]) {
	case "-T" :
	case "--toggle-window" :
		if (args.length > 1) {
			string window_name = args[1];
			open_window (window_name);
		} else {
			response = "Error: Window name not provided";
		}
		break;
	case "-Q":
	case "--quit":
		try {
			this.quit ();
		} catch (GLib.Error e) {
			print("GLib.Error");
		}
		
		break;
	case "-h":
	case "--help":
		response = print_help ();
		break;
	default:
		response = "Unknown command. Use -h to see help.";
		break;
	}
	return response;
}

private string print_help () {
	return "Usage: geronimo [options]\n"
	       + "Options:\n"
	       + "  \033[34m-T|--toggle-window\033[0m \033[32m<window>\033[0m  | Toggle visibility of the specified window\n"
	       + "  \033[34m-Q|--quit\033[0m                    | Quit the application\n"
	       + "  \033[34m-h|--help\033[0m                    | Show this help message";
}

public override int command_line (ApplicationCommandLine command_line) {
	string[] args = command_line.get_arguments ();

	if (args.length > 1) {
		string command = string.joinv (" ", args[1 : args.length]);
		string response = process_command (command);
		command_line.print (response + "\n");
		return 0;
	}

	activate ();
	return 0;
}
}