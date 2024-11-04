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

    public BluetoothPanel() {
        Object();
    }

    construct {
        set_css_name("bluetooth_panel");
        
        bluetooth = AstalBluetooth.get_default();
        adapter = bluetooth.adapter;
        
        devices_store = new GLib.ListStore(typeof(AstalBluetooth.Device));
        selection_model = new Gtk.SingleSelection(devices_store);
        
        setup_device_list();
        setup_signals();
        
        // On scan au démarrage si le BT est actif
        if (bluetooth.is_powered) {
            scan_devices.begin();
        }
    }

    private void setup_device_list() {
        var factory = new Gtk.SignalListItemFactory();
        factory.setup.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            box.margin_start = 12;
            box.margin_end = 12;
            
            var icon = new Gtk.Image.from_icon_name("bluetooth-symbolic");
            var label = new Gtk.Label("");
            label.halign = Gtk.Align.START;
            
            box.append(icon);
            box.append(label);
            list_item.child = box;
        });
        
        factory.bind.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var device = list_item.item as AstalBluetooth.Device;
            var box = list_item.child as Gtk.Box;
            var label = box.get_last_child() as Gtk.Label;
            
            string status = device.paired ? " (Appairé)" : device.connected ? " (Connecté)" : "";
            label.label = "%s%s".printf(device.name ?? device.address, status);
            
            var icon = box.get_first_child() as Gtk.Image;
            switch (device.icon) {
                case "audio-card":
                    icon.icon_name = "audio-headphones-symbolic";
                    break;
                case "input-keyboard":
                    icon.icon_name = "input-keyboard-symbolic";
                    break;
                case "input-mouse":
                    icon.icon_name = "input-mouse-symbolic";
                    break;
                default:
                    icon.icon_name = "bluetooth-symbolic";
                    break;
            }
        });
        
        devices_list.model = selection_model;
        devices_list.factory = factory;
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
                status_label.label = "Déconnexion en cours...";
                try {
                    yield wait_milliseconds(500);
                    device.disconnect_profile("*");
                    yield wait_milliseconds(1000);
                    
                    status_label.label = "Appareil déconnecté !";
                    yield scan_devices();
                } catch (Error e) {
                    status_label.label = "Erreur de déconnexion : %s".printf(e.message);
                }
            }
        } catch (Error e) {
            status_label.label = "Erreur : %s".printf(e.message);
        }
    }

    private async void scan_devices() {
        if (!bluetooth.is_powered) return;
        
        adapter.start_discovery();
        devices_store.remove_all();
        
        // On attend un peu que le scan se fasse
        yield wait_milliseconds(1000);
        
        var available_devices = bluetooth.devices;
        foreach (var device in available_devices) {
            devices_store.append(device);
        }

        status_label.label = "Recherche d'appareils...";
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