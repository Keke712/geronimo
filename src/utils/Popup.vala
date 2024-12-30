
[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/utils/Popup.ui")]
public class Popup : Astal.Window {
    // créer une instance statique de la classe QuickSettings
    private static Popup? instance;

    public Popup() {
        Object (
            name: "Popup",
            namespace: "Popup"
        );
        // On stock l'instance dès la création
        instance = this;
    }

    // Method pour chopper l'instance depuis n'importe où
    public static Popup get_instance() {
        return instance;
    }

    construct {
        init_layer_properties ();
        set_css_name("popup");
        set_default_size(200, 100);
        set_modal(true);

        status_label.visible = false;
    }

    [GtkChild]
    private unowned Gtk.Label title_label;

    [GtkChild]
    private unowned Gtk.Entry entry;

    [GtkChild]
    private unowned Gtk.Label status_label;

    public void init_layer_properties() {
        GtkLayerShell.init_for_window(this);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.OVERLAY);
        GtkLayerShell.set_keyboard_mode(this, GtkLayerShell.KeyboardMode.ON_DEMAND);
        
        GtkLayerShell.set_namespace(this, "Popup");
        
        // On ancre que sur les côtés et le haut
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.RIGHT, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, false);  // Plus d'ancrage en bas
        
        // Marges sur les côtés et le haut seulement
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 400);
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.RIGHT, 400);
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.TOP, 50);  // Petite marge en haut
    }

    public void present_layer () {
        this.present ();
        this.visible = false;
    }

    // Méthode pour update le titre
    public void update_title(string title) {
        // Vérifie que le label existe avant de le modifier
        if (title_label != null) {
            title_label.label = title;
        }
    }

    [GtkCallback]
    public void key_released (uint keyval) {
        if (keyval == Gdk.Key.Escape) {
            this.visible = false;
        }
    }

    [GtkCallback]
    public void confirm() {
        string password = entry.get_text();
        // Mettre à jour le label de statut si tu l'as
        status_label.visible = true;
        status_label.label = "Tentative de connexion...";

        // ça va bien attendre que le dev mette en place le connect to wifi
        // network.wifi.connect_to_network(selected_ap, password);
    }

}