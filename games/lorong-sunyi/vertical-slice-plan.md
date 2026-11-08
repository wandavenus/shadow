# Rencana Vertical Slice — Lorong Sunyi

## Arah pengalaman
Bangun satu vertical slice slice-of-life yang damai di desa kompak dan terbatas. Pemain menjelajah, menyapa warga, membantu lewat tugas sederhana, mengamati rutinitas yang berubah bersama waktu/cuaca, lalu bebas menjelajahi desa setelah tugas utama selesai. Nuansa low-fi 2D oblique/2.5D dan blue-hour yang redup harus terasa tenang serta hangat—bukan ancaman atau horor.

Seluruh cerita, nama, dialog, karakter, aset, UI, dan adegan harus orisinal. Inspirasi genre hanya untuk mood umum; jangan menyalin elemen khas game lain.

## Loop slice
1. Mulai dengan arahan singkat; salam pertama tetap netral pada semua waktu, sementara catatan cuaca menyesuaikan keadaan.
2. Sapa Pak Ranu dan, bila pemain berkenan, bantu mengantar keranjang sayur ke kedai Bu Sari.
3. Beri feedback sosial yang hangat; setelah tugas utama selesai, buka free exploration tanpa timer atau urutan wajib.
4. Tugas opsional menghubungkan Nara, bunga kecil, dan Lio, dengan feedback tersendiri.
5. Waktu, cuaca, aktivitas warga, dan ambience berubah selama eksplorasi; jeda menghentikan simulasi.

## Roster dan arah karakter
- Mika — fox, karakter pemain.
- Pak Ranu — goat, petani.
- Bu Sari — cat, pemilik kedai.
- Nara — rabbit, tetangga pekebun.
- Pak Jati — bear, perajin anyaman.
- Lio — dog, anak tetangga.

Setiap karakter harus terbaca sebagai humanoid-chibi full-body: kepala, telinga, muzzle, torso, lengan/tangan, kaki, dan telapak/sepatu terlihat menyatu dan menapak. Jangan memakai kepala melayang atau membiarkan badan/kaki hilang. Untuk slice ini, sumber karakter berupa sprite full-body utuh; ekor dibuat terpisah sebagai komponen procedural dan dianimasikan. Idle memberi gerak napas halus; berjalan menggerakkan badan dan ekor, sementara rutinitas NPC benar-benar berpindah di world. Pemisahan setiap anggota tubuh menjadi bone/sprite tersendiri bukan syarat slice.

Name tag nama dan peran harus berkontras, terbaca pada resolusi 1280×720, dan tidak menutupi wajah atau tujuan interaksi.

## Waktu, cuaca, dan sapaan
- Daypart persis `morning`, `day`, `evening`, `night`; weather persis `clear`, `cloudy`, `rain`, `wind`.
- Jam berjalan selama bermain dan berhenti saat pause. Waktu/cuaca mengubah setidaknya satu rutinitas/aktivitas warga dan ambience/visual.
- Sapaan pertama saat berbicara dengan warga harus netral pada semua daypart; catatan cuaca dapat berubah sesuai keadaan. Uji semua 16 kombinasi waktu/cuaca.
- Quest utama dan tugas opsional harus bisa selesai pada seluruh kombinasi itu tanpa menunggu atau dibatasi waktu.
- Tidak ada deadline, hukuman, fear, chase, hide, damage, atau lose state.
- Kontrak visual Dudul: `set_time_of_day(hour24)` dan `set_weather(kind,intensity,wind=0)`. Kontrak Meki: `set_village_conditions(daypart, weather)` pada kondisi awal serta tiap perubahan, dengan ambience opt-in.
- Reduced-motion harus meredam animasi tanpa menghalangi gerak atau interaksi.

## Kontrol dan target
Pertahankan kontrol keyboard dan touch UI, prompt interaksi, serta binding `move_down`. Export preset memakai Gradle, `minSdk=30`, `targetSdk=35`, dan hanya ABI `arm64-v8a`. Dokumentasi Godot 4.7 menempatkan `gradle_build/min_sdk` pada jalur Gradle; APK Debug lokal sudah membuktikan nilai manifest dan ABI tersebut. Jangan menjalankan Release/signing release/deploy sebagai bagian dari verifikasi slice.

## Acceptance dan regresi
- Enam karakter menampilkan full body dan ciri spesies; tidak ada karakter berupa kepala melayang.
- Ekor hadir pada semua rig; idle/walk menampilkan gerak badan dan ekor. NPC rutin bergerak, bukan hanya berubah warna.
- Keenam name tag terbaca dan dialog tiap warga berbeda.
- Salam tetap netral di semua daypart dan catatan cuaca cocok dengan tiap kombinasi dari 4 daypart × 4 cuaca.
- Tugas utama dan opsional diuji pada seluruh 16 pasangan waktu/cuaca; satu penyelesaian tugas utama diuji end-to-end melalui input gerak, fokus target, dan interaksi normal tanpa teleport. Perubahan aktivitas, pause/resume, reduced-motion, serta free exploration juga diuji.
- Automated verification: 571 pemeriksaan gameplay, 110 pemeriksaan kontrak audio, dan 29 pemeriksaan visual desa lulus. Pemeriksaan visual langsung serta uji perangkat Android masih terbuka.
- APK Debug lokal lolos pemeriksa manifest dan isi: `minSdk=30`, `targetSdk=35`, native library hanya `arm64-v8a`, dan aset/script runtime utama tersedia. Release workflow tidak dijalankan.
