# Lorong Sunyi

**Lorong Sunyi** adalah prototipe game horor psikologis 2.5D berbahasa Indonesia. Mika, seekor kelinci kecil, terjebak di kamar oblique yang berubah saat kegelisahannya meningkat. Periksa bangku, lemari, laci, meja, lampu, jam, potret, dan pintu; kumpulkan tiga angka, pahami urutannya, lalu hindari Kehadiran dengan bersembunyi.

## Menjalankan

- Proyek menggunakan Godot 4.7.2; scene masuk adalah `scenes/main.tscn`.
- Di desktop: gerak dengan WASD/panah, periksa benda dengan E, Spasi, atau Enter, dan jeda dengan Esc/P.
- Di layar sentuh: gunakan pad arah di kiri dan tombol **PERIKSA** di kanan.
- Pilih **CARA BERMAIN** pada layar judul untuk melihat instruksi.
- Source mirror GitHub ini tidak membawa runtime Game Webdev; media biner juga disimpan terpisah. Lihat bagian **Aset dan prasyarat build** sebelum mencoba mengekspor dari clone.

## Build APK Android rilis lewat GitHub Actions

Repo menyediakan preset Godot **Android Release** di `export_presets.cfg` dan workflow manual di `.github/workflows/build-android-release.yml`. Workflow menjalankan `godot --export-release`, menghasilkan APK yang ditandatangani untuk sideload, memverifikasi tanda tangannya, lalu mengunggah APK sebagai artifact pada run Actions. Workflow tidak mengunggah ke Play Store dan tidak membuat GitHub Release. **Workflow belum dijalankan dan belum ada APK yang dihasilkan.**

Untuk memulai build, buka **Actions → Build APK Rilis Android — Lorong Sunyi → Run workflow**. Centang input persetujuan lisensi Android SDK sebelum menjalankan; workflow berhenti jika input itu tidak disetujui. Runner memasang JDK 17, Android SDK Platform 35, Build Tools 35.0.1, NDK r28b, CMake, Godot 4.7.2, dan template ekspor Android. APK menggunakan `versionCode` yang bertambah pada setiap run.

Repo ini bersifat publik; perlakukan log workflow dan APK artifact sebagai keluaran publik. Jangan masukkan data pribadi ke game atau artifact.

### Aset runtime yang diperlukan

File gambar dan font runtime sengaja tidak dimasukkan ke Git. Karena itu, clone ini belum dapat menghasilkan APK sampai media dipulihkan. Ada dua cara:

1. Set secret repo `LORONG_ASSETS_ARCHIVE_URL` ke URL HTTPS arsip ZIP yang berisi folder tingkat teratas `assets/` dengan struktur file proyek; atau
2. Sediakan media pada folder `games/lorong-sunyi/assets/` sebelum menjalankan workflow. `.gitignore` mengabaikan biner media; bila memilih commit media, tambahkan file yang diperlukan secara sadar dengan `git add -f`.

Workflow memeriksa sembilan file gambar/font yang wajib dan gagal dengan pesan yang menyebut file yang hilang. Secret URL hanya digunakan untuk mengunduh arsip saat build; media hasil unduhan tidak dikomit ke repo.

### Signing untuk instalasi langsung

Jika tiga secret berikut tidak disediakan, workflow membuat signing key sementara untuk satu run: `ANDROID_RELEASE_KEYSTORE_BASE64`, `ANDROID_RELEASE_KEYSTORE_PASSWORD`, dan `ANDROID_RELEASE_KEY_ALIAS`. APK tetap diekspor dalam mode rilis, bukan debug, tetapi build berikutnya memakai kunci berbeda; hapus instalasi lama sebelum memasang APK baru.

Untuk memperbarui aplikasi yang sudah terpasang tanpa uninstall, simpan keystore yang sama secara aman di GitHub Actions secrets dengan ketiga nama tersebut. `ANDROID_RELEASE_KEYSTORE_BASE64` harus berisi keystore dalam Base64; password dan alias harus cocok dengan keystore. Jangan commit keystore atau password ke Git.

## Aset

Sumber, peran, dan fakta lisensi aset dicatat di [ASSETS.md](ASSETS.md). Aset katalog yang tercatat dipakai mengikuti metadata lisensi terbitannya; game tidak menggunakan aset atau karakter Suikoden II.

Media runtime disimpan dalam penyimpanan aset terkelola Manus; `assets.lock.json`, provenance, dan sidecar impor dipertahankan di repo. Arsip aset diperlukan agar build CI mandiri dapat memulihkan biner tersebut. Buka proyek Webdev terkait untuk sinkronisasi media dari penyimpanan sumber.
