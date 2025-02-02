using GtkLayerShell;

[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/ControlPanel.ui")]
public class ControlPanel : Astal.Window {
    // créer une instance statique de la classe ControlPanel
    private static ControlPanel? instance;

    public AstalWp.Endpoint speaker { get; set; }
    public AstalMpris.Mpris mpris {get; private set;}

    public const int n_grid_buttons = 10;

    [GtkChild]
    private unowned Gtk.Grid control_panel_grid;

    [GtkChild]
    private unowned Gtk.Adjustment vol_adjust;
    
    [GtkChild]
    private unowned Gtk.Adjustment backlight_adjust;

    [GtkChild]
    private unowned Gtk.Label backlight_label;
    
    [GtkChild]
    private unowned Adw.Carousel players;

    public ControlPanel () {
        Object (
            anchor: Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT,
            margin_top: 10,
            margin_right: 10
        );

        // On stock l'instance dès la création
        instance = this;
    }

    // Method pour chopper l'instance depuis n'importe où
    public static ControlPanel get_instance() {
        return instance;
    }

    construct {
        // Initialize services
        speaker = AstalWp.get_default ().audio.default_speaker;
        mpris = AstalMpris.get_default ();

        // Bind properties
        if (speaker != null) {
            speaker.bind_property ("volume", vol_adjust, "value", 
                GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
        }

        // Initialize backlight
        init_backlight();

        backlight_adjust.value_changed.connect(() => {
            set_backlight(backlight_adjust.value);
        });

        // Initialize the panel
        show_panel("quick");

        // Initialize MPRIS
        if (mpris != null) {
            mpris.players.@foreach ((p) => on_player_added (p));
            mpris.player_added.connect (on_player_added);
            mpris.player_closed.connect (on_player_removed);
        }

        
    }

    private const string BACKLIGHT_PATH = "/sys/class/backlight/intel_backlight";
    private const string BRIGHTNESS_HELPER = "/usr/bin/brightness-helper";
    private int max_brightness;
    private double brightness_pct;
    private bool backlight_initialized = false;

    private void init_backlight() {
        try {
            string max_brightness_str;
            if (FileUtils.get_contents(BACKLIGHT_PATH + "/max_brightness", out max_brightness_str)) {
                max_brightness = int.parse(max_brightness_str.strip());
                backlight_initialized = true;
                
                if (max_brightness <= 0) {
                    return;
                }
                
                string current_brightness_str;
                if (FileUtils.get_contents(BACKLIGHT_PATH + "/brightness", out current_brightness_str)) {
                    int current_brightness = int.parse(current_brightness_str.strip());
                    
                    if (backlight_adjust != null && backlight_adjust is Gtk.Adjustment) {
                        backlight_adjust.value = (double) current_brightness / max_brightness;
                    }
                }
            }
        } catch (Error e) {
            print("Failed to initialize backlight: %s\n", e.message);
        }
    }

    public string get_backlight() {
        try {
            string brightness_str;
            if (FileUtils.get_contents(BACKLIGHT_PATH + "/brightness", out brightness_str)) {
                
                int brightness = int.parse(brightness_str.strip());

                if (max_brightness > 0) {
                    brightness_pct = (double)brightness / max_brightness;
                    var result = "%.0f%%".printf(brightness_pct * 100);
                    return result;
                }
            }
            return "N/A";
        } catch (Error e) {
            return "N/A";
        }
    }

    [GtkCallback]
    public string update_backlight() {
        if (backlight_initialized) {
            return get_backlight();
        } else {
            init_backlight();
            return get_backlight();
        }
    }

    private void set_backlight(double value) {
        if (max_brightness <= 0) return;
        
        try {
            double percentage = value * 100;
            double rounded = Math.round(percentage / 5) * 5;
            int new_brightness = (int)((rounded / 100) * max_brightness);
            
            if (new_brightness < 0) new_brightness = 0;
            if (new_brightness > max_brightness) new_brightness = max_brightness;
            
            // Utiliser pkexec pour exécuter le helper script
            string[] spawn_args = {"pkexec", BRIGHTNESS_HELPER, new_brightness.to_string()};
            string[] spawn_env = Environ.get();
            
            Process.spawn_sync(null,
                spawn_args,
                spawn_env,
                SpawnFlags.SEARCH_PATH,
                null,
                null,
                null,
                null);

            // Mettre à jour le label
            backlight_label.label = "%.0f%%".printf(rounded);
    
        } catch (Error e) {
            warning("Failed to set brightness: %s", e.message);
        }
    }

    [GtkCallback]
    public string current_volume(double volume) {
        return "%.0f%%".printf(volume * 100);
    }

    private void clear_panel() {
        var child = control_panel_grid.get_first_child();
        while (child != null) {
            control_panel_grid.remove(child);
            child = control_panel_grid.get_first_child();
        }
    }

    private void setup_quick_panel() {
        QuickPanel quick_panel = new QuickPanel();
        control_panel_grid.attach(quick_panel, 0, 0, 1, 1);
    }

    private void setup_network_panel() {
        NetworkPanel network_panel = new NetworkPanel();
        control_panel_grid.attach(network_panel, 0, 0, 1, 1);
    }

    private void setup_bluetooth_panel() {
        BluetoothPanel bluetooth_panel = new BluetoothPanel();
        control_panel_grid.attach(bluetooth_panel, 0, 0, 1, 1);
    }

    private void setup_crypto_panel() {
        CryptoWallet crypto_wallet = new CryptoWallet();
        control_panel_grid.attach(crypto_wallet, 0, 0, 1, 1);
    }

    private void setup_battery_panel() {
        BatteryMode battery_mode = new BatteryMode();
        control_panel_grid.attach(battery_mode, 0, 0, 1, 1);
    }

    public void show_panel(string panel) {
        clear_panel();

        if ( panel == "quick" ) {
            setup_quick_panel();
        } else if ( panel == "network" ) {
            setup_network_panel();
        } else if ( panel == "bluetooth" ) {
            setup_bluetooth_panel();
        } else if ( panel == "crypto") {
            setup_crypto_panel();
        } else if ( panel == "battery") {
            setup_battery_panel();
        }
    }

    private void on_player_added(AstalMpris.Player player) {
        var mpris_widget = new Mpris(player);
        if (players != null) {
            players.append(mpris_widget);

            player.notify["playback-status"].connect(() => {
                reorder_players();
            });

            reorder_players();
        }
    }

    private void on_player_removed(AstalMpris.Player player) {
        if (players != null) {
            for (int i = 0; i < players.n_pages; i++) {
                Mpris p = (Mpris)players.get_nth_page(i);
                if (p.player == player) {
                    players.remove(p);
                    break;
                }
            }
        }
    }

    private void reorder_players() {
        if (players == null) return;

        Mpris? playing_widget = null;
        int playing_index = -1;

        for (int i = 0; i < players.n_pages; i++) {
            Mpris mpris_widget = (Mpris)players.get_nth_page(i);
            if (mpris_widget.player.playback_status == AstalMpris.PlaybackStatus.PLAYING) {
                playing_widget = mpris_widget;
                playing_index = i;
                break;
            }
        }

        if (playing_widget != null && playing_index > 0) {
            players.remove(playing_widget);
            players.insert(playing_widget, 0);
            players.scroll_to(playing_widget, true);
        }
    }

    [GtkCallback]
    public void shutdown() {
        try {
            Process.spawn_command_line_async("systemctl poweroff");
        } catch (Error e) {
            warning("Failed to shutdown: %s", e.message);
        }
    }

    [GtkCallback]
    public void reboot() {
        try {
            Process.spawn_command_line_async("systemctl reboot");
        } catch (Error e) {
            warning("Failed to reboot: %s", e.message);
        }
    }

    [GtkCallback]
    public void suspend() {
        try {
            Process.spawn_command_line_async("systemctl suspend");
        } catch (Error e) {
            warning("Failed to suspend: %s", e.message);
        }
    }

    [GtkCallback]
    public void hibernate() {
        try {
            Process.spawn_command_line_async("systemctl hibernate");
        } catch (Error e) {
            warning("Failed to hibernate: %s", e.message);
        }
    }

    [GtkCallback]
    public void lock() {
        try {
            Process.spawn_command_line_async("swaylock");
        } catch (Error e) {
            warning("Failed to lock: %s", e.message);
        }
    }

    public void init_layer_properties() {
        GtkLayerShell.init_for_window(this);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.TOP);
        GtkLayerShell.set_namespace(this, "ControlPanel");

        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.RIGHT, true);

        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.TOP, 5);
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.RIGHT, 5);
    }

    public void present_layer() {
        this.present();
        this.visible = false;
    }
}