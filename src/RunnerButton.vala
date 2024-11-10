[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/RunnerButton.ui")]
public class RunnerButton : Gtk.ListBoxRow {

public AstalApps.Application app {get; construct;}
public int score { get; set;}

[GtkChild]
private unowned Gtk.Label desc_label;

[GtkChild]
private unowned Gtk.Label title_label;

[GtkCallback]
public void clicked () {
	app.launch ();
}
[GtkCallback]
public void activated () {
	app.launch ();
}

public void set_title(string title) {
	title_label.label = title;
}

public void set_description(string desc) {
	desc_label.label = desc;
}

public RunnerButton (AstalApps.Application app) {
	Object (app: app);
}

}