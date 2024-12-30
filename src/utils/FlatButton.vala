[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/utils/FlatButton.ui")]
public class FlatButton : Gtk.Box {

public AstalNetwork.Network network { get; set; }

public signal void clicked ();
public signal void clicked_extras ();

public string icon { get; set; }
public string file { get; set; }
public bool extra_visible { get; set; default=true; }

public bool active {
	get {
		return this.has_css_class ("flatbutton-active");
	}
	set {
		if (value)
			this.add_css_class ("flatbutton-active");
		else
			this.remove_css_class ("flatbutton-active");
	}
}
public bool inactive {
	get {
		return !this.has_css_class ("flatbutton-active");
	}
	set {
		if (!value)
			this.add_css_class ("flatbutton-active");
		else
			this.remove_css_class ("flatbutton-active");
	}
}

[GtkCallback]
public void on_clicked () {
	clicked ();
}

[GtkCallback]
public void on_clicked_extras () {
	clicked_extras ();
}

static construct {
	set_css_name ("flatbutton");
}
FlatButton () {
	Object (
		name: "FlatButton"
		);
	network = AstalNetwork.get_default ();
}
}