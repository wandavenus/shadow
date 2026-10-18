# TODO — Lorong Sunyi

## 1. Prototipe horor psikologis 2.5D Android

- [x] “Buat game untuk Android, dengan gaya horror-psychology 2.5D dengan karakter hewan chibi.” Prototipe Godot memakai kontrol sentuh dan layout lanskap; APK belum dihasilkan—workflow rilis tersedia di bagian 5.
- [x] “Sorot angle camera seperti suikoden 2”; komposisi oblique/isometrik dibuat orisinal tanpa menyalin aset, karakter, atau adegan Suikoden II.
- [x] “Gunakan Godot” dengan implementasi 2D berlapis/pseudo-3D yang sesuai untuk perangkat Android.
- [x] “Sertakan karakter hewan chibi, kontrol dan UI ramah sentuh Android, suasana horor psikologis tanpa gore eksplisit, serta sebuah area permainan/prototipe awal yang dapat dimainkan.”

## 2. Eksplorasi, seluruh prop, petunjuk, teka-teki, dan ancaman

- [x] “Rancang loop gameplay yang padu dengan suasana: eksplorasi ruang yang sunyi dan berubah secara psikologis, investigasi petunjuk, memeriksa/menggunakan seluruh prop, memecahkan teka-teki lingkungan, serta menghindari ancaman yang mengubah persepsi dan tata ruang.”
- [x] “Semua prop yang dapat dijangkau—termasuk bangku, lemari, laci, meja, lampu, pintu, dan benda lain—harus interaktif dengan respons visual/audio/teks yang bermakna.”
- [x] “Gunakan sistem interaksi data-driven agar setiap prop dapat memberi deskripsi, keadaan, petunjuk, item atau efek atmosfernya sendiri.”
- [x] Area prototipe dapat dijelajahi dengan jalur oblique/isometrik; ancaman mengubah persepsi dan tata ruang serta dapat dihindari dengan bersembunyi.
- [x] Selidiki petunjuk dan item, pahami perubahan lingkungan, pecahkan teka-teki, dan buka jalan keluar.

## 3. Kontrol, bahasa, dan batas suasana

- [x] “Kendalikan karakter hewan chibi melalui kontrol serta UI ramah sentuh Android.”
- [x] “Seluruh konten game menggunakan Bahasa Indonesia tanpa pemilih bahasa.”
- [x] “Pertahankan horor psikologis tanpa gore eksplisit.”

## 4. Proyek dan aset

- [x] Integrasikan aset yang dibutuhkan ke scene; pertahankan provenance dan fakta lisensi katalog.
- [x] Ganti identitas, splash/loading screen, artwork sharing, dan favicon bawaan agar konsisten dengan Lorong Sunyi.
- [x] Simpan source proyek ke repo GitHub `wandavenus/shadow` di subfolder `games/lorong-sunyi` tanpa menimpa README, lisensi, atau konten repo yang sudah ada.

## 5. Build APK rilis melalui GitHub Actions

- [x] Tambahkan preset `Android Release` dan workflow manual Godot 4.7.2 yang memakai `--export-release`, menandatangani APK, memverifikasi tanda tangan, dan mengunggah artifact Actions tanpa membuat GitHub Release atau mengunggah ke Play Store.
- [x] Minta persetujuan eksplisit atas lisensi Android SDK melalui checkbox workflow yang default-nya tidak dicentang.
- [x] Dukung signing key sementara per run atau tiga GitHub Actions secrets untuk key persisten.
- [ ] Jalankan build pertama setelah media runtime dipulihkan melalui secret `LORONG_ASSETS_ARCHIVE_URL` (atau disediakan di checkout) dan persetujuan SDK dicentang. Repo saat ini sengaja tidak menyimpan biner media.
