# Catatan Aset — Lorong Sunyi

## Arah visual dan provenance
Gaya target adalah low-fi 2D oblique/2.5D, kampung Indonesia yang tenang pada blue-hour, dengan kontras cukup untuk jalur, warga, prompt, dan quest. Cerita, dialog, karakter, UI, serta aset baru harus orisinal; jangan menyalin elemen khas game lain.

## Aset runtime dan share
| Aset | Path | Penggunaan |
| --- | --- | --- |
| Latar kampung sumber | `assets/environment/desa-kampung-lowfi.png` | Artwork orisinal 2560×1440. |
| Latar kampung runtime | `assets/environment/desa-kampung-runtime-1280x720.png` | Turunan 1280×720 untuk room dan title/splash. |
| Mika — fox | `assets/characters/desa-hewan/mika-fox.png`; `mika-fox-runtime-384x576.png` | Sprite full-body orisinal; runtime memakai derivative 384×576. |
| Pak Ranu — goat | `assets/characters/desa-hewan/pak-ranu-goat.png`; runtime `pak-ranu-goat-runtime-384x576.png` | Sprite full-body NPC. |
| Bu Sari — cat | `assets/characters/desa-hewan/bu-sari-cat.png`; runtime `bu-sari-cat-runtime-384x576.png` | Sprite full-body NPC. |
| Nara — rabbit | `assets/characters/desa-hewan/nara-rabbit.png`; runtime `nara-rabbit-runtime-384x576.png` | Sprite full-body NPC. |
| Pak Jati — bear | `assets/characters/desa-hewan/pak-jati-bear.png`; runtime `pak-jati-bear-runtime-384x576.png` | Sprite full-body NPC. |
| Lio — dog | `assets/characters/desa-hewan/lio-dog.png`; runtime `lio-dog-runtime-384x576.png` | Sprite full-body NPC. |
| Ekor dan animasi | `scripts/lorong/character_visual.gd` | Ekor procedural per spesies; badan dan ekor bergerak saat idle/jalan. |
| Objek tugas | `scripts/lorong/interactive_prop.gd` | Keranjang sayur dan bunga kecil digambar sebagai objek interaktif. |
| OG art sumber | `assets/share/lorong-sunyi-village-og.png` | Key art kampung dan Mika fox full-body, 2560×1440. |
| OG art share | `assets/share/lorong-sunyi-village-og-1280x720.png` | Derivative 1280×720 yang dirujuk oleh `game-sharing.json`; bukan aset gameplay. |
| Ikon sumber | `assets/share/favicon-fox-clean.png` | Ikon statis Mika fox full-body, 1920×1920. |
| Ikon runtime/share | `assets/share/favicon-fox-runtime-256.png` | Turunan 256×256 untuk `project.godot` dan `game-sharing.json`. |

Sumber sprite karakter berukuran 1536×2304; derivative runtime 384×576 menjaga alpha dan memakai nearest-neighbor. Sprite menampilkan badan penuh, telinga/muzzle, torso, lengan, kaki, serta alas kaki. Anggota tubuh tidak dipisah menjadi bone; ekor dibuat terpisah dan bergerak.

## Aset katalog lama yang dipertahankan
`assets/characters/catalog-kenney/PNG/Round (outline)/rabbit.png` tetap berada di repo dan tidak dihapus. Metadata proyek mencatat sumber Kenney Animal Pack dan lisensi CC0-1.0; aset katalog kelinci ini tidak dipakai sebagai Mika runtime. Mika adalah fox full-body.

Aset horror lama, art karakter/environment/powerup/UI template, furniture atlas, favicon lama, dan OG art lama tetap tercatat sebagai provenance historis. Aset-aset yang tidak dipakai diberi status unused dan dikecualikan dari export Android; aset kelinci Kenney asli tetap dipertahankan.

## Verifikasi dan target Android
Automated tests terakhir: 571 pemeriksaan gameplay, 110 pemeriksaan kontrak audio, dan 29 pemeriksaan visual desa lulus. Quest utama/opsional diuji pada 16 pasangan waktu/cuaca dan satu rute quest utama dilalui dengan input/target interaksi tanpa teleport. Pemeriksaan visual langsung dan uji perangkat Android masih terbuka. Export preset memakai Gradle, `minSdk=30`, `targetSdk=35`, dan hanya ABI `arm64-v8a` (`armeabi-v7a=false`).

Dokumentasi resmi [Godot 4.7 Android export options](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html) menyatakan `gradle_build/min_sdk` digunakan saat Gradle build. APK Debug lokal dari Godot 4.7.2 sudah diverifikasi `minSdk=30`, `targetSdk=35`, ABI native hanya `arm64-v8a`, serta memuat latar kampung, Mika fox, room, dan controller.

APK Debug diagnostik pernah dibuat di `/tmp` untuk pemeriksaan manifest dan isi, lalu dihapus. Godot memakai signing debug otomatis; tidak ada release keystore, build Release, upload, atau publikasi. Release workflow belum dijalankan.

## Provenance aset katalog
Lisensi dan receipt katalog lengkap tetap disimpan di `asset-provenance.json`.

| Aset | Sumber/provenance | Status saat ini |
| --- | --- | --- |
| `assets/characters/catalog-kenney/PNG/Round (outline)/rabbit.png` | Kenney Animal Pack, CC0-1.0 | Dipertahankan sebagai aset katalog lama, tidak dipakai sebagai Mika. |
| `assets/props/catalog-furniture/Untitled 17.png` | Furniture Assets oleh ZebraVibe, itch.io asset ID `2200439`, CC0-1.0 | Sumber lama; props desa digambar oleh script. |
| `assets/environment/catalog-horror/Horror background/corridor.jpg` | Horror Interior Backgrounds Free CC0, itch.io asset ID `2244246`, CC0-1.0 | Referensi katalog lama saja; tidak dipakai atau disalin ke runtime desa. |
