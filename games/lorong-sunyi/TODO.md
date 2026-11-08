# TODO — Lorong Sunyi

## Selesai dan lolos pemeriksaan otomatis
- [x] Mengalihkan loop dari horor ke slice-of-life desa yang damai: bantu warga, feedback sosial, lalu free exploration.
- [x] Memakai latar runtime kampung low-fi 1280×720.
- [x] Menyiapkan enam karakter humanoid-chibi full-body: Mika fox, Pak Ranu goat, Bu Sari cat, Nara rabbit, Pak Jati bear, Lio dog.
- [x] Menambahkan ekor procedural dan animasi idle/walk; tidak ada kepala saja yang melayang.
- [x] Membuat warga dapat diajak bicara, dengan quest utama, tugas opsional, dan finish hangat.
- [x] Menjaga sapaan tetap netral; catatan cuaca, rutinitas warga, empat daypart/cuaca, pause, dan reduced-motion mengikuti state.
- [x] Memeriksa keyboard/touch, prompt, name tag, status quest, serta eksplorasi bebas.
- [x] Menuntaskan quest utama dan opsional pada seluruh 16 pasangan waktu/cuaca; satu rute quest utama lulus lewat input/target interaksi tanpa teleport.
- [x] Menjalankan suite gameplay: 571 checks lulus.
- [x] Menjalankan suite kontrak audio: 110 checks lulus.
- [x] Menjalankan suite visual desa: 29 checks lulus.
- [x] Menjalankan APK Debug Gradle lokal untuk memverifikasi manifest, ABI, serta aset/script utama di paket.

## Masih perlu dilakukan
- [ ] Uji visual langsung pada 1280×720 untuk keterbacaan tiap name tag, animasi, dan jalur pada semua cuaca.
- [ ] Uji kontrol touch, safe area, performa, dan skala UI di perangkat Android min SDK 30/arm64.
- [ ] Playtest untuk polish dialog, rutinitas warga, keterbacaan tujuan, dan transisi free exploration.
- [ ] Minta pemilik kerja visual/audio meninjau ambience akhir; file efek/audio paralel tidak diubah dalam pekerjaan core ini.

## Batas rilis
- [x] Export preset memakai Gradle, `minSdk=30`, `targetSdk=35`, dan hanya ABI `arm64-v8a`.
- [x] APK Debug lokal diverifikasi: `minSdk=30`, `targetSdk=35`, native library hanya `arm64-v8a`, dan aset/script utama ada di paket.
- APK Debug memakai signing debug otomatis Godot; file sementara dihapus setelah pemeriksaan. Tidak ada release keystore, Release build, upload, atau publikasi.
- Release workflow diperbarui tetapi tidak dijalankan.
