[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/HeaderPanel.ui")]
public class HeaderPanel : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Button back_button;
    
    [GtkChild]
    private unowned Gtk.Button refresh_button;

    [GtkChild]
    private unowned Gtk.Label title_label;

    public string title {
        get { return title_label.label; }
        set { title_label.label = value; }
    }

    public signal void on_back_clicked();
    public signal void on_refresh_clicked();

    public HeaderPanel() {
        Object();
    }

    construct {
        back_button.clicked.connect(() => {
            on_back_clicked();
        });

        refresh_button.clicked.connect(() => {
            on_refresh_clicked();
        });
    }
}