# Catatan aset — Lorong Sunyi

Sumber katalog berikut dipilih melalui metadata resmi katalog. Metadata mencatat lisensi **CC0-1.0**, penggunaan komersial serta distribusi proyek yang diedit diperbolehkan, dan atribusi/pemberitahuan hak cipta tidak diwajibkan. Catatan ini menyimpan asal dan penggunaan; bukan klaim bahwa aset eksklusif atau bebas dari semua risiko pihak ketiga.

| Peran | Koleksi / anggota | Sumber | ID katalog | SHA-256 arsip |
| --- | --- | --- | --- | --- |
| Karakter pemain Mika | Kenney Animal Pack — `PNG/Round (outline)/rabbit.png` | https://kenney.nl/assets/animal-pack | `kenney-animal-pack` | `0bc2c14992bc5156dcb0af06d61553c68a0fc3ec6ff6aa9781f9ed1b7120b8a9` |
| Sprite prop interaktif | Furniture Assets — `Untitled 17.png` (atlas furnitur) | https://zebravibe.itch.io/furniture | `itch-io:2200439` | `ac45ddc5d93199fa1233c4e2ba8ad42794480aa09f422f9f3f091427218cf71a` |
| Referensi suasana, tidak diekspor | Horror Interior Backgrounds Free CC0 — `Horror background/corridor.jpg` | https://the-outlander.itch.io/horror-backgrounds-scary-haunted-interior-free-cc0 | `itch-io:2244246` | `33df3adbbfee788031e4ad283a8997e409f5038f5901582dcc0bd5c4dbcb3036` |

Aset katalog diambil melalui akses resmi; receipt dan provenance retrieval dipertahankan. `scripts/lorong/prop_catalog.gd` memetakan atlas furnitur ke bangku, lemari, laci, meja, lampu, jam, potret, dan pintu. Sprite kelinci menjadi basis Mika; skala, gerakan, dan y-sort membuatnya terbaca sebagai avatar chibi pada ruang oblique. Gambar koridor katalog tidak ditempel di scene karena akan menampilkan benda statis yang tak bisa diperiksa.

## Artwork orisinal dan optimasi runtime

Artwork berikut dibuat untuk pilihan produksi hibrida pada Blueprint; tidak mengambil aset, karakter, atau adegan Suikoden II. Semua runtime derivative mempertahankan artwork sumber dan hanya dipangkas/diubah ukurannya untuk anggaran texture serta rasio tampil.

| Path | Peran | Catatan produksi |
| --- | --- | --- |
| `assets/environment/lorong_empty_room.png` | Master ruang kosong | Ilustrasi kamar oblique 2560×1440 tanpa furnitur yang tampak; master dipertahankan sebagai referensi. |
| `assets/environment/lorong-empty-room-1280x720.png` | Latar area permainan | Downscale Lanczos dari master ke 1280×720 agar pas dengan viewport lanskap. |
| `assets/characters/empty_presence.png` | Master ancaman | Siluet Kehadiran dengan alpha transparan; master dipertahankan. |
| `assets/characters/empty-presence-512.png` | Sprite runtime Kehadiran | Downscale Lanczos 512×512 dalam ruang alpha premultiplikasi untuk menghindari halo gelap. |
| `assets/share/lorong-sunyi-og.png` | Master artwork judul | Cover orisinal dengan tulisan persis “LORONG SUNYI”; master 2560×1440. |
| `assets/share/lorong-title-1280x720.png` | Layar judul dan splash | Downscale 1280×720 untuk layar permainan lanskap. |
| `assets/share/lorong-sunyi-og-1200x630.png` | OG sharing | Crop tengah tipis pada sumbu vertikal lalu downscale ke rasio 1200×630; tulisan tetap utuh. |
| `assets/share/favicon.png` | Ikon | Adaptasi sprite kelinci katalog pada bidang warna game, 128×128; diperiksa pada ukuran 32×32. |

Loader Web menyematkan favicon kecil secara inline supaya ikon tampil sebelum PCK siap. Master yang tidak digunakan langsung dikecualikan dari PCK tetapi dipertahankan dalam proyek sebagai sumber; aset sumber tidak dihapus.
