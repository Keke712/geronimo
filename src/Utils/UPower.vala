public class Battery : Object {
    public string device { get; set; }
    public string native_path { get; set; }
    public string vendor { get; set; }
    public string model { get; set; }
    public string serial { get; set; }
    public bool power_supply { get; set; }
    public string state { get; set; }
    public double energy { get; set; }
    public double energy_full { get; set; }
    public double energy_rate { get; set; }
    public double voltage { get; set; }
    public int charge_cycles { get; set; }
    public string time_to_empty { get; set; }
    public int percentage { get; set; }
    public double temperature { get; set; }
    public int capacity { get; set; }
    public string technology { get; set; }

    public Battery(string device_path) {
        this.device = device_path;
        this.update_info();
    }

    public void update_info() {
        string info = UPower.get_info(this.device);
        parse_info(info);
    }

    private void parse_info(string info) {
        string[] lines = info.split("\n");
        foreach (string line in lines) {
            string[] parts = line.strip().split(":");
            if (parts.length < 2) continue;

            string key = parts[0].strip();
            string value = parts[1].strip();

            switch (key) {
                case "native-path":
                    this.native_path = value;
                    break;
                case "vendor":
                    this.vendor = value;
                    break;
                case "model":
                    this.model = value;
                    break;
                case "serial":
                    this.serial = value;
                    break;
                case "power supply":
                    this.power_supply = value == "yes";
                    break;
                case "state":
                    this.state = value;
                    break;
                case "energy":
                    this.energy = double.parse(value.split(" ")[0].replace(",", "."));
                    break;
                case "energy-full":
                    this.energy_full = double.parse(value.split(" ")[0].replace(",", "."));
                    break;
                case "energy-rate":
                    this.energy_rate = double.parse(value.split(" ")[0].replace(",", "."));
                    break;
                case "voltage":
                    this.voltage = double.parse(value.split(" ")[0].replace(",", "."));
                    break;
                case "charge-cycles":
                    this.charge_cycles = int.parse(value);
                    break;
                case "time to empty":
                    this.time_to_empty = value;
                    break;
                case "percentage":
                    this.percentage = int.parse(value.replace("%", ""));
                    break;
                case "temperature":
                    this.temperature = double.parse(value.split(" ")[0].replace(",", "."));
                    break;
                case "capacity":
                    this.capacity = int.parse(value.replace("%", ""));
                    break;
                case "technology":
                    this.technology = value;
                    break;
            }
        }
    }

    public string to_string() {
        return """
            Device: %s
            State: %s
            Percentage: %d%%
            Energy: %.2f Wh
            Time to empty: %s
            Temperature: %.1f°C
        """.printf(
            this.device,
            this.state,
            this.percentage,
            this.energy,
            this.time_to_empty,
            this.temperature
        );
    }
}

public class UPower : Object {
    public static string get_info(string device) {
        string stdout;
        string stderr;
        int status;
        try {
            Process.spawn_command_line_sync(
                "upower -i /org/freedesktop/UPower/devices/" + device,
                out stdout,
                out stderr,
                out status
            );
        } catch (SpawnError e) {
            return "failed to invoke upower";
        }
        return stdout.strip();
    }
}