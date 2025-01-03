public static void main (string[] args) {
	var app = new Geronimo();
	init_types(); // Initialize custom types
	app.run(args); // Run the application
}

// Ensure custom types are registered
private void init_types () {
	typeof (FlatButton).ensure ();
}