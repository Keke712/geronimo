using GtkLayerShell;
using Gtk;

[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/DynamicIsland.ui")]
public class DynamicIsland : Astal.Window {

    [GtkChild]
    public unowned Gtk.Box dynamicisland_box;

    private static DynamicIsland? instance;

    [GtkCallback]
    public void key_released(uint keyval) {
        if (keyval == Gdk.Key.Escape) {
            this.visible = false;
        }
    }

    public DynamicIsland() {
        Object (
            anchor: Astal.WindowAnchor.TOP,
            margin_top: 0 // Changed from 20 to 5 to position the panel higher
        );
    }

    public static DynamicIsland get_instance() {
        if (instance == null) {
            instance = new DynamicIsland();
        }
        return instance;
    }

    public void show_panel() {
        this.visible = true;
    }

    public void hide_panel() {
        this.visible = false;
    }
}