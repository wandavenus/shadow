# Lorong Sunyi

Lorong Sunyi adalah vertical slice slice-of-life damai di desa kompak. Pemain menyapa warga, membantu mengantar sayur dari kebun ke kedai, boleh menyelesaikan tugas bunga untuk Lio, lalu bebas menjelajahi desa tanpa deadline.

## Karakter dan visual
Mika adalah humanoid fox chibi. Warga lainnya: Pak Ranu (goat), Bu Sari (cat), Nara (rabbit), Pak Jati (bear), dan Lio (dog). Keenamnya memakai sprite full-body dengan ciri spesies yang jelas; tidak ada kepala melayang. Rig menambahkan ekor procedural, animasi idle/walk, serta name tag nama/peran.

Art direction-nya low-fi 2D oblique/2.5D dengan blue-hour yang tenang, kontras cukup untuk gameplay, dan cahaya jendela terbatas. Cerita, karakter, teks, dan aset harus orisinal; jangan menyalin elemen khas game lain.

## Waktu, cuaca, dan sapaan
Jam berjalan selama bermain dan berhenti saat pause. Daypart: `morning`, `day`, `evening`, `night`; cuaca: `clear`, `cloudy`, `rain`, `wind`. Rutinitas dan ambience menyesuaikan kondisi. Salam pembuka tetap netral (“Halo, Mika.”) pada semua waktu; catatan cuaca menyesuaikan keadaan. Tidak ada timer, hukuman, fear, chase, hide, damage, atau lose state.

## Menjalankan tes
Dari folder repo:

```bash
godot --headless --path games/lorong-sunyi res://test/test_suite.tscn
godot --headless --path games/lorong-sunyi --script res://test/atmosphere_audio_test.gd
godot --headless --path games/lorong-sunyi res://test/village_effects_test.tscn
```

Hasil terakhir: **571 pemeriksaan gameplay**, **110 pemeriksaan kontrak audio**, dan **29 pemeriksaan visual desa** lulus. Quest utama dan opsional tercakup pada seluruh 16 pasangan waktu/cuaca; satu playthrough quest utama juga lulus dengan input gerak dan interaksi target normal tanpa teleport. Pemeriksaan visual langsung dan uji perangkat Android masih terbuka.

## Android dan kontrol
Pertahankan keyboard/touch UI, prompt interaksi, serta binding `move_down`. Export preset memakai Gradle dengan `minSdk=30`, `targetSdk=35`, dan hanya ABI `arm64-v8a`. APK Debug lokal sudah lolos pemeriksaan manifest dan aset/runtime. Release workflow tidak dijalankan; APK Debug memakai signing debug otomatis Godot dan tidak diunggah/dipublikasikan.

Lihat [vertical slice plan](vertical-slice-plan.md), [plan](plan.md), [TODO](TODO.md), dan [asset notes](ASSETS.md).
