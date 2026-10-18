# Lorong Sunyi

**Lorong Sunyi** adalah prototipe game horor psikologis 2.5D berbahasa Indonesia. Mika, seekor kelinci kecil, terjebak di kamar oblique yang berubah saat kegelisahannya meningkat. Periksa bangku, lemari, laci, meja, lampu, jam, potret, dan pintu; kumpulkan tiga angka, pahami urutannya, lalu hindari Kehadiran dengan bersembunyi.

## Menjalankan

- Proyek menggunakan Godot 4.7.2; scene masuk adalah `scenes/main.tscn`.
- Di desktop: gerak dengan WASD/panah, periksa benda dengan E, Spasi, atau Enter, dan jeda dengan Esc/P.
- Di layar sentuh: gunakan pad arah di kiri dan tombol **PERIKSA** di kanan.
- Pilih **CARA BERMAIN** pada layar judul untuk melihat instruksi.
- `npm run check` menjalankan pemeriksaan finite untuk bahasa, Tweak, kontrol, prop, ancaman, dan teka-teki.
- `npm run build` menghasilkan Web build lokal untuk pemeriksaan; pratinjau proyek memakai runtime Game Webdev.

## Android

Area game dan UI dirancang untuk layar lanskap 16:9 dan memakai renderer GL Compatibility, dengan kontrol sentuh di dalam game. APK belum dibangun di sandbox ini: Godot tersedia, tetapi Android SDK, Java SDK, dan template ekspor Android tidak terpasang. Proyek ini belum memiliki preset ekspor Android; pada lingkungan dengan toolchain tersebut, buat preset Android di Godot 4.7.2 untuk menghasilkan paket perangkat.

## Aset

Sumber, peran, dan fakta lisensi aset dicatat di [ASSETS.md](ASSETS.md). Aset katalog yang tercatat dipakai mengikuti metadata lisensi terbitannya; game tidak menggunakan aset atau karakter Suikoden II.

Media runtime disimpan dalam penyimpanan aset terkelola Manus dan sengaja tidak disertakan di Git; `assets.lock.json`, provenance, dan sidecar impor dipertahankan. Karena itu clone GitHub ini adalah mirror source, bukan paket mandiri yang langsung dapat dijalankan tanpa memulihkan media dari proyek Manus terkait. Buka proyek Webdev yang sama untuk menyinkronkan media dan menjalankan ekspor dari sana.
