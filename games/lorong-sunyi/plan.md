# Rencana Proyek — Lorong Sunyi

## Ringkasan

Game psychological horror 2.5D untuk Android, dibangun sebagai proyek Godot 4.7.2. Permainan memakai implementasi 2D berlapis/pseudo-3D dengan perspektif oblique/isometrik yang mengingatkan pada komposisi RPG klasik seperti Suikoden II tanpa menyalin aset, karakter, atau adegan. Prototipe pertama berfokus pada satu ruangan yang bisa dijelajahi, karakter hewan chibi, investigasi, teka-teki properti, ancaman pengubah persepsi, dan semua prop yang terlihat sebagai objek interaktif.

## Keputusan implementasi

- **Engine dan penyajian:** Godot 4.7.2, proyek offline, simulasi dan interaksi lokal; konfigurasi ekspor Web yang disediakan starter tetap dipakai untuk Preview, sementara proyek disiapkan sebagai sumber game Android. Resolusi logis 1280×720 dengan canvas scaling dan UI adaptif.
- **Perspektif dan gerak:** ruangan disusun memakai layer visual 2D berurutan menurut koordinat Y, jalur gerak diagonal-oblique dan batas tabrakan yang konsisten. Gerak keyboard/gamepad serta tombol sentuh Android mengontrol karakter yang sama.
- **Loop inti:** mulai → jelajahi ruangan → dekati dan interaksikan prop → kumpulkan/membaca petunjuk dan item → hindari ancaman dengan bersembunyi atau mengubah jalur → gunakan petunjuk untuk membuka jalan keluar → layar hasil dan coba lagi.
- **Interaksi prop:** katalog data-driven mendefinisikan nama, deskripsi, keadaan, syarat, petunjuk, item, dan respons tiap objek. Semua benda yang ditampilkan sebagai prop permainan dapat diperiksa atau digunakan; prompt menandai objek terdekat dan satu aksi konteks menangani pemeriksaan/penggunaan.
- **Bahasa:** seluruh UI, dialog, petunjuk, kontrol, dan teks permainan dalam Bahasa Indonesia; tidak ada pemilih bahasa atau pelokalan otomatis.
- **Aset:** mode produksi hibrida yang tercatat menjadi acuan: cari dan adaptasi aset katalog untuk basis yang cocok, lalu gunakan visual AI yang sesuai izin hibrida untuk celah peran yang belum tercakup. Pertahankan sumber/lisensi aset katalog; jangan memakai materi Suikoden II. Tidak membuat mockup konsep karena pilihannya tidak disetujui.
- **Batas pengalaman:** horor psikologis tanpa gore eksplisit; ancaman terutama mengubah cahaya, persepsi, dan posisi/jalur. Tidak ada backend, login, papan peringkat, pembayaran, atau pemilih bahasa.

## Struktur utama

- `scenes/main.tscn` tetap menjadi entry scene dan memakai pengendali baru.
- `scripts/lorong/game_controller.gd` memiliki alur judul, mulai, jeda, hasil, kontrol sentuh, dan integrasi ruang.
- `scripts/lorong/room.gd` memiliki arena oblique, tata ruang, gerak/tumbukan, logika investigasi, teka-teki, ancaman, dan kondisi menang/gagal.
- `scripts/lorong/player.gd` mengelola gerak dan animasi sederhana karakter chibi.
- `scripts/lorong/interactive_prop.gd` menjadi komponen interaksi prop; `scripts/lorong/prop_catalog.gd` menjadi sumber data deskripsi/keadaan/petunjuk/item.
- `assets/characters/`, `assets/props/`, dan `assets/environment/` menyimpan visual runtime yang digunakan; `assets/share/` menampung ikon dan artwork berbagi yang terdaftar.
- `web/loading.html` dan shell terkait menggunakan identitas Lorong Sunyi, warna solid serta ikon game, indikator progres nyata/indeterminate dan Retry.
- `test/` dan `game-verification.json` mempertahankan pemeriksaan finite starter yang relevan dan menegaskan loop inti baru.

## Sistem visual dan desain

