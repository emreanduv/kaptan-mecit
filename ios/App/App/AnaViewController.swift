import UIKit
import Capacitor

/* Uygulamanın kendi eklentileri (iCloud eşitleme) köprüye burada kaydedilir. */
class AnaViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(BulutPlugin())
    }
}
