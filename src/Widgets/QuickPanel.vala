[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/Widgets/QuickPanel.ui")]
public class QuickPanel : Gtk.Grid {
    // Properties
    public AstalNetwork.Network network { get; set; }
    public AstalBluetooth.Bluetooth bluetooth { get; set; }
    public AstalNotifd.Notifd notifd { get; private set; }

    [GtkChild]
    private unowned QuickSettingsButton battery_mode;

    // Constructor & initialization
    public QuickPanel() {
        Object();
    }

    construct {
        set_css_name("quick_panel");
        bluetooth = AstalBluetooth.get_default();
        notifd = AstalNotifd.get_default();
        network = AstalNetwork.get_default();

        // Update battery mode icon
        update_battery_icon();
    }

    // Network methods
    [GtkCallback]
    private void network_clicked() {
        if (network != null && network.wifi != null) {
            network.wifi.enabled = !network.wifi.enabled;
        }
    }

    [GtkCallback]
    private string network_icon(bool connected) {
        return connected ? "network-wireless-connected-100" : "network-wireless-disconnected";
    }

    [GtkCallback]
    private void network_clicked_extras() {
        this.visible = false;
        QuickSettings.get_instance().show_panel("network");
    }

    // Bluetooth methods
    [GtkCallback]
    private void bluetooth_clicked() {
        if (bluetooth != null && bluetooth.adapter != null) {
            bluetooth.adapter.powered = !bluetooth.adapter.powered;
        }
    }

    [GtkCallback]
    private void bluetooth_clicked_extras() {
        this.visible = false;
        QuickSettings.get_instance().show_panel("bluetooth");
    }

    [GtkCallback]
    private string bluetooth_icon_name(bool connected) {
        return connected ? "network-bluetooth" : "preferences-system-bluetooth-inactive-symbolic";
    }

    // VPN methods
    [GtkCallback]
    private string active_vpn(AstalNetwork.Network? network) {
        if (network == null || network.wifi == null || network.wifi.active_connection == null) {
            return "network-disconnect-symbolic";
        }
        return network.wifi.active_connection.vpn ? "curve-connector-symbolic" : "network-disconnect-symbolic";
    }

    [GtkCallback]
    private void toggle_vpn() {
        // TODO: Implement VPN toggle functionality
    }

    // Notifications methods
    [GtkCallback]
    private string dont_disturb_icon(bool dnd) {
        return dnd ? "notifications-disabled-symbolic" : "notifications-symbolic";
    }

    [GtkCallback]
    private void toggle_disturb() {
        if (notifd != null) {
            notifd.dont_disturb = !notifd.dont_disturb;
        }
    }

    [GtkCallback]
    private void on_notif_arrow_clicked() {
        // TODO: Implement notification arrow click functionality
    }

    // Crypto wallet methods
    [GtkCallback]
    private void cryptowallet_clicked() {
        this.visible = false;
        QuickSettings.get_instance().show_panel("crypto");
    }

    // Battery/Power mode methods
    private void update_battery_icon() {
        string stdout;
        string stderr;
        int status;
        
        Process.spawn_command_line_sync("powerprofilesctl get",
                                    out stdout,
                                    out stderr,
                                    out status);
        
        string current_mode = stdout.strip();
        switch (current_mode) {
            case "power-saver":
                battery_mode.icon = "food";
                break;

            case "balanced":
                battery_mode.icon = "dashboard-show";
                break;

            case "performance":
                battery_mode.icon = "exception";
                break;

            default:
                battery_mode.icon = "battery-missing-symbolic";
                break;
        }
    }

    [GtkCallback]
    private void switch_battery_mode() {
        try {
            string stdout;
            string stderr;
            int status;
            
            Process.spawn_command_line_sync("powerprofilesctl get",
                                        out stdout,
                                        out stderr,
                                        out status);
            
            string current_mode = stdout.strip();
            string next_mode;
            
            switch (current_mode) {
                case "power-saver":
                    next_mode = "balanced";
                    break;
                case "balanced":
                    next_mode = "performance";
                    break;
                case "performance":
                    next_mode = "power-saver";
                    break;
                default:
                    next_mode = "balanced";
                    break;
            }
            
            Process.spawn_command_line_sync("pkexec powerprofilesctl set " + next_mode);
            update_battery_icon();
            
        } catch (SpawnError e) {
            warning("Erreur : %s", e.message);
        }
    }
}