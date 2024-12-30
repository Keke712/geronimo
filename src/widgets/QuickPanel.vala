[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/widgets/QuickPanel.ui")]
public class QuickPanel : Gtk.Grid {
    // Properties
    public AstalNetwork.Network network { get; set; }
    public AstalBluetooth.Bluetooth bluetooth { get; set; }
    public AstalNotifd.Notifd notifd { get; private set; }

    [GtkChild]
    private unowned FlatButton battery_mode_button;

    private string battery_mode_icon;
    private string current_mode;

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
        current_mode = BatteryMode.get_powerprofile();
        battery_mode_icon = BatteryMode.get_battery_icon(current_mode);

        battery_mode_button.icon = battery_mode_icon;
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
        ControlPanel.get_instance().show_panel("network");
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
        ControlPanel.get_instance().show_panel("bluetooth");
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
        ControlPanel.get_instance().show_panel("crypto");
    }

    // Power Profiles -> Icon and methods

    [GtkCallback]
    private void call_switch() {
        string current_mode = BatteryMode.get_powerprofile();
        string next_mode = BatteryMode.get_next_mode(current_mode);
        BatteryMode.switch_mode(next_mode);
        battery_mode_button.icon = BatteryMode.get_battery_icon(next_mode);
    }

    [GtkCallback]
    private void on_battery_extras() {
        this.visible = false;
        ControlPanel.get_instance().show_panel("battery");
    }

}