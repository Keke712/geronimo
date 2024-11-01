[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/RunnerButton.ui")]
public class RunnerButton : Gtk.ListBoxRow {

public AstalApps.Application app {get; construct;}
public int score { get; set;}

[GtkCallback]
public void clicked () {
	app.launch ();
}
[GtkCallback]
public void activated () {
	app.launch ();
}

public RunnerButton (AstalApps.Application app) {
	Object (app: app);
}

}