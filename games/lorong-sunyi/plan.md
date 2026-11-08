# Rencana Proyek — Lorong Sunyi

## Ringkasan
Lorong Sunyi adalah vertical slice slice-of-life damai di satu desa kompak untuk Android. Loop-nya adalah eksplorasi, percakapan, tugas saling membantu, rutinitas warga yang berubah menurut jam/cuaca, lalu free exploration setelah finish hangat. Visual low-fi 2D oblique/2.5D memakai cahaya blue-hour yang tenang dan tetap terbaca.

## Roster
- Mika (fox), protagonis.
- Pak Ranu (goat), petani.
- Bu Sari (cat), pemilik kedai.
- Nara (rabbit), pekebun.
- Pak Jati (bear), perajin anyaman.
- Lio (dog), anak tetangga.

## Keputusan desain
- Desa satu area tetap, dengan halaman, kedai, jalan kampung, dan landmark yang mudah dikenali.
- Semua karakter harus full-body humanoid-chibi: telinga, muzzle, torso, lengan/tangan, kaki, dan telapak terlihat menyatu; tidak ada kepala saja yang melayang.
- Slice memakai sprite full-body, dengan ekor procedural terpisah. Visual rig memberi idle/walk yang terlihat, sementara dua NPC memiliki rutinitas gerak di world.
- Name tag menampilkan nama serta peran dengan kontras yang terbaca pada 1280×720.
- Quest utama menghubungkan Pak Ranu ke Bu Sari; tugas opsional menghubungkan Nara, bunga kecil, dan Lio. Finish membuka eksplorasi bebas tanpa deadline.
- Sapaan pembuka mengikuti daypart dan cuaca. Hindari satu kalimat “selamat pagi” yang muncul di semua kondisi.
- Daypart hanya `morning`, `day`, `evening`, `night`; weather hanya `clear`, `cloudy`, `rain`, `wind`. Perubahan memengaruhi rutinitas dan ambience, bukan tekanan atau hukuman.
- Tidak ada timer, deadline, fear, chase, hide, damage, atau lose state.
- Bahasa UI, dialog, petunjuk, quest, dan feedback adalah Bahasa Indonesia.

## Integrasi dan target
Dudul menyediakan `set_time_of_day(hour24)` dan `set_weather(kind,intensity,wind=0)` untuk visual; Meki menerima `set_village_conditions(daypart, weather)` dan event ambience opt-in. State berhenti saat pause. Kontrol keyboard/touch dan binding `move_down` dipertahankan. Export preset memakai Gradle, `minSdk=30`, `targetSdk=35`, dan hanya ABI `arm64-v8a`; hasil APK Debug lokal sudah diverifikasi.

## Verifikasi
Suite saat ini lulus 571 pemeriksaan gameplay, 110 pemeriksaan kontrak audio, dan 29 pemeriksaan visual desa. Quest utama dan opsional diuji pada seluruh 16 pasangan waktu/cuaca; satu rute quest utama diuji melalui input/target interaksi tanpa teleport. Uji visual langsung pada resolusi target dan perangkat Android masih perlu dilakukan. APK Debug lokal terverifikasi `minSdk=30`, `targetSdk=35`, native ABI hanya `arm64-v8a`, serta aset/script runtime utama. Release workflow tidak dijalankan dan APK tidak diunggah/dipublikasikan.
