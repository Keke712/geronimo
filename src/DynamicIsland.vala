using GtkLayerShell;
using Gtk;

[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/DynamicIsland.ui")]
public class DynamicIsland : Astal.Window {

    public AstalWp.Endpoint speaker { get; set; }
    private bool is_initialized = false;

    [GtkChild]
    public unowned Gtk.Box calendar_box;

    [GtkChild]
    public unowned Gtk.Box dynamic_box;
    
    [GtkChild]
    public unowned Gtk.Button clock_button;
    
    [GtkChild]
    public unowned Gtk.Box volume_osd;
    
    [GtkChild]
    public unowned Gtk.Adjustment vol_adjust;
    
    [GtkChild]
    public unowned Gtk.Box backlight_osd;
    
    [GtkChild]
    public unowned Gtk.Adjustment back_adjust;

    private static DynamicIsland? instance;
    private int initial_width;
    private int initial_height;

    public DynamicIsland(int margin_int) {
        Object (
            anchor: Astal.WindowAnchor.TOP,
            margin_top: margin_int
        );
        this.visible = true;
    }

    construct {
        speaker = AstalWp.get_default ().audio.default_speaker;
        init_clock ();
        
        calendar_box.visible = false;
        
        // Wait for the window to be fully loaded
        this.map.connect (() => {
            if (!is_initialized) {
                initial_height = get_natural(Gtk.Orientation.VERTICAL);
                initial_width = get_natural(Gtk.Orientation.HORIZONTAL);
                set_default_size(initial_width, initial_height);
                is_initialized = true;
            }
        });
        
        speaker.bind_property ("volume", vol_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
        // Connect the event without parameters
        speaker.notify["volume"].connect(() => {
            if (is_initialized) {
                clock_button.visible = false;
                volume_osd.visible = true;
                handle_timeout();
            }
        });

        init_hover();
    }

    public static DynamicIsland get_instance() {
        return instance;
    }

    public int get_natural(Gtk.Orientation orientation) {
        int minimum; int natural; int minimum_baseline; int natural_baseline;
    
        // Check if dynamic_box is initialized
        if (dynamic_box == null) {
            print("dynamic_box is not initialized\n");
            return -1;
        }
        
        dynamic_box.measure(orientation, -1, out minimum, out natural, out minimum_baseline, out natural_baseline);
    
        return natural;
    }

    public void show_panel() {
        set_size_request(-1, -1); // Allow natural resizing
        calendar_box.visible = true;
    }

    public void hide_panel() {
        calendar_box.visible = false;
        reset_size();
    }

    private void reset_size() {
        if (initial_width > 0 && initial_height > 0) {
            set_size_request(initial_width, initial_height);
            queue_resize();
        }
    }

    // Clock methods
    private bool using_clock = true;

    private void update_clock () {
        var clock_time = new DateTime.now_local ();
        clock_button.label = clock_time.format ("%H:%M");
    }

    private void init_clock () {
        update_clock ();
        GLib.Timeout.add (30000, () => {
                if (using_clock) { update_clock (); }
                return true;
            });
    }

    private bool is_mouse_over_dynamic;

    private uint hover_timeout_id = 0;
    private void do_action() {
        if (hover_timeout_id != 0) {
            GLib.Source.remove(hover_timeout_id);
            hover_timeout_id = 0;
        }

        if (!is_mouse_over_dynamic) {
            hover_timeout_id = GLib.Timeout.add(300, () => {
                if (!is_mouse_over_dynamic) {
                    hide_panel();
                }
                hover_timeout_id = 0;
                return false;
            });
        } else {
            show_panel();
        }
    }

    private void init_hover() {
        var hover_controller = new Gtk.EventControllerMotion();
        hover_controller.enter.connect(() => {
            is_mouse_over_dynamic = true;
            do_action();
        });
        hover_controller.leave.connect(() => {
            is_mouse_over_dynamic = false;
            do_action();
        });
        dynamic_box.add_controller(hover_controller);
    }

    // Dynamic island methods

    private uint hide_timeout_id = 0;

    private void handle_timeout() {
        // Remove the existing timeout if it exists
        if (hide_timeout_id != 0) {
            GLib.Source.remove(hide_timeout_id);
            hide_timeout_id = 0;
        }
        
        // Set a new timeout
        hide_timeout_id = GLib.Timeout.add(3000, () => {
            // Set a new timeout to hide the volume
            clock_button.visible = true;
            volume_osd.visible = false;
            

            hide_timeout_id = 0;
            return false;
        });
    }
}