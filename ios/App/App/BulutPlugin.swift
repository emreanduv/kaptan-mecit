import Foundation
import Capacitor

/* iCloud eşitleme: kayıt oyuncunun kendi iCloud Drive'ındaki gizli uygulama klasörüne (Documents) yazılır/okunur. */
@objc(BulutPlugin)
public class BulutPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "BulutPlugin"
    public let jsName = "Bulut"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "durum", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "yaz", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "oku", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sil", returnType: CAPPluginReturnPromise)
    ]
    private let kuyruk = DispatchQueue(label: "cbm.bulut", qos: .utility)
    private var onbellek: URL?

    private func klasor() -> URL? {
        if let k = onbellek { return k }
        guard FileManager.default.ubiquityIdentityToken != nil,
              let kok = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let d = kok.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        onbellek = d
        return d
    }
    private func yerTutucu(_ url: URL) -> Bool {
        let p = url.deletingLastPathComponent().appendingPathComponent("." + url.lastPathComponent + ".icloud")
        return FileManager.default.fileExists(atPath: p.path)
    }

    @objc func durum(_ call: CAPPluginCall) {
        kuyruk.async { call.resolve(["var": self.klasor() != nil]) }
    }

    @objc func yaz(_ call: CAPPluginCall) {
        guard let ad = call.getString("ad"), let b64 = call.getString("veri"), let veri = Data(base64Encoded: b64) else { call.reject("eksik"); return }
        kuyruk.async {
            guard let d = self.klasor() else { call.reject("icloud-yok"); return }
            let url = d.appendingPathComponent(ad)
            var koord: NSError?
            var hata: Error?
            NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forReplacing, error: &koord) { u in
                do { try veri.write(to: u, options: .atomic) } catch { hata = error }
            }
            if let e = koord ?? (hata as NSError?) { call.reject(e.localizedDescription) } else { call.resolve() }
        }
    }

    @objc func oku(_ call: CAPPluginCall) {
        guard let ad = call.getString("ad") else { call.reject("eksik"); return }
        kuyruk.async {
            guard let d = self.klasor() else { call.resolve([:]); return }
            let url = d.appendingPathComponent(ad)
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
            var n = 0
            while n < 100 {                                    // en çok ~25 sn: iCloud'dan inmesini bekle
                if let v = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]), v.ubiquitousItemDownloadingStatus == .current { break }
                if n > 8 && !FileManager.default.fileExists(atPath: url.path) && !self.yerTutucu(url) { break }
                Thread.sleep(forTimeInterval: 0.25); n += 1
            }
            var koord: NSError?
            var veri: Data?
            NSFileCoordinator(filePresenter: nil).coordinate(readingItemAt: url, options: [], error: &koord) { u in veri = try? Data(contentsOf: u) }
            if let v = veri { call.resolve(["veri": v.base64EncodedString()]) } else { call.resolve([:]) }
        }
    }

    @objc func sil(_ call: CAPPluginCall) {
        guard let ad = call.getString("ad") else { call.reject("eksik"); return }
        kuyruk.async {
            guard let d = self.klasor() else { call.resolve(); return }
            let url = d.appendingPathComponent(ad)
            var koord: NSError?
            NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forDeleting, error: &koord) { u in try? FileManager.default.removeItem(at: u) }
            call.resolve()
        }
    }
}
