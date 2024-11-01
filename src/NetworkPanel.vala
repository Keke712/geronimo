[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/NetworkPanel.ui")]
public class NetworkPanel : Gtk.Box {
    [GtkChild]
    private unowned Gtk.ListView networks_list;
    
    [GtkChild]
    private unowned Gtk.Button refresh_button;

    private AstalNetwork.Network network;
    private GLib.ListStore network_store;
    private Gtk.SingleSelection selection_model;

    public NetworkPanel() {
        Object();
    }

    construct {
        set_css_name("network_panel");
        
        network = AstalNetwork.get_default();
        
        network_store = new GLib.ListStore(typeof(AstalNetwork.AccessPoint));
        selection_model = new Gtk.SingleSelection(network_store);
        
        var factory = new Gtk.SignalListItemFactory();
        factory.setup.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var label = new Gtk.Label("");
            label.halign = Gtk.Align.START;
            label.margin_start = 12;
            label.margin_end = 12;
            list_item.child = label;
        });
        
        factory.bind.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var ap = list_item.item as AstalNetwork.AccessPoint;
            var label = list_item.child as Gtk.Label;
            label.label = ap.ssid ?? "Réseau inconnu";
        });
        
        networks_list.model = selection_model;
        networks_list.factory = factory;

        // Gestion de la sélection d'un réseau
        networks_list.activate.connect((pos) => {
            var selected_ap = selection_model.selected_item as AstalNetwork.AccessPoint;
            if (selected_ap != null) {
                try {
                    // On active le WiFi si pas déjà fait
                    if (!network.wifi.enabled) {
                        network.wifi.enabled = true;
                    }

                    // On chope l'instance une seule fois, c'est plus propre
                    var quick_settings = QuickSettings.get_instance();
                    var popup = Popup.get_instance();
                    Geronimo.instance.toggle_window("Popup");

                    popup.set_title(selected_ap.ssid);

                    this.visible = false;
                    quick_settings.show_panel("quick");
                    quick_settings.visible = false;  // Ou quick_settings.hide() si tu préfères

                } catch (Error e) {
                    stderr.printf("Erreur connexion: %s\n", e.message);
                }
            }
        });
        
        refresh_button.clicked.connect(() => {
            scan_networks();
        });
        
        scan_networks();
    }

    private void scan_networks() {
        network.wifi.scan();
        
        network_store.remove_all();
        var available_networks = network.wifi.access_points;
        
        foreach (var ap in available_networks) {
            network_store.append(ap);
        }
    }
}