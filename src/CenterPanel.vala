using GtkLayerShell;
using Gtk;

[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/CenterPanel.ui")]
public class CenterPanel : Astal.Window {

    [GtkChild]
    public unowned Gtk.Box centerpanel_box;

    private static CenterPanel? instance;

    [GtkCallback]
    public void key_released(uint keyval) {
        if (keyval == Gdk.Key.Escape) {
            this.visible = false;
        }
    }

    public CenterPanel() {
        Object (
            anchor: Astal.WindowAnchor.TOP,
            margin_top: 0 // Changed from 20 to 5 to position the panel higher
        );
    
        // Set the background color to black
        this.add_css_class("center-panel-black");   
    }

    public static CenterPanel get_instance() {
        if (instance == null) {
            instance = new CenterPanel();
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