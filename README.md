# EdukasiTrader — Blog Finance/Trading (Adsterra-ready)

Situs statis (HTML/CSS murni, tanpa build tool) berisi 5 artikel edukasi trading berbahasa Indonesia, siap di-deploy gratis dan dipasangi iklan Adsterra.

## Struktur

```
adsterra-blog/
  index.html              # Homepage (daftar artikel)
  about.html
  contact.html
  privacy.html            # Wajib ada sebelum apply Adsterra
  articles/                # 5 artikel
  assets/css/style.css
  ads.txt                  # Isi setelah akun Adsterra disetujui
  robots.txt
  sitemap.xml
```

## Cara Deploy Gratis (GitHub Pages)

1. Buat akun GitHub (gratis) di https://github.com jika belum punya.
2. Buat repository baru, misalnya `edukasitrader` (public).
3. Dari dalam folder `adsterra-blog`, jalankan:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: EdukasiTrader blog"
   git branch -M main
   git remote add origin https://github.com/USERNAME/edukasitrader.git
   git push -u origin main
   ```
4. Di GitHub: masuk ke repo → **Settings → Pages** → pada "Build and deployment", pilih source **Deploy from a branch**, branch **main**, folder **/(root)** → Save.
5. Setelah beberapa menit, situs akan online di:
   `https://USERNAME.github.io/edukasitrader/`

### (Opsional) Custom Domain Gratis
GitHub Pages mendukung custom domain jika Anda punya domain sendiri. Jika belum punya domain dan ingin gratis, alternatif seperti `.eu.org` atau `is-a.dev` bisa dipertimbangkan, atau sub-domain gratis dari Cloudflare Pages.

## Setelah Online: Apply ke Adsterra

1. Daftar sebagai publisher di https://adsterra.com.
2. Ajukan domain/URL GitHub Pages Anda untuk direview.
3. Setelah disetujui, Adsterra akan memberi:
   - **Script/tag iklan** → tempel di lokasi yang sudah ditandai komentar `<!-- ADSTERRA: ad slot -->` di `index.html` dan tiap file di `articles/*.html`.
   - **Entri ads.txt** → salin ke file `ads.txt` di root, menggantikan isi contoh yang ada.
4. Commit & push perubahan tersebut supaya situs live ter-update:
   ```bash
   git add .
   git commit -m "Add Adsterra ad code"
   git push
   ```

## Menambah Artikel Baru

1. Duplikat salah satu file di `articles/`, ganti isi `<title>`, `<h1>`, dan body artikel.
2. Tambahkan card baru di `index.html` pada `<section class="article-grid">`.
3. Tambahkan `<url>` baru di `sitemap.xml`.

## Catatan Penting

- Semua artikel wajib memuat disclaimer edukasi (sudah ada di template) — jangan dihapus, karena situs ini bukan penyedia saran investasi berlisensi.
- Ganti alamat email di `contact.html` dan domain placeholder (`ganti-dengan-domain-anda.example`) di `robots.txt` dan `sitemap.xml` setelah situs online.
- Approval Adsterra biasanya lebih mudah untuk situs dengan konten orisinal yang cukup (idealnya 15-20+ artikel) dan trafik yang sudah berjalan — pertimbangkan menambah artikel secara rutin sebelum/sesudah apply.
