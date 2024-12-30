using AstalHyprland;
using GtkLayerShell;

[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/StatusBar.ui")]
public class StatusBar : Astal.Window {

// Interface
private static StatusBar? instance;

public static StatusBar get_instance() {
	return instance;
}

// Properties
private AstalMpris.Mpris mpris { get; set; }
private AstalHyprland.Hyprland hyprland { get; set; }

private Battery battery;

private List<Gtk.Button> workspace_buttons = new List<Gtk.Button> ();

public AstalMpris.Player mpd { get; set; }
public AstalWp.Endpoint speaker { get; set; }

// UI Elements
[GtkChild]
public unowned Gtk.Box workspaces;

[GtkChild]
public unowned Gtk.Button apps_button;

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
public unowned Gtk.Label battery_label;

[GtkChild]
public unowned Gtk.Button power_button;

[GtkChild]
public unowned Gtk.Image battery_icon;

// Workspace icon
private static string wicon = "󰝥 ";
private int max_workspace_id = 10;  // Set a maximum number of workspaces
private bool is_initialized = false;

public StatusBar () {
	Object (
		anchor: Astal.WindowAnchor.LEFT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT
	);
	
	switch_bar_mode();
    present();
}

construct {
	speaker = AstalWp.get_default ().audio.default_speaker;
	mpris = AstalMpris.Mpris.get_default ();
	hyprland = AstalHyprland.Hyprland.get_default ();
	battery = new Battery("battery_BAT0");

	init_workspaces ();
	init_clock ();
	init_battery();
	init_island();
	hover_clock();

	setup_event_handlers();

    // Remove the clock_button click callback
    // clock_button.clicked.connect(() => {
    //     var center_panel = new CenterPanel();
    //     center_panel.present();
    // });

	GLib.Timeout.add(1000, () => {
		is_initialized = true;
		return false;
	});
}

public void switch_bar_mode() {
	if (!auto_exclusive_zone_is_enabled(this)) {
		auto_exclusive_zone_enable(this);
	} else {
		auto_exclusive_zone_enable(this);
	}
}

private void setup_event_handlers () {
	power_button.clicked.connect (() => {
		Geronimo.open_window("ControlPanel");
		ControlPanel.get_instance().show_panel ("quick");
	});

	apps_button.clicked.connect (() => {
			Geronimo.open_window("Runner");
		});
}

// Battery methods

// Treshold constants
private const int BATTERY_LOW_THRESHOLD = 20;
private const int BATTERY_CAUTION_THRESHOLD = 40;
private const int BATTERY_GOOD_THRESHOLD = 70;

// Icon constants
private const string ICON_BATTERY_EMPTY = "battery-empty-symbolic";
private const string ICON_BATTERY_CAUTION = "battery-caution-symbolic";
private const string ICON_BATTERY_GOOD = "battery-good-symbolic";
private const string ICON_BATTERY_FULL = "battery-full-symbolic";
private const string ICON_BATTERY_CHARGING = "exception-symbolic";

enum BatteryState { CHARGING, EMPTY, CAUTION, GOOD, FULL }

// CSS Constants
private const string CSS_CLASS_CHARGING = "charging";
private const string CSS_CLASS_LOW = "low";

// ICON Size Constant
private const int ICON_SIZE = 30;
private const int ICON_CHARGING_SIZE = 20;

// Track charging state
private bool previous_charging_state = false;

private void update_battery_icon(int displayed_percentage, bool charging) {    
    // Determine battery state
    BatteryState battery_state;
    if (charging) {
        battery_state = BatteryState.CHARGING;
    } else if (displayed_percentage <= BATTERY_LOW_THRESHOLD) {
        battery_state = BatteryState.EMPTY;
    } else if (displayed_percentage < BATTERY_CAUTION_THRESHOLD) {
        battery_state = BatteryState.CAUTION;
    } else if (displayed_percentage < BATTERY_GOOD_THRESHOLD) {
        battery_state = BatteryState.GOOD;
    } else {
        battery_state = BatteryState.FULL;
    }
    
    // Switch on the battery state
    switch (battery_state) {
        case BatteryState.CHARGING:
            icon_name = ICON_BATTERY_CHARGING;
            battery_icon.add_css_class(CSS_CLASS_CHARGING);
            battery_icon.pixel_size = ICON_CHARGING_SIZE;
            break;
            
        case BatteryState.EMPTY:
            icon_name = ICON_BATTERY_EMPTY;
            battery_icon.add_css_class(CSS_CLASS_LOW);
            battery_icon.pixel_size = ICON_SIZE;
            break;
            
        case BatteryState.CAUTION:
            icon_name = ICON_BATTERY_CAUTION;
            battery_icon.pixel_size = ICON_SIZE;
            break;
            
        case BatteryState.GOOD:
            icon_name = ICON_BATTERY_GOOD;
            battery_icon.pixel_size = ICON_SIZE;
            break;
            
        case BatteryState.FULL:
            icon_name = ICON_BATTERY_FULL;
            battery_icon.pixel_size = ICON_SIZE;
            break;
    }
    
    // Remove previous CSS Classes
    if (!charging && previous_charging_state) {
        battery_icon.remove_css_class(CSS_CLASS_CHARGING);
        battery_icon.queue_draw();
    } else if (battery_state != BatteryState.EMPTY && battery_icon.has_css_class(CSS_CLASS_LOW)) {
        battery_icon.remove_css_class(CSS_CLASS_LOW);
        battery_icon.queue_draw();
    }
    
    battery_icon.icon_name = icon_name;
    
    previous_charging_state = charging;
}

private void update_battery() {
	battery.update_info();
    var percentage = battery.percentage;
	bool charging;
	if (battery.state == "charging") {
		charging = true;
	} else {
		charging = false;
	}
    
    update_battery_icon(percentage, charging);
    battery_label.label = percentage.to_string() + "%";
}

private void init_battery () {
	update_battery ();
	GLib.Timeout.add (30000, () => {
			update_battery ();
			return true;
		});
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

private DynamicIsland center_panel = DynamicIsland.get_instance();
private bool is_mouse_over_calendar;
private bool is_mouse_over_clock;

private void expand_dynamic() {
	GLib.Timeout.add (10, () => {
		int cp_width = center_panel.get_allocated_width();
		dynamic_box.set_size_request(cp_width, -1); // Set width based on center_panel
		dynamic_box.queue_draw();
		
		return false;
	});
}

private void collapse_dynamic() {
	dynamic_box.set_size_request(-1, -1); // Reset to default width
	dynamic_box.queue_draw();
}

private void do_action() {
	if (!is_mouse_over_clock && !is_mouse_over_calendar) {
		GLib.Timeout.add (50, () => {
			if (!is_mouse_over_clock && !is_mouse_over_calendar){
				dynamic_box.remove_css_class("expanded");
				collapse_dynamic();
				center_panel.hide_panel();
			}
			
			return false;
		});
	}else{
		dynamic_box.add_css_class("expanded");
		expand_dynamic();
		center_panel.show_panel();
	}
}

private void hover_clock () {

    // HOVER CALENDAR
    var hover_controller_calendar = new Gtk.EventControllerMotion();
    hover_controller_calendar.enter.connect(() => {
        is_mouse_over_calendar = true;
		do_action();
    });
    hover_controller_calendar.leave.connect(() => {
		is_mouse_over_calendar = false;
		do_action();
    });
    center_panel.dynamicisland_box.add_controller(hover_controller_calendar);

	// HOVER CLOCK
    var hover_controller_button = new Gtk.EventControllerMotion();
    hover_controller_button.enter.connect(() => {
		is_mouse_over_clock = true;
		do_action();
		expand_dynamic();  // Ensure dynamic island expands immediately
    });
    hover_controller_button.leave.connect(() => {
		is_mouse_over_clock = false;
		do_action();
    });
    clock_button.add_controller(hover_controller_button);
}

// Dynamic island methods

private uint hide_timeout_id = 0;

private void init_island () {
	speaker.bind_property ("volume", vol_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
    // Connecte l'événement sans paramètres
	speaker.notify["volume"].connect(() => {
		if (is_initialized) {
        	clock_button.visible = false;
			volume_osd.visible = true;
			handle_timeout();
		}
    });
}

private void handle_timeout() {
	// Remove the existing timeout if it exists
	if (hide_timeout_id != 0) {
		GLib.Source.remove(hide_timeout_id);
		hide_timeout_id = 0;
	}
	
	// Set a new timeout
	hide_timeout_id = GLib.Timeout.add(3000, () => {
        // Définition d'un nouveau timeout pour masquer le volume
		clock_button.visible = true;
        volume_osd.visible = false;
		

		hide_timeout_id = 0;
		return false;
	});
}

// Workspace methods

private static int focused_workspace_id { get; private set; }

private void init_workspaces () {
	update_workspace_buttons();
	setup_workspace_event_handlers ();
}

private void update_workspace_buttons() {
	// Remove existing buttons
	foreach (var button in workspace_buttons) {
		workspaces.remove(button);
	}
	workspace_buttons = new List<Gtk.Button>();

	// Create buttons for all workspaces up to max_workspace_id
	for (var i = 1; i <= max_workspace_id; i++) {
		var workspace_button = new Gtk.Button.with_label (wicon);
		connect_button_to_workspace (workspace_button, i);
		workspace_button.valign = Gtk.Align.CENTER;
		workspace_button.halign = Gtk.Align.CENTER;
		workspaces.append (workspace_button);
		workspace_buttons.append (workspace_button);
	}
	update_workspaces();
}

private void setup_workspace_event_handlers () {
	hyprland.notify["focused-workspace"].connect (update_workspaces);
	hyprland.client_added.connect (() => {
		update_workspace_buttons();
		update_workspaces();
	});
	hyprland.client_removed.connect (() => {
		update_workspace_buttons();
		update_workspaces();
	});
	hyprland.client_moved.connect (update_workspaces);
}

private void update_workspaces () {
	focused_workspace_id = hyprland.focused_workspace != null ? hyprland.focused_workspace.id : 1;

	int index = 0;
	workspace_buttons.foreach ((button) => {
		if (button != null) {
			int workspace_number = index + 1;
			if (workspace_number == focused_workspace_id) {
				button.set_css_classes (new string[] { "focused" });
			} else if (workspace_exists(workspace_number)) {
				button.set_css_classes (new string[] { "occupied" });
			} else {
				button.set_css_classes (new string[] { "empty" });
			}
			button.visible = workspace_number <= get_highest_workspace_id();
		}
		index++;
	});
}

private bool workspace_exists(int workspace_number) {
	var workspace = hyprland.get_workspace(workspace_number);
	return workspace != null && workspace.clients != null && workspace.clients.length() > 0;
}

private int get_highest_workspace_id() {
	int highest_id = 1;
	foreach (var workspace in hyprland.workspaces) {
		if (workspace != null && workspace.id > highest_id) {
			highest_id = workspace.id;
		}
	}
	return int.max(highest_id, focused_workspace_id);
}


private void connect_button_to_workspace (Gtk.Button button, int workspace_number) {
	var middle_click = new Gtk.GestureClick ();
	middle_click.set_button (2);
	middle_click.pressed.connect (() => {
			hyprland.dispatch ("movetoworkspacesilent", workspace_number.to_string ());
		});
	button.add_controller (middle_click);
	button.clicked.connect (() => {
			hyprland.dispatch ("workspace", workspace_number.to_string ());
		});
}

}
