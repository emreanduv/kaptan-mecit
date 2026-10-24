# Champion Battle Manager — masaüstü (Steam) kabuğu

Mobil sürümle aynı oyun derlemesini (`www/index.html`) Electron içinde çalıştırır.

- `oyun/index.html` ← `../www/index.html` (CI kopyalar)
- F11 / Alt+Enter tam ekran, pencere boyutu hatırlanır, kayıtlar kullanıcı klasöründe kalır
- Steam: `steam_appid.txt` içine gerçek AppID yazılınca steamworks.js açılır (başarımlar, overlay). 0 iken devre dışı.
- Derleme: kaptan-mecit deposundaki `champion-steam.yml` (Windows, macOS, Linux)
