using GtkLayerShell;

[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/Runner.ui")]
public class Runner : Astal.Window {

    public AstalApps.Apps apps { get; construct set; }

    [GtkChild]
    private unowned Gtk.ListBox app_list;

    [GtkChild]
    private unowned Gtk.Entry entry;

    private int sort_func(Gtk.ListBoxRow la, Gtk.ListBoxRow lb) {
        RunnerButton a = (RunnerButton)la;
        RunnerButton b = (RunnerButton)lb;
        // if score = -> frequency
        if (a.score == b.score) {
            return b.app.frequency - a.app.frequency;
        }
        // -> score
        return (a.score > b.score) ? -1 : 1;
    }

    private bool filter_func(Gtk.ListBoxRow row) {
        RunnerButton app = (RunnerButton)row;
        return app.score >= 0;
    }

    bool is_mathematical_expression(string text) {
        if (text.length == 0) return false;
        
        // check if the first char is a mathematical digit
        if (text[0].isdigit() || text[0] == '(') {
            string valid_chars = "0123456789+-*/^().";
            for (int i = 0; i < text.length; i++) {
                unichar c = text.get_char(i);
                if (!c.isspace() && !valid_chars.contains(c.to_string())) {
                    return false;
                }
            }
    
            return true;
        }
        return false;
    }

    public AstalApps.Application get_app(string app_name){
        AstalApps.Application? app_found = null; 
 
        this.apps.list.@foreach(app => {
            if (app.name == app_name) {
                app_found = app;
            }
        });
 
        return app_found;
    }

    public RunnerButton get_runnerbutton(string name) {
        int i = 0;
        RunnerButton output = null;
        RunnerButton? app = (RunnerButton)this.app_list.get_row_at_index(i);
        while (app != null) {
            if (app.app.name == name && app != calculator) {
                output = app;
            }
            app = (RunnerButton)this.app_list.get_row_at_index(++i);
        }
        if (output != null) {
            return output;
        }else{
            return null;
        }
    }

    string PREVIEW_TITLE = "Result";
    string CALCULATOR_NAME = "Calculatrice";
    string ERROR_INVALID = "Invalid Expression";
    string ERROR_CALC = "Calculation Error";
    private RunnerButton? calculator = null;
    private RunnerButton? calculator_app = null;

    [GtkCallback]
    public void update_list() {
        string text = this.entry.text.strip();
        calculator_app = get_runnerbutton(CALCULATOR_NAME);

        // Calculator mode
        if (is_mathematical_expression(text)) {
            AstalApps.Application? calc_app = get_app(CALCULATOR_NAME);
            if (calc_app == null) return;

            // Create the first widget if it's null
            if (calculator == null) {
                calculator = new RunnerButton(calc_app);
                calculator.score = 100;
                calculator.set_title(PREVIEW_TITLE);
                this.app_list.insert(calculator, 0);
            }
            
            // Update the widget
            try {
                calculator.set_description("%.2f".printf(Calculator.evaluate(text)));
            } catch (CalculatorError.INVALID_EXPRESSION e) {
                calculator.set_description(ERROR_INVALID);
            } catch (CalculatorError e) {
                calculator.set_description(ERROR_CALC);
            }

            // Make invisible the second calculator application
            calculator_app.visible = false;

            return;
        }

        // Normal mode
        if (calculator != null) {
            this.app_list.remove(calculator);
            calculator = null;
            calculator_app.visible = true;
        }

        // Score update
        int i = 0;
        RunnerButton? app = (RunnerButton)this.app_list.get_row_at_index(i);
        while (app != null) {
            if (app != calculator) {
                app.score = (int)(app.app.fuzzy_match(text).name * 100);
            }
            app = (RunnerButton)this.app_list.get_row_at_index(++i);
        }

        this.app_list.invalidate_sort();
        this.app_list.invalidate_filter();
    }

    [GtkCallback]
    public void launch_first_runner_button() {
        RunnerButton? selectedButton = (RunnerButton)this.app_list.get_row_at_index(0);
        if (selectedButton != null) {
            selectedButton.activate();
            this.visible = false;
        }
    }

    [GtkCallback]
    public void key_released(uint keyval) {
        if (keyval == Gdk.Key.Escape) {
            this.visible = false;
        }
    }

    public Runner() {
        Object (
            anchor: Astal.WindowAnchor.TOP,
            margin_top: 20
        );
    }

    construct {
        // make window editable
        GtkLayerShell.init_for_window(this);
        GtkLayerShell.set_keyboard_mode(this, GtkLayerShell.KeyboardMode.EXCLUSIVE);

        this.apps = new AstalApps.Apps();

        this.app_list.set_sort_func(sort_func);
        this.app_list.set_filter_func(filter_func);

        this.apps.list.@foreach(app => {
            this.app_list.append(new RunnerButton(app));
        });

        this.notify["visible"].connect(() => {
            if (!this.visible) {
                this.entry.text = "";
            } else {
                this.entry.grab_focus();
            }
        });
    }
}