[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/widgets/BatteryMode.ui")]
public class BatteryMode : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Button powersaver_button;
    
    [GtkChild]
    private unowned Gtk.Button balanced_button;
    
    [GtkChild]
    private unowned Gtk.Button performance_button;

    [GtkChild]
    private unowned Gtk.Label time_left;

    [GtkChild]
    private unowned Gtk.Label capacity_left;

    [GtkChild]
    private unowned Gtk.Label uptime_label;

    private Battery battery;
    private HeaderPanel header;

    public BatteryMode() {
        Object();
    }

    construct {
        set_css_name("battery_panel");

        // Battery module
        battery = new Battery("battery_BAT0");

        // Header panel
        header = new HeaderPanel();
        header.title = "Power Management";
        header.on_back_clicked.connect(() => {
            QuickSettings.get_instance().show_panel("quick");
        });
        header.refresh_button_visible = false;
        prepend(header);

        // Core
        setup_signals();
        update_labels(1000);

        // Start uptime timer
        uptime();

        // Setup the checked button
        var pwp = get_powerprofile();
        switch (pwp) {
            case "power-saver":
                powersaver_button.set_state_flags(Gtk.StateFlags.CHECKED, true);
                break;
                
            case "balanced":
                balanced_button.set_state_flags(Gtk.StateFlags.CHECKED, true);
                break;
                
            case "performance":
                performance_button.set_state_flags(Gtk.StateFlags.CHECKED, true);
                break;
                
            default:
                break;
                
        }
    }

    // UI COMPONENTS METHODS

    private void uptime() {
        update_uptime();
        GLib.Timeout.add(60000, () => {
            update_uptime();
            return true;
        });
    }

    private void update_uptime() {
        try {
            string stdout;
            Process.spawn_command_line_sync("uptime -p", out stdout);
            if (uptime_label != null) {
                uptime_label.label = stdout.strip();
            }
        } catch (Error e) {
            warning("Failed to get uptime: %s", e.message);
        }
    }

    private void setup_signals() {
        powersaver_button.clicked.connect(() => {
            update_button_states(powersaver_button);
            update_labels(4000);
            switch_mode("power-saver");
        });
        
        balanced_button.clicked.connect(() => {
            update_button_states(balanced_button);
            update_labels(4000);
            switch_mode("balanced");
        });
        
        performance_button.clicked.connect(() => {
            update_button_states(performance_button);
            update_labels(4000);
            switch_mode("performance");
        });
    }

    private void update_labels(int time) {
        GLib.Timeout.add(time, () => {
            print("Update labels\n");
            time_left.label = "Time left: "+get_time_left();
            string capa_str = get_capacity().to_string();
            capacity_left.label = "Battery health: "+capa_str+" %";
            return false;
        });
    }

    private void update_button_states(Gtk.Button clicked_button) {
        // Uncheck
        powersaver_button.set_state_flags(Gtk.StateFlags.NORMAL, true);
        balanced_button.set_state_flags(Gtk.StateFlags.NORMAL, true);
        performance_button.set_state_flags(Gtk.StateFlags.NORMAL, true);
        
        // Check
        clicked_button.set_state_flags(Gtk.StateFlags.CHECKED, true);
    }

    [GtkCallback]
    private string call_icon(string current_mode) {
        return BatteryMode.get_battery_icon(current_mode);
    }

    // Return methods

    private string get_time_left() {
        if (battery == null) {
            return "N/A";
        }
        
        return battery.time_to_empty;
    }

    private int get_capacity() {
        if (battery == null) {
            return 0;
        }
        
        int value = battery.capacity;
        return value;
    }

    public static string get_powerprofile() {
        string stdout;
        string stderr;
        int status;
        
        try {
            Process.spawn_command_line_sync("powerprofilesctl get",
                                    out stdout,
                                    out stderr,
                                    out status);
        } catch {
            return "pexec, no permission";
        }
        
        return stdout.strip();
    }

    public static string get_next_mode(string current_mode){
        switch (current_mode) {
            case "power-saver":
                return "balanced";
                
            case "balanced":
                return "performance";
                
            case "performance":
                return "power-saver";
                
            default:
                return "balanced";
                
        }
    }

    public static string get_battery_icon(string current_mode) {
        switch (current_mode) {
            case "power-saver":
                return "office-chart-pie-symbolic";

            case "balanced":
                return "draw-halfcircle2";

            case "performance":
                return "draw-circle";

            default:
                return "battery-missing-symbolic";
                
        }
    }

    // Switching methods
    public static void switch_mode(string mode) {
        try {
            Process.spawn_command_line_sync("pkexec powerprofilesctl set " + mode);
            print("Changed mode to %s\n", mode);
            
        } catch (SpawnError e) {
            warning("Erreur : %s\n", e.message);
        }
    }

    // impletements
    // battery -> life time
    // battery -> cycle and life span
    // good,  battery -> powerprofiles css bar - | - | -
}