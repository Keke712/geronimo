public errordomain CryptoError {
    HTTP_ERROR,
    PARSE_ERROR
}

public class Crypto : GLib.Object {
    // Exemple: https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT
    private string api_base_url = "https://api.binance.com/api/v3/ticker/price?symbol=";
    private Soup.Session session;

    public Crypto() {
        session = new Soup.Session();
    }

    public async double? get_crypto_price(string symbol) throws CryptoError {
        try {
            string url = api_base_url + symbol;
            var message = new Soup.Message("GET", url);
            
            var stream = yield session.send_async(message, null);
            
            if (message.status_code != 200) {
                throw new CryptoError.HTTP_ERROR("Erreur HTTP: %u".printf(message.status_code));
            }

            var parser = new Json.Parser();
            yield parser.load_from_stream_async(stream);
            var root = parser.get_root();
            var obj = root.get_object();
            
            string price_str = obj.get_string_member("price");
            return double.parse(price_str);
        } catch (GLib.Error e) {
            stderr.printf("Erreur lors de la récupération du prix: %s\n", e.message);
            throw new CryptoError.PARSE_ERROR(e.message);
        }
    }
}