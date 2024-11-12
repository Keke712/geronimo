[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/Widgets/BluetoothPanel.ui")]
public class BluetoothPanel : Gtk.Box {
    [GtkChild]
    private unowned Gtk.ListView devices_list;
    
    [GtkChild]
    private unowned Gtk.Label status_label;

    private HeaderPanel header;
    private AstalBluetooth.Bluetooth bluetooth;
    private AstalBluetooth.Adapter adapter;
    private GLib.ListStore devices_store;
    private Gtk.SingleSelection selection_model;
    private GLib.HashTable<string, AstalBluetooth.Device> connected_devices;

    public BluetoothPanel() {
        Object();
    }

    construct {
        set_css_name("bluetooth_panel");
        
        // Setup header
        header = new HeaderPanel();
        header.title = "Bluetooth Devices";
        header.on_back_clicked.connect(() => {
            QuickSettings.get_instance().show_panel("quick");
        });
        header.on_refresh_clicked.connect(() => {
            scan_devices.begin();
        });
        
        prepend(header);
        
        // Initialize bluetooth components
        bluetooth = AstalBluetooth.get_default();
        adapter = bluetooth.adapter;
        devices_store = new GLib.ListStore(typeof(GLib.Object));
        selection_model = new Gtk.SingleSelection(devices_store);
        connected_devices = new GLib.HashTable<string, AstalBluetooth.Device>(str_hash, str_equal);
        
        setup_device_list();
        setup_signals();
        
        if (bluetooth.is_powered) {
            scan_devices.begin();
        }
    }

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
            
            if (list_item.item is HeaderItem) {
                var header = list_item.item as HeaderItem;
                label.label = header.title;
                label.add_css_class("separator-label");
                icon.visible = false;
                return;
            }
            
            icon.visible = true;
            string status = get_device_status(device);
            label.label = "%s%s".printf(device.name ?? device.address, status);
            icon.icon_name = get_device_icon(device);
        });
        
        devices_list.model = selection_model;
        devices_list.factory = factory;
    }
    
    private string get_device_status(AstalBluetooth.Device device) {
        if (device.paired) return " (Paired)";
        if (device.connected) return " (Connected)";
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
    }

    private async void handle_device_action(AstalBluetooth.Device? device) {
        if (device == null) return;

        if (!device.paired) {
            status_label.label = "Pairing in progress...";
            
            yield wait_milliseconds(500);
            device.pair();
            yield wait_milliseconds(1000);
            
            status_label.label = "Device paired!";
            yield scan_devices();
            
        } else if (!device.connected) {
            status_label.label = "Connection in progress...";
            
            yield wait_milliseconds(500);
            device.connect_profile("*");
            yield wait_milliseconds(1000);
            
            status_label.label = "Device connected!";
            yield scan_devices();
            
        } else {
            device_disconnect.begin(device);
        }
    }

    private async void device_disconnect(AstalBluetooth.Device device) {
        status_label.label = "Disconnecting...";
        
        yield wait_milliseconds(500);
        yield device.disconnect_device();
        yield wait_milliseconds(1000);
        
        status_label.label = "Device disconnected!";
        yield scan_devices();
    }

    private async void scan_devices() {
        if (!bluetooth.is_powered) return;
        
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
        
        if (connected.length > 0) {
            devices_store.append(new HeaderItem("Connected Devices"));
            foreach (var device in connected.data) {
                devices_store.append(device);
            }
        }
        
        if (disconnected.length > 0) {
            devices_store.append(new HeaderItem("Available Devices"));
            foreach (var device in disconnected.data) {
                devices_store.append(device);
            }
        }
        
        status_label.label = "Scanning for devices...";
    }

    private async void wait_milliseconds(uint ms) {
        Timeout.add(ms, () => {
            wait_milliseconds.callback();
            return false;
        });
        yield;
    }
}