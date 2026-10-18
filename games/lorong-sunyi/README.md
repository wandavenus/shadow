# Lorong Sunyi

**Lorong Sunyi** adalah prototipe game horor psikologis 2.5D berbahasa Indonesia. Mika, seekor kelinci kecil, terjebak di kamar oblique yang berubah saat kegelisahannya meningkat. Periksa bangku, lemari, laci, meja, lampu, jam, potret, dan pintu; kumpulkan tiga angka, pahami urutannya, lalu hindari Kehadiran dengan bersembunyi.

## Menjalankan

- Proyek menggunakan Godot 4.7.2; scene masuk adalah `scenes/main.tscn`.
- Di desktop: gerak dengan WASD/panah, periksa benda dengan E, Spasi, atau Enter, dan jeda dengan Esc/P.
- Di layar sentuh: gunakan pad arah di kiri dan tombol **PERIKSA** di kanan.
- Pilih **CARA BERMAIN** pada layar judul untuk melihat instruksi.
- Repo publik ini berisi source code, konfigurasi, lisensi, serta seluruh aset game yang diperlukan untuk membuka proyek dan menjalankan workflow Android.

## Build APK Android rilis sekali klik

1. Buka **Actions → Build APK Rilis Android — Lorong Sunyi → Run workflow**.
2. Biarkan input persetujuan lisensi SDK Android tetap tercentang (default sudah true berdasarkan persetujuan pemilik repo sebelumnya), lalu klik **Run workflow**.
3. Setelah run berhasil, unduh `Lorong-Sunyi-APK-Rilis` dari bagian **Artifacts** pada run tersebut.

Workflow memasang JDK 17, Android SDK Platform 35, Build Tools 35.0.1, NDK r28b, CMake, Godot 4.7.2, dan template ekspor Android. Workflow memakai `--export-release`, menandatangani APK untuk sideload, memverifikasi tanda tangan, dan mengunggah APK sebagai artifact. Workflow tidak mengunggah ke Play Store dan tidak membuat GitHub Release. **Workflow belum dijalankan setelah aset dimasukkan, jadi belum ada APK yang dihasilkan.**

Tidak ada GitHub Actions secret yang wajib disiapkan. Secara default, workflow membuat signing key sementara untuk setiap run. APK dapat dipasang langsung, tetapi untuk memasang build berikutnya sebagai pembaruan tanpa uninstall, gunakan signing key tetap melalui tiga secret opsional: `ANDROID_RELEASE_KEYSTORE_BASE64`, `ANDROID_RELEASE_KEYSTORE_PASSWORD`, dan `ANDROID_RELEASE_KEY_ALIAS`. Jangan commit keystore atau password ke Git.

Repo ini dan source asset-nya bersifat publik. Perlakukan log workflow dan artifact APK sebagai keluaran publik; jangan masukkan data pribadi ke game atau artifact.

## Aset dan lisensi

Semua gambar, sprite, font, derivative runtime, serta file lisensi yang dibutuhkan disertakan di `assets/`. Provenance, sumber, peran, dan fakta lisensi dirangkum di [ASSETS.md](ASSETS.md). Receipt sementara dari proses retrieval katalog tidak disertakan. Game tidak menggunakan aset atau karakter Suikoden II.
