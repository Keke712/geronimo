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

// UI Elements

[GtkChild]
public unowned Gtk.Box left_box;

[GtkChild]
public unowned Gtk.Box workspaces;

[GtkChild]
public unowned Gtk.Button apps_button;

[GtkChild]
public unowned Gtk.Label battery_label;

[GtkChild]
public unowned Gtk.Button power_button;

[GtkChild]
public unowned Gtk.Image battery_icon;

// Workspace icon
private static string wicon = "󰝥 ";
private int max_workspace_id = 10;  // Set a maximum number of workspaces
public DynamicIsland dynamic_island { get; private set; }
public int statusbar_height;

public StatusBar () {
	Object (
		anchor: Astal.WindowAnchor.LEFT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT
	);
	
	switch_bar_mode();
    this.present();
    this.visible = true;  // Add this line to make the window visible
}

construct {
	mpris = AstalMpris.Mpris.get_default ();
	hyprland = AstalHyprland.Hyprland.get_default ();
	battery = new Battery("battery_BAT0");

	init_workspaces ();
	init_battery();
	

	GLib.Timeout.add(400, () => {
		statusbar_height = get_natural_height();
		init_island();
		return false;
	});

	setup_event_handlers();	
}

public int get_natural_height() {
    int minimum;
    int natural;
    int minimum_baseline;
    int natural_baseline;

    // Check if left_box is initialized
    if (left_box == null) {
        print("left_box is not initialized\n");
        return -1;
    }

    left_box.measure(Gtk.Orientation.VERTICAL, -1, out minimum, out natural, out minimum_baseline, out natural_baseline);

    return natural;
}

private void init_island() {
    // Code to initialize and display the dynamic island
	var margin_top = -statusbar_height;
    dynamic_island = new DynamicIsland(margin_top);
    dynamic_island.show();
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

// Threshold constants
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
