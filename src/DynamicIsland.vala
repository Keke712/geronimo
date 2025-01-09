using GtkLayerShell;
using Gtk;

// Core panel dimensions
private const int PANEL_DEFAULT_WIDTH = 250;
private const int PANEL_EXPANDED_WIDTH = 300;
private const int PANEL_MIN_HEIGHT = 35;
private const int PANEL_MAX_HEIGHT = 150;
private const int PANEL_DELAY_SHOW = 400;
private const int PANEL_DELAY_HIDE = 800;
private const int DAYS_INTERVAL = 3;  // Number of days shown in calendar view

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

    [GtkChild]
    private unowned Gtk.Box days_box;
    
    [GtkChild]
    private unowned Gtk.Button prev_button;
    
    [GtkChild]
    private unowned Gtk.Button next_button;
    
    [GtkChild]
    private unowned Gtk.Label month_label;

    private int visible_start = 0;
    
    private Gtk.Button[] day_buttons;
    private int current_day;

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
        init_days();
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
        calendar_box.visible = true;
        dynamic_box.add_css_class("expanded");
        
        GLib.Timeout.add(50, () => {  // Short delay to let the transition start
            calendar_box.add_css_class("visible");
            return false;
        });
    }

    public void hide_panel() {
        calendar_box.visible = false;  // Changed to be immediate
        dynamic_box.remove_css_class("expanded");
        set_size_request(PANEL_DEFAULT_WIDTH, PANEL_MIN_HEIGHT);
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

    private void handle_hover_state() {  // Renamed from do_action
        if (hover_timeout_id != 0) {
            GLib.Source.remove(hover_timeout_id);
            hover_timeout_id = 0;
        }

        if (!is_mouse_over_dynamic) {
            hide_panel();  // Removed timeout, immediate close
        } else {
            show_panel();
        }
    }

    private void init_hover() {
        var hover_controller = new Gtk.EventControllerMotion();
        hover_controller.enter.connect(() => {
            is_mouse_over_dynamic = true;
            handle_hover_state();  // Updated call
        });
        hover_controller.leave.connect(() => {
            is_mouse_over_dynamic = false;
            handle_hover_state();  // Updated call
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

    private DateTime current_date_obj;
    private int days_offset = 0;
    
    private void init_days() {
        if (days_box == null) return;

        current_date_obj = new DateTime.now_local();
        update_calendar_view();
        
        prev_button.clicked.connect(() => {
            days_offset -= 1;  // Navigate day by day
            current_date_obj = current_date_obj.add_days(-1);
            update_calendar_view();
        });
        
        next_button.clicked.connect(() => {
            days_offset += 1;
            current_date_obj = current_date_obj.add_days(1);
            update_calendar_view();
        });
    }
    
    private void update_calendar_view() {
        // Update current date and month
        month_label.label = current_date_obj.format("%B %Y");
        
        // Clean up old buttons
        Gtk.Widget? child = days_box.get_first_child();
        while (child != null) {
            var next_child = child.get_next_sibling();
            days_box.remove(child);
            child = next_child;
        }
        
        // Create buttons for 3 days (previous, current, next)
        day_buttons = new Gtk.Button[DAYS_INTERVAL];
        
        for (int i = -1; i <= 1; i++) {
            var date = current_date_obj.add_days(i);
            var button = new Gtk.Button.with_label(date.format("%d"));
            button.visible = true;
            button.add_css_class("day-button");
            
            if (i == 0) {
                button.add_css_class("current");
            }
            
            days_box.append(button);
            day_buttons[i + 1] = button;
        }
        
        // Enable/disable navigation buttons
        prev_button.sensitive = true;
        next_button.sensitive = days_offset < 30;  // Limit to one month ahead
    }
}