# Shadow

## Proyek
### Lorong Sunyi
Lorong Sunyi adalah proyek Godot berbahasa Indonesia yang diarahkan sebagai vertical slice slice-of-life damai di desa. Pemain menjelajah, membantu warga dengan tugas sederhana, mengamati rutinitas yang berubah menurut waktu/cuaca, lalu melanjutkan free exploration tanpa deadline.

Protagonisnya Mika, humanoid fox chibi full-body. Lima warga lain memiliki spesies goat, cat, rabbit, bear, dan dog. Semua karakter, cerita, dialog, nama, aset runtime baru, dan UI harus orisinal; jangan menyalin karakter, adegan, quest, teks, aset, atau elemen khas game lain.

Gameplay mencakup quest utama saling membantu, tugas opsional, sapaan yang mengikuti waktu/cuaca, dua rutinitas warga, ambience, pause, reduced-motion, serta kontrol keyboard/touch. Tidak ada fear, chase, hide, damage, timer, atau kondisi kalah.

Artwork kampung sumber ada di `games/lorong-sunyi/assets/environment/desa-kampung-lowfi.png`; runtime memakai derivative 1280×720 `desa-kampung-runtime-1280x720.png`. Sprite full-body enam karakter ada di `games/lorong-sunyi/assets/characters/desa-hewan/`, dengan derivative 384×576 untuk runtime dan ekor procedural terpisah. Aset katalog kelinci Kenney yang lama tetap dipertahankan, tetapi tidak digunakan untuk Mika.

Suite terakhir lulus 433 pemeriksaan gameplay dan 95 pemeriksaan kontrak audio. Export preset memakai Gradle, `minSdk=30`, `targetSdk=35`, dan hanya ABI `arm64-v8a`; APK Debug lokal membuktikan manifest dan aset utama. Release workflow tidak dijalankan. Godot menandatangani APK Debug secara otomatis dengan signing debug; APK sementara sudah dihapus, tidak diunggah atau dipublikasikan. Uji visual langsung dan perangkat Android masih terbuka.

Lihat [README game](games/lorong-sunyi/README.md), [rencana vertical slice](games/lorong-sunyi/vertical-slice-plan.md), [plan](games/lorong-sunyi/plan.md), [TODO](games/lorong-sunyi/TODO.md), dan [ASSETS.md](games/lorong-sunyi/ASSETS.md).