### Arah desain

**Gerak desain:** RPG oblique klasik bertemu horor psikologis lo-fi yang intim; rasa ruang datang dari lantai, dinding, tumpang tindih objek, dan perubahan kecil yang tidak nyaman, bukan dari gore.

**Prinsip inti:** (1) sudut dan siluet mudah dibaca saat layar kecil; (2) semua objek dekoratif yang tampil sebagai prop punya affordance dan respons; (3) ketegangan dibangun lewat cahaya, bunyi/teks singkat, serta perubahan persepsi; (4) kontrol sentuh dan aksesibilitas tidak menutupi jalur gerak.

**Filosofi warna:** biru tinta dan ungu arang memberi rasa malam dan ruang terkurung; kayu kusam dan abu lembap membuat kamar terasa lama dihuni; aksen amber kusam menandai benda berguna, sedangkan merah muda pucat/merah redup hanya muncul saat persepsi terganggu. Kontras tinggi dipakai untuk keterbacaan target sentuh, bukan gore.

**Paradigma tata letak:** satu kamar asimetris dilihat dari atas-miring; lorong diagonal di tengah membuka ruang gerak, sementara prop penting berada di pinggir agar pemain membaca ruang melalui langkah dan sudut pandang. HUD berada di tepi layar dan kontrol virtual berada di area bawah tanpa memotong objek interaktif.

**Elemen khas:** (1) bingkai/ambang pintu yang tampak berubah saat ancaman dekat; (2) halo tipis seperti debu pada prop aktif; (3) bayangan yang kadang tidak mengikuti benda sumber.

**Filosofi interaksi:** pemain mendekati benda, menerima nama dan petunjuk konteks, lalu memilih satu aksi yang jelas. Respons prop bersifat spesifik dan mempertahankan perubahan keadaan; dialog pendek membuat pemeriksaan terasa seperti membaca gejala, bukan sekadar membuka menu.

**Animasi:** gerak karakter lembut dan singkat; lampu berdenyut perlahan saat ketegangan naik; distorsi ruang bertransisi halus, tidak menyilaukan; ancaman bergerak dengan jeda yang mengganggu; sediakan opsi reduced motion dan hindari flash cepat.

**Tipografi:** gunakan keluarga display/body yang sudah dibundel starter Godot, dengan hirarki judul besar, teks petunjuk medium dan label tombol singkat. Semua teks permainan tetap teks UI live, bukan raster di dalam artwork.

**Esensi merek:** pengalaman horor eksplorasi pendek untuk pemain yang menyukai detail ruang dan misteri emosional; berbeda karena furnitur biasa menjadi alat penyelidikan. Kepribadian: sunyi, ganjil, hangat.

**Suara merek:** narasi pendek, puitis, dan tidak menjelaskan terlalu banyak; CTA jelas dan praktis. Contoh: “Sesuatu bergerak di balik kayu.” dan “Periksa dulu. Jangan buru-buru pergi.”

**Wordmark/logo:** tulisan “LORONG SUNYI” diperlakukan sebagai cap judul dengan jarak huruf lebar dan aksen garis pintu/retakan, bukan teks bawaan biasa untuk aset berbagi; di HUD gunakan label live.

**Warna merek:** nila-ungu redup dengan aksen amber kapur, yaitu identitas yang dapat dikenali di atas latar gelap tanpa menyamarkan affordance.

## Struktur gameplay prototipe

Satu ruang awal memuat bangku, lemari, laci, meja, lampu, jam, cermin, dan pintu keluar. Setiap prop mendapat identitas dan responsnya sendiri. Beberapa pemeriksaan membuka petunjuk/kunci, lampu mengungkap detail yang tadinya tidak terlihat, dan kombinasi petunjuk mengizinkan pintu dibuka. Interaksi meningkatkan ketegangan; ketika ancaman muncul, pemain dapat memutus garis pandang dengan bersembunyi di lemari atau mengubah rute. Menuntaskan teka-teki membawa ke layar hasil; gagal tertangkap atau memilih ulang dapat memulai kembali area.
