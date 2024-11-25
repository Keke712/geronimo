[GtkTemplate (ui = "/com/github/Keke712/geronimo/ui/Widgets/CryptoWallet.ui")]
public class CryptoWallet : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Box accounts;

    private HeaderPanel header;
    private Crypto crypto_client;
    private HashTable<string, double?> crypto_holdings;
    private Gtk.Label total_label;

    public CryptoWallet() {
        Object();
    }
    
    construct {
        set_css_name("crypto_wallet");
        crypto_client = new Crypto();
        
        // Initialize crypto holdings
        crypto_holdings = new HashTable<string, double?>(str_hash, str_equal);
        crypto_holdings.insert("VETUSDT", 12715.20);
        crypto_holdings.insert("GALAUSDT", 10461);
        crypto_holdings.insert("OPUSDT", 25.15482);
        crypto_holdings.insert("FETUSDT", 35.5644);
        
        // Setup header
        header = new HeaderPanel();
        header.title = "Cryptocurrencies";
        header.on_back_clicked.connect(() => {
            QuickSettings.get_instance().show_panel("quick");
        });
        header.on_refresh_clicked.connect(() => {
            update_all_crypto_prices.begin();
        });
        
        prepend(header);
        
        // Create crypto labels
        create_crypto_labels();
        update_all_crypto_prices.begin();
    }

    private void create_crypto_labels() {
        crypto_holdings.foreach((symbol, amount) => {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6) {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER
            };

            var label = new Gtk.Label("$0.00") {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER
            };

            box.set_data("crypto_symbol", symbol);
            box.set_data("crypto_amount", amount.to_string());
            box.append(label);
            accounts.append(box);

        });

        if (total_label == null) {
            total_label = new Gtk.Label("Total: $0.00") {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER,
                margin_top = 12
            };
            total_label.add_css_class("title-2");
            accounts.append(total_label);
        }
    }

    private async void update_all_crypto_prices() {
        double total_value = 0.0;
        var child = accounts.get_first_child();
        
        while (child != null) {
            if (child is Gtk.Box) {
                var box = (Gtk.Box) child;
                var symbol = box.get_data<string>("crypto_symbol");
                var amount_str = box.get_data<string>("crypto_amount");
                var label = (Gtk.Label) box.get_first_child();
                
                double amount = 0.0;
                if (amount_str != null) {
                    amount = double.parse(amount_str);
                }
                
                var crypto_value = yield update_crypto_price(label, symbol, amount);
                total_value += crypto_value;
            }
            child = child.get_next_sibling();
        }
        
        total_label.label = "Total: $%.2f".printf(total_value);
    }

    private async double update_crypto_price(Gtk.Label label, string symbol, double amount) {
        try {
            var price = yield crypto_client.get_crypto_price(symbol);
            if (price != null) {
                double total_value = price * amount;
                label.label = "%s: $%.2f".printf(symbol, total_value);
                return total_value;
            }
        } catch (Error e) {
            label.label = "%s: Error".printf(symbol);
            stderr.printf("Error updating price for %s: %s\n", symbol, e.message);
        }
        return 0.0;
    }
}