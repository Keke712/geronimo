[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/Widgets/NetworkPanel.ui")]
public class NetworkPanel : Gtk.Box {
    [GtkChild]
    private unowned Gtk.ListView networks_list;
    
    private HeaderPanel header;
    private AstalNetwork.Network network;
    private GLib.ListStore network_store;
    private Gtk.SingleSelection selection_model;

    public NetworkPanel() {
        Object();
    }

    construct {
        set_css_name("network_panel");
        
        // Setup header
        header = new HeaderPanel();
        header.title = "Wi-Fi Networks";
        header.on_back_clicked.connect(() => {
            QuickSettings.get_instance().show_panel("quick");
        });
        header.on_refresh_clicked.connect(() => {
            scan_networks();
        });
        
        prepend(header);
        
        // Initialize network components
        network = AstalNetwork.get_default();
        network_store = new GLib.ListStore(typeof(AstalNetwork.AccessPoint));
        selection_model = new Gtk.SingleSelection(network_store);
        
        setup_network_list();
        setup_signals();
        scan_networks();
    }

    private void setup_network_list() {
        var factory = new Gtk.SignalListItemFactory();
        factory.setup.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var label = new Gtk.Label("") {
                halign = Gtk.Align.START,
                margin_start = 12,
                margin_end = 12
            };
            list_item.child = label;
        });
        
        factory.bind.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var ap = list_item.item as AstalNetwork.AccessPoint;
            var label = list_item.child as Gtk.Label;
            label.label = ap.ssid ?? "Unknown Network";
        });
        
        networks_list.model = selection_model;
        networks_list.factory = factory;
    }

    private void setup_signals() {
        networks_list.activate.connect((pos) => {
            var selected_ap = selection_model.selected_item as AstalNetwork.AccessPoint;
            if (selected_ap != null) {
                try {
                    if (!network.wifi.enabled) {
                        network.wifi.enabled = true;
                    }

                    var quick_settings = QuickSettings.get_instance();
                    var popup = Popup.get_instance();
                    Geronimo.instance.toggle_window("Popup");

                    popup.update_title(selected_ap.ssid);

                    this.visible = false;
                    quick_settings.show_panel("quick");
                    quick_settings.visible = false;
                } catch (Error e) {
                    stderr.printf("Connection error: %s\n", e.message);
                }
            }
        });
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