[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/BluetoothPanel.ui")]
public class BluetoothPanel : Gtk.Box {
    [GtkChild]
    private unowned Gtk.ListView devices_list;
    
    [GtkChild]
    private unowned Gtk.Button back_button;

    [GtkChild]
    private unowned Gtk.Button refresh_button;
    
    [GtkChild]
    private unowned Gtk.Label status_label;

    private AstalBluetooth.Bluetooth bluetooth;
    private AstalBluetooth.Adapter adapter;

    private GLib.ListStore devices_store;
    private Gtk.SingleSelection selection_model;

    // stockage appareils connectés
    private GLib.HashTable<string, AstalBluetooth.Device> connected_devices;

    public BluetoothPanel() {
        Object();
    }

    construct {
        set_css_name("bluetooth_panel");
        
        bluetooth = AstalBluetooth.get_default();
        adapter = bluetooth.adapter;
        
        devices_store = new GLib.ListStore(typeof(GLib.Object));
        selection_model = new Gtk.SingleSelection(devices_store);
        connected_devices = new GLib.HashTable<string, AstalBluetooth.Device>(str_hash, str_equal);
        
        setup_device_list();
        setup_signals();
        
        // On scan au démarrage si le BT est actif
        if (bluetooth.is_powered) {
            scan_devices.begin();
        }
    }

    // Classe pour les headers
    private class HeaderItem : Object {
        public string title { get; construct; }
        
        public HeaderItem(string title) {
            Object(title: title);
        }
    }

    private void setup_device_list() {
        var factory = new Gtk.SignalListItemFactory();
        
        factory.setup.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6) {
                margin_start = 12,
                margin_end = 12
            };
            
            var icon = new Gtk.Image();
            var label = new Gtk.Label("") {
                halign = Gtk.Align.START,
                hexpand = true
            };
            
            box.append(icon);
            box.append(label);
            list_item.child = box;
        });
        
        factory.bind.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var device = list_item.item as AstalBluetooth.Device;
            var box = list_item.child as Gtk.Box;
            
            var icon = box.get_first_child() as Gtk.Image;
            var label = icon.get_next_sibling() as Gtk.Label;
            
            // Si c'est un header
            if (list_item.item is HeaderItem) {
                var header = list_item.item as HeaderItem;
                label.label = header.title;
                label.add_css_class("separator-label");
                icon.visible = false;
                
                
                return;
            }
            
            // Sinon c'est un appareil normal
            icon.visible = true;
            string status = get_device_status(device);
            label.label = "%s%s".printf(device.name ?? device.address, status);
            icon.icon_name = get_device_icon(device);
        });
        
        devices_list.model = selection_model;
        devices_list.factory = factory;
    }
    
    private string get_device_status(AstalBluetooth.Device device) {
        if (device.paired) return " (Appairé)";
        if (device.connected) return " (Connecté)";
        return "";
    }
    
    private string get_device_icon(AstalBluetooth.Device device) {
        if (device.connected) return "stateshape";
        
        switch (device.icon) {
            case "audio-card":
                return "new-audio-alarm-symbolic";
            case "input-keyboard":
                return "input-keyboard-virtual-show-symbolic";
            case "input-mouse":
                return "input-mouse-click-middle-symbolic";
            default:
                return "network-bluetooth";
        }
    }

    private void setup_signals() {

        devices_list.activate.connect((pos) => {
            var selected_device = selection_model.selected_item as AstalBluetooth.Device;
            handle_device_action.begin(selected_device);
        });

        back_button.clicked.connect(() => {
            QuickSettings.get_instance().show_panel("quick");
        });
        
        refresh_button.clicked.connect(() => {
            scan_devices.begin();
        });
    }

    private async void handle_device_action(AstalBluetooth.Device? device) {
        if (device == null) return;

        try {
            if (!device.paired) {
                status_label.label = "Appairage en cours...";
                try {
                    // On attend un peu avant et après pour être sûr
                    yield wait_milliseconds(500);
                    device.pair();  // Méthode sync
                    yield wait_milliseconds(1000);
                    
                    status_label.label = "Appareil appairé !";
                    yield scan_devices();
                } catch (Error e) {
                    status_label.label = "Erreur d'appairage : %s".printf(e.message);
                }
            } else if (!device.connected) {
                status_label.label = "Connexion en cours...";
                try {
                    yield wait_milliseconds(500);
                    device.connect_profile("*");
                    yield wait_milliseconds(1000);
                    
                    status_label.label = "Appareil connecté !";
                    yield scan_devices();
                } catch (Error e) {
                    status_label.label = "Erreur de connexion : %s".printf(e.message);
                }
            } else {
                device_disconnect.begin(device);
            }
        } catch (Error e) {
            status_label.label = "Erreur : %s".printf(e.message);
        }
    }

    private async void device_disconnect(AstalBluetooth.Device device) {
        status_label.label = "Déconnexion en cours...";
        try {
            yield wait_milliseconds(500);
            
            try {
                yield device.disconnect_device();
            } catch (GLib.Error disconnect_error) {
                print("Disconnect error: %s\n", disconnect_error.message);
            }
            
            yield wait_milliseconds(1000);
            status_label.label = "Appareil déconnecté !";
            yield scan_devices();
        } catch (Error e) {
            status_label.label = "Erreur de déconnexion : %s".printf(e.message);
        }
    }

    private async void scan_devices() {
        if (!bluetooth.is_powered) return;
        
        try {
            if (adapter.discovering) {
                adapter.stop_discovery();
                yield wait_milliseconds(500);
            }
            
            adapter.start_discovery();
            devices_store.remove_all();
            yield wait_milliseconds(1000);
            
            var connected = new GenericArray<AstalBluetooth.Device>();
            var disconnected = new GenericArray<AstalBluetooth.Device>();
            
            foreach (var device in bluetooth.devices) {
                if (device.connected) {
                    connected.add(device);
                } else {
                    disconnected.add(device);
                }
            }
            
            // Ajouter le header pour les appareils connectés si il y en a
            if (connected.length > 0) {
                devices_store.append(new HeaderItem("Appareils connectés"));
                foreach (var device in connected.data) {
                    devices_store.append(device);
                }
            }
            
            // Ajouter le header pour les appareils non connectés si il y en a
            if (disconnected.length > 0) {
                devices_store.append(new HeaderItem("Appareils disponibles"));
                foreach (var device in disconnected.data) {
                    devices_store.append(device);
                }
            }
            
            status_label.label = "Recherche d'appareils...";
        } catch (Error e) {
            status_label.label = "Erreur lors du scan : %s".printf(e.message);
        }
    }

    // Helper pour attendre en async
    private async void wait_milliseconds(uint ms) {
        Timeout.add(ms, () => {
            wait_milliseconds.callback();
            return false;
        });
        yield;
    }
}