public static void main (string[] args) {
	var app = new Geronimo();
	init_types();
	app.run(args);
}

private void init_types () {
	typeof (FlatButton).ensure ();
}