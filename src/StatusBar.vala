
using AstalHyprland;
using GtkLayerShell;

[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/StatusBar.ui")]
public class StatusBar : Gtk.Window, ILayerWindow {
// Properties
private AstalMpris.Mpris mpris { get; set; }
private AstalHyprland.Hyprland hyprland { get; set; }

private AstalBattery.Device battery;

private List<Gtk.Button> workspace_buttons = new List<Gtk.Button> ();

public AstalMpris.Player mpd { get; set; }
public AstalWp.Endpoint speaker { get; set; }

public string namespace { get; set; }

// UI Elements
[GtkChild]
public unowned Gtk.Box workspaces;

[GtkChild]
public unowned Gtk.Button apps_button;

[GtkChild]
public unowned Gtk.Box dynamic_box;

[GtkChild]
public unowned Gtk.Label clock;

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

public StatusBar (Gtk.Application app) {
	Object (application: app);
	initialize_components ();
	setup_event_handlers ();
}

// Initialization methods
private void initialize_components () {
	speaker = AstalWp.get_default ().audio.default_speaker;
	mpris = AstalMpris.Mpris.get_default ();
	hyprland = AstalHyprland.Hyprland.get_default ();

	battery = AstalBattery.Device.get_default ();

	init_layer_properties ();
	this.name = "StatusBar";
	this.namespace = "StatusBar";

	init_workspaces ();
	init_clock ();
	init_battery();
	init_island();

	GLib.Timeout.add(1000, () => {
		is_initialized = true;
		print("Initialized\n");
		return false;
	});
	
}

private void setup_event_handlers () {
	power_button.clicked.connect (() => {
			Geronimo.instance.toggle_window ("QuickSettings");
			QuickSettings.get_instance().show_panel ("quick");
		});

	apps_button.clicked.connect (() => {
			Geronimo.instance.toggle_window ("Runner");
		});

	//  hyprland.notify["focused-client"].connect (() => {
	//  		focused_client ();
	//  	});
}

[GtkCallback]
public string current_volume (double volume) {
	return @"$(Math.round(volume * 100))%";
}

// Layer Shell methods
public void init_layer_properties () {
	GtkLayerShell.init_for_window (this);
	GtkLayerShell.set_layer (this, GtkLayerShell.Layer.TOP);

	GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);
	GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);
	GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);

	GtkLayerShell.set_namespace (this, "StatusBar");
	GtkLayerShell.auto_exclusive_zone_enable (this);
}

public void present_layer () {
	this.present ();
}

// Battery methods

private void update_battery_icon(int displayed_percentage, bool charging) {
    string battery_icon_name;
    string css_class;

    if (displayed_percentage <= 25) {
        battery_icon_name = charging ? "battery-empty-charging" : "battery-empty-symbolic";
        css_class = "low";
    } else if (displayed_percentage < 50) {
        battery_icon_name = charging ? "battery-caution-charging" : "battery-caution-symbolic";
        css_class = "medium";
    } else if (displayed_percentage < 80) {
        battery_icon_name = charging ? "battery-good-charging" : "battery-good-symbolic";
        css_class = "good";
    } else {
        battery_icon_name = charging ? "battery-full-charging" : "battery-full-symbolic";
        css_class = "full";
    }

    battery_icon.icon_name = battery_icon_name;
    battery_icon.pixel_size = 30;

    battery_icon.remove_css_class("low");
    battery_icon.remove_css_class("medium");
    battery_icon.remove_css_class("good");
    battery_icon.remove_css_class("full");
    battery_icon.add_css_class(css_class);
}

private void update_battery() {
    var percentage = battery.percentage;
    int displayed_percentage = (int) (percentage * 100);
    bool charging = battery.charging;
    update_battery_icon(displayed_percentage, charging);
    battery_label.label = displayed_percentage.to_string() + "%";
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
	clock.label = clock_time.format ("%H:%M");
}

private void init_clock () {
	update_clock ();
	GLib.Timeout.add (30000, () => {
			if (using_clock) { update_clock (); }
			return true;
		});
}

// Dynamic island methods

private uint hide_timeout_id = 0;

private void init_island () {
	speaker.bind_property ("volume", vol_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
    // Connecte l'événement sans paramètres
	speaker.notify["volume"].connect(() => {
		if (is_initialized) {
        	clock.visible = false;
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
		clock.visible = true;
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
	setup_workspace_scroll ();
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

private void setup_workspace_scroll () {
	var scroll = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.VERTICAL);
	scroll.scroll.connect ((delta_x, delta_y) => {
			string direction = delta_y > 0 ? "e-1" : "e+1";
			hyprland.dispatch ("workspace", direction);
			return true;
		});
	workspaces.add_controller (scroll);
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

private bool workspace_has_windows (int workspace_number) {
	var window_count = hyprland.get_workspace (workspace_number).clients.length ();
	return window_count > 0;
}
}
