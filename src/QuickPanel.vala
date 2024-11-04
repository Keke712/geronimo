[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/QuickPanel.ui")]
public class QuickPanel : Gtk.Grid {

    public AstalNetwork.Network network { get; set; }
    public AstalBluetooth.Bluetooth bluetooth { get; set; }
    public AstalNotifd.Notifd notifd {get; private set;}

    public QuickPanel() {
        Object ();
    }

    construct {
        set_css_name("quick_panel");
        bluetooth = AstalBluetooth.get_default ();
        notifd = AstalNotifd.get_default ();
        network = AstalNetwork.get_default ();
    }

    [GtkCallback]
    public void network_clicked() {
        if (network != null && network.wifi != null) {
            network.wifi.enabled = !network.wifi.enabled;
        }
    }

    [GtkCallback]
    public string network_icon(bool connected) {
        return connected ? "network-wireless-connected-100" : "network-wireless-disconnected";
    }

    [GtkCallback]
    public void network_clicked_extras() {
        this.visible = false;
        // On chope l'instance et on balance la méthode
        QuickSettings.get_instance().show_panel("network");
    }

    [GtkCallback]
    public void bluetooth_clicked() {
        if (bluetooth != null && bluetooth.adapter != null) {
            bluetooth.adapter.powered = !bluetooth.adapter.powered;
        }
    }

    [GtkCallback]
    public void bluetooth_clicked_extras() {
        this.visible = false;
        // On chope l'instance et on balance la méthode
        QuickSettings.get_instance().show_panel("bluetooth");
    }

    [GtkCallback]
    public string bluetooth_icon_name(bool connected) {
        return connected
            ? "network-bluetooth"
            : "preferences-system-bluetooth-inactive-symbolic";
    }

    [GtkCallback]
    public string active_vpn(AstalNetwork.Network? network) {
        if (network == null || network.wifi == null || network.wifi.active_connection == null) {
            return "network-disconnect-symbolic";
        }
        return network.wifi.active_connection.vpn ? "curve-connector-symbolic" : "network-disconnect-symbolic";
    }

    [GtkCallback]
    public void toggle_vpn() {
        // TODO: Implement VPN toggle functionality
    }

    [GtkCallback]
    public string dont_disturb_icon(bool dnd) {
        return dnd
            ? "notifications-disabled-symbolic"
            : "notifications-symbolic";
    }

    [GtkCallback]
    public void toggle_disturb() {
        if (notifd != null) {
            notifd.dont_disturb = !notifd.dont_disturb;
        }
    }

    [GtkCallback]
    public void on_notif_arrow_clicked() {
        // TODO: Implement notification arrow click functionality
    }
}